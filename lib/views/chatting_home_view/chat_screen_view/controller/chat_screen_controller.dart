import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../models/chat_user.dart';
import '../../models/message.dart';
import '../../utils/apis.dart';
import '../../utils/live_location_service.dart';
import '../../utils/map_picker_screen.dart';

class ChatScreenController extends GetxController {
  final messages = <Message>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final showEmoji = false.obs;
  final isUploading = false.obs;
  final hasNewMessage = false.obs;
  final textController = TextEditingController();
  late ChatUser user;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;
  bool _hasMore = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messageSubscription;
  late String convoID;
  Timer? _typingTimer;
  bool _isTyping = false;
  final otherUserIsTyping = false.obs;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _typingSubscription;
  final ScrollController scrollController = ScrollController();
  final record = AudioRecorder();
  final isRecording = false.obs;
  final isTextEmpty = true.obs;
  String? recordingPath;

  // Audio recording preview variables
  final hasRecordedAudio = false.obs;
  final audioPlayer = AudioPlayer();
  final isPlaying = false.obs;
  final audioDuration = Duration.zero.obs;
  final audioPosition = Duration.zero.obs;

  final recordingDuration = Duration.zero.obs;
  Timer? _recordingTimer;

  @override
  void onInit() {
    super.onInit();
    user = Get.arguments as ChatUser;
    convoID = APIs.getConversationID(user.id);
    fetchMessages();
    textController.addListener(_onTyping);
    _listenToTypingStatus();
    scrollController.addListener(_onScroll);
    isTextEmpty.value = textController.text.isEmpty;

    // Audio player listeners
    audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        isPlaying.value = false;
        audioPosition.value = Duration.zero;
      }
    });
    audioPlayer.onDurationChanged.listen((duration) {
      audioDuration.value = duration;
    });
    audioPlayer.onPositionChanged.listen((position) {
      audioPosition.value = position;
    });
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    APIs.setTypingStatus(convoID, APIs.user.uid, false);
    _typingSubscription?.cancel();
    _messageSubscription?.cancel();
    scrollController.dispose();
    if (isRecording.value) record.stop();
    _recordingTimer?.cancel(); // Cancel the recording timer
    audioPlayer.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50 &&
        !isLoadingMore.value &&
        !isLoading.value) {
      fetchMoreMessages();
    }
    if (!_isAtBottom() && messages.isNotEmpty) {
      hasNewMessage.value = true;
    } else {
      hasNewMessage.value = false;
    }
  }

  bool _isAtBottom() {
    if (!scrollController.hasClients) return true;
    return scrollController.position.pixels <= 50;
  }

  void scrollToBottom() {
    if (scrollController.hasClients && !_isAtBottom()) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      hasNewMessage.value = false;
    }
  }

  void _onTyping() {
    isTextEmpty.value = textController.text.isEmpty;
    if (textController.text.isNotEmpty) {
      if (!_isTyping) {
        APIs.setTypingStatus(convoID, APIs.user.uid, true);
        _isTyping = true;
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        APIs.setTypingStatus(convoID, APIs.user.uid, false);
        _isTyping = false;
      });
    } else {
      _typingTimer?.cancel();
      if (_isTyping) {
        APIs.setTypingStatus(convoID, APIs.user.uid, false);
        _isTyping = false;
      }
    }
  }

  void _listenToTypingStatus() {
    _typingSubscription = APIs.getTypingStatus(convoID).listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        otherUserIsTyping.value = data?['typing_${user.id}'] ?? false;
      } else {
        otherUserIsTyping.value = false;
      }
    });
  }

  Future<void> sendMessage() async {
    late Message tempMessage;
    if (textController.text.isNotEmpty) {
      final messageText = textController.text;
      textController.clear();
      try {
        tempMessage = Message(
          msg: messageText,
          toId: user.id,
          read: '',
          type: Type.text,
          fromId: APIs.user.uid,
          sent: Timestamp.fromDate(DateTime.now()),
        );
        messages.insert(0, tempMessage);

        if (messages.length == 1) {
          await APIs.sendFirstMessage(user, messageText, Type.text);
        } else {
          await APIs.sendMessage(user, messageText, Type.text);
        }
        _typingTimer?.cancel();
        APIs.setTypingStatus(convoID, APIs.user.uid, false);
        _isTyping = false;
      } catch (e) {
        log('Error sending message: $e');
        textController.text = messageText;
        messages.removeWhere((m) => m.sent == tempMessage.sent);
      }
    }
  }

  Future<void> startRecording() async {
    // Discard previous recording if any
    if (hasRecordedAudio.value) {
      await discardRecordedAudio();
    }
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      final dir = await getTemporaryDirectory();
      recordingPath = '${dir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
      try {
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );
        await record.start(
          config,
          path: recordingPath!,
        );
        isRecording.value = true;
        // Start the recording timer
        recordingDuration.value = Duration.zero;
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          recordingDuration.value += const Duration(seconds: 1);
        });
      } catch (e) {
        log('Error starting recording: $e');
        Get.snackbar('Error', 'Failed to start recording');
      }
    } else if (status.isPermanentlyDenied) {
      Get.snackbar(
        'Permission Denied',
        'Microphone permission is permanently denied. Please enable it in settings.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        mainButton: TextButton(
          onPressed: () => openAppSettings(),
          child: const Text('Open Settings'),
        ),
      );
    } else {
      final newStatus = await Permission.microphone.request();
      if (newStatus.isGranted) {
        await startRecording(); // Retry after permission is granted
      } else {
        Get.snackbar('Permission Denied', 'Microphone permission is required');
      }
    }
  }

  Future<void> stopRecording() async {
    try {
      await record.stop();
      isRecording.value = false;
      _recordingTimer?.cancel(); // Stop the timer
      if (recordingPath != null) {
        final file = File(recordingPath!);
        if (await file.exists()) {
          await sendRecordedAudio();
        }
      }
    } catch (e) {
      log('Error stopping recording: $e');
      Get.snackbar('Error', 'Failed to stop recording');
    }
  }

  Future<void> playRecordedAudio() async {
    if (recordingPath != null) {
      try {
        await audioPlayer.play(DeviceFileSource(recordingPath!));
        isPlaying.value = true;
      } catch (e) {
        log('Error playing recorded audio: $e');
        Get.snackbar('Error', 'Failed to play audio');
      }
    }
  }

  Future<void> stopRecordedAudio() async {
    try {
      await audioPlayer.stop();
      isPlaying.value = false;
    } catch (e) {
      log('Error stopping recorded audio: $e');
      Get.snackbar('Error', 'Failed to stop audio');
    }
  }

  Future<void> sendRecordedAudio() async {
    if (recordingPath != null) {
      final file = File(recordingPath!);
      if (await file.exists()) {
        try {
          if (isPlaying.value) {
            await stopRecordedAudio();
          }
          final url = await APIs.uploadAudio(file);
          final fileName = file.path.split('/').last;
          final msgContent = '$url|$fileName';
          await APIs.sendMessage(user, msgContent, Type.audio);
          await file.delete(); // Clean up temporary file
          recordingPath = null;
          hasRecordedAudio.value = false;
        } catch (e) {
          log('Error sending recorded audio: $e');
          Get.snackbar('Error', 'Failed to send voice message');
        }
      }
    }
  }

  Future<void> discardRecordedAudio() async {
    if (recordingPath != null) {
      final file = File(recordingPath!);
      if (await file.exists()) {
        try {
          if (isPlaying.value) {
            await stopRecordedAudio();
          }
          await file.delete();
          recordingPath = null;
          hasRecordedAudio.value = false;
        } catch (e) {
          log('Error discarding recorded audio: $e');
          Get.snackbar('Error', 'Failed to discard audio');
        }
      }
    }
  }

  Future<void> cancelRecording() async {
    if (isRecording.value) {
      try {
        await record.stop();
        isRecording.value = false;
        _recordingTimer?.cancel();
        recordingDuration.value = Duration.zero;

        if (recordingPath != null) {
          final file = File(recordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
          recordingPath = null;
        }
      } catch (e) {
        log('Error cancelling recording: $e');
      }
    }
  }

  Future<void> fetchMessages() async {
    isLoading.value = true;
    _messageSubscription?.cancel();
    _messageSubscription = APIs.getAllMessages(user, limit: _pageSize).listen((snapshot) {
      final newMessages = snapshot.docs.map((e) => Message.fromJson(e.data())).toList();
      messages.assignAll(newMessages);
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _pageSize;
      isLoading.value = false;

      final addedDocs = snapshot.docChanges.where((change) => change.type == DocumentChangeType.added);
      if (addedDocs.isNotEmpty) {
        if (_isAtBottom()) {
          scrollToBottom();
        } else {
          hasNewMessage.value = true;
        }
      }

      APIs.markMessagesAsRead(user);
    }, onError: (e) {
      log('Error fetching messages: $e');
      Get.snackbar('Error', 'Failed to load messages');
      isLoading.value = false;
    });
  }

  Future<void> fetchMoreMessages() async {
    if (!_hasMore || _lastDocument == null || isLoadingMore.value) return;

    isLoadingMore.value = true;
    try {
      APIs.getAllMessages(user, limit: _pageSize, startAfter: _lastDocument).listen((snapshot) {
        final newMessages = snapshot.docs.map((e) => Message.fromJson(e.data())).toList();
        if (newMessages.isNotEmpty) {
          messages.addAll(newMessages);
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length == _pageSize;
        } else {
          _hasMore = false;
        }
        isLoadingMore.value = false;
        APIs.markMessagesAsRead(user);
      }, onError: (e) {
        log('Error fetching more messages: $e');
        Get.snackbar('Error', 'Failed to load more messages');
        isLoadingMore.value = false;
      });
    } catch (e) {
      log('Error fetching more messages: $e');
      Get.snackbar('Error', 'Failed to load more messages');
      isLoadingMore.value = false;
    }
  }

  Future<void> sendChatImage(List<File> files) async {
    isUploading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      log('Current user: ${user?.uid ?? "Not authenticated"}');
      if (user == null) {
        Get.snackbar('Error', 'You must be logged in to upload images');
        return;
      }

      log('Starting image upload for user: ${this.user.id}');
      final tempMessage = Message(
        msg: 'uploading',
        toId: user.uid,
        read: '',
        type: Type.image,
        fromId: APIs.user.uid,
        sent: Timestamp.fromDate(DateTime.now()),
      );
      messages.insert(0, tempMessage);

      await APIs.sendChatImage(this.user, files);

      messages.remove(tempMessage);
    } catch (e) {
      log('Error uploading images: $e');
      Get.snackbar('Error', 'Failed to upload images: $e');
      messages.removeWhere((m) => m.msg == 'uploading');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> sendChatVideo(File file) async {
    isUploading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      log('Current user: ${user?.uid ?? "Not authenticated"}');
      if (user == null) {
        Get.snackbar('Error', 'You must be logged in to upload videos');
        return;
      }

      log('Starting video upload for user: ${this.user.id}');
      final tempMessage = Message(
        msg: 'uploading',
        toId: user.uid,
        read: '',
        type: Type.video,
        fromId: APIs.user.uid,
        sent: Timestamp.fromDate(DateTime.now()),
      );
      messages.insert(0, tempMessage);

      await APIs.sendChatVideo(this.user, file);

      messages.remove(tempMessage);
    } catch (e) {
      log('Error uploading video: $e');
      Get.snackbar('Error', 'Failed to upload video: $e');
      messages.removeWhere((m) => m.msg == 'uploading');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> sendChatDocument(List<File> files) async {
    isUploading.value = true;
    try {
      for (var file in files) {
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        final url = await APIs.uploadDocument(file);
        Get.back();
        final fileName = file.path.split('/').last;
        final msgContent = '$url|$fileName';
        await APIs.sendMessage(user, msgContent, Type.document);
      }
    } catch (e) {
      log('Error uploading documents: $e');
      Get.snackbar('Error', 'Failed to upload documents');
      Get.back();
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> pickImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(imageQuality: 70);
      if (images.isNotEmpty) {
        final files = images.map((i) => File(i.path)).toList();
        await sendChatImage(files);
      }
    } catch (e) {
      log('Error picking images: $e');
      Get.snackbar('Error', 'Failed to pick images');
    }
  }

  Future<void> pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null) {
        final files = result.files.map((file) => File(file.path!)).toList();
        for (var file in files) {
          final fileSize = await file.length();
          if (fileSize > 5 * 1024 * 1024) {
            Get.snackbar('Error', 'File size exceeds 5MB limit');
            return;
          }
        }
        await sendChatDocument(files);
      }
    } catch (e) {
      log('Error picking documents: $e');
      Get.snackbar('Error', 'Failed to pick documents');
    }
  }

  Future<void> pickCameraImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (image != null) {
        await sendChatImage([File(image.path)]);
      }
    } catch (e) {
      log('Error picking camera image: $e');
      Get.snackbar('Error', 'Failed to capture image');
    }
  }

  Future<void> pickVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        await sendChatVideo(File(video.path));
      }
    } catch (e) {
      log('Error picking video: $e');
      Get.snackbar('Error', 'Failed to pick video');
    }
  }

  Future<void> pickCameraVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        await sendChatVideo(File(video.path));
      }
    } catch (e) {
      log('Error recording video: $e');
      Get.snackbar('Error', 'Failed to record video');
    }
  }

  Future<void> editMessage(Message message, String newText) async {
    await APIs.editMessage(user, message, newText);
  }

  Future<void> pickContact() async {
    try {
      final status = await Permission.contacts.status;
      if (status.isGranted) {
        await _selectAndSendContact();
      } else if (status.isPermanentlyDenied) {
        Get.snackbar(
          'Permission Required',
          'Contact access is permanently denied. Please enable it in settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        );
      } else {
        final granted = await FlutterContacts.requestPermission();
        if (granted) {
          await _selectAndSendContact();
        } else {
          Get.snackbar('Error', 'Contact permission denied');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to access contacts');
    }
  }

  Future<void> _selectAndSendContact() async {
    final contact = await FlutterContacts.openExternalPick();
    if (contact != null) {
      final name = contact.displayName;
      final phone = contact.phones.isNotEmpty ? contact.phones[0].number : '';
      log('Selected contact: $name, $phone');
      if (phone.isNotEmpty) {
        final msg = 'contact:$name|$phone';
        final tempMessage = Message(
          msg: msg,
          toId: user.id,
          read: '',
          type: Type.text,
          fromId: APIs.user.uid,
          sent: Timestamp.fromDate(DateTime.now()),
        );
        messages.insert(0, tempMessage);
        try {
          await APIs.sendMessage(user, msg, Type.text);
        } catch (e) {
          log('Error sending contact: $e');
          messages.removeWhere((m) => m.sent == tempMessage.sent);
          Get.snackbar('Error', 'Failed to send contact');
        }
      } else {
        Get.snackbar('Error', 'Selected contact has no phone number');
      }
    } else {
      log('No contact selected');
    }
  }

  Future<void> pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.audio,
      );
      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          Get.snackbar('Error', 'Audio file size exceeds 10MB limit');
          return;
        }
        await sendChatAudio(file);
      }
    } catch (e) {
      log('Error picking audio: $e');
      Get.snackbar('Error', 'Failed to pick audio');
    }
  }

  Future<void> sendChatAudio(File file) async {
    isUploading.value = true;
    try {
      final url = await APIs.uploadAudio(file);
      final fileName = file.path.split('/').last;
      final msgContent = '$url|$fileName';
      await APIs.sendMessage(user, msgContent, Type.audio);
    } catch (e) {
      log('Error uploading audio: $e');
      Get.snackbar('Error', 'Failed to upload audio');
    } finally {
      isUploading.value = false;
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied.';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> shareLocation() async {
    try {
      final result = await Get.to(() => MapPickerScreen());
      log('Location result: $result');
      if (result != null) {
        final latLng = result['location'] as LatLng;
        final locationMsg = '${latLng.latitude},${latLng.longitude}';
        if (result['type'] == 'static') {
          await APIs.sendMessage(user, locationMsg, Type.location, locationType: LocationType.static);
        } else if (result['type'] == 'live') {
          final duration = result['duration'] as int?;
          await APIs.sendMessage(user, locationMsg, Type.location,
              locationType: LocationType.live, duration: duration ?? -1);
          LiveLocationService().startSharing(convoID, APIs.user.uid, duration ?? -1);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to share location: $e');
    }
  }

  void toggleEmoji() {
    showEmoji.value = !showEmoji.value;
  }
}