import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../models/chat_user.dart';
import '../../models/message.dart';
import '../../utils/apis.dart';

class GroupChatController extends GetxController {
  final messages = <Message>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final membersLoading = true.obs;
  final showEmoji = false.obs;
  final isUploading = false.obs;
  final hasNewMessage = false.obs;
  final textController = TextEditingController();
  final isTextEmpty = true.obs;
  late String groupId;
  final groupName = ''.obs;
  final groupImage = ''.obs;
  final members = <String, ChatUser>{}.obs;
  final adminId = ''.obs;
  final typingUsers = <String>[].obs;
  final lastRead = <String, String>{}.obs;
  final ScrollController scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  StreamSubscription<DocumentSnapshot>? _groupSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messageSubscription;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _firstLoad = true;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  final record = AudioRecorder();
  final isRecording = false.obs;
  String? recordingPath;
  final hasRecordedAudio = false.obs;
  final audioPlayer = AudioPlayer();
  final isPlaying = false.obs;
  final audioDuration = Duration.zero.obs;
  final audioPosition = Duration.zero.obs;
  final recordingDuration = Duration.zero.obs;
  Timer? _recordingTimer;

  @override
  Future<void> onInit() async {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    groupId = args['groupId'];
    groupName.value = args['groupName'];

    _groupSubscription = firestore
        .collection('companies/${await APIs.getCompanyPath()}/groups')
        .doc(groupId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        groupName.value = doc['name'] ?? '';
        groupImage.value = doc['image'] ?? '';
        adminId.value = doc['adminId'] ?? '';
        final typingUsersMap =
            doc['typingUsers'] as Map<String, dynamic>? ?? {};
        final typingUserIds = typingUsersMap.entries
            .where((e) => e.value == true)
            .map((e) => e.key)
            .toList();
        typingUsers.value = typingUserIds;
        final lastReadMap = doc['lastRead'] as Map<String, dynamic>? ?? {};
        lastRead.value =
            lastReadMap.map((key, value) => MapEntry(key, value.toString()));
      }
    }, onError: (e) {
      log('Error listening to group $groupId: $e');
    });

    await fetchMembers();
    fetchMessages();
    textController.addListener(_onTyping);
    scrollController.addListener(_onScroll);
    isTextEmpty.value = textController.text.isEmpty;

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
    APIs.setGroupTypingStatus(groupId, APIs.user.uid, false);
    _groupSubscription?.cancel();
    _messageSubscription?.cancel();
    scrollController.dispose();
    if (isRecording.value) record.stop();
    _recordingTimer?.cancel();
    audioPlayer.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 50 &&
        !isLoadingMore.value &&
        !isLoading.value &&
        _hasMore) {
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
        APIs.setGroupTypingStatus(groupId, APIs.user.uid, true);
        _isTyping = true;
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        APIs.setGroupTypingStatus(groupId, APIs.user.uid, false);
        _isTyping = false;
      });
    } else {
      _typingTimer?.cancel();
      if (_isTyping) {
        APIs.setGroupTypingStatus(groupId, APIs.user.uid, false);
        _isTyping = false;
      }
    }
  }

  String get typingText {
    final typingUserIds =
        typingUsers.where((id) => id != APIs.user.uid).toList();
    final typingCount = typingUserIds.length;
    if (typingCount == 0) return '';
    if (typingCount == 1) {
      final userId = typingUserIds[0];
      final user = members[userId];
      return user != null
          ? '${user.name} is typing...'
          : 'Someone is typing...';
    }
    final typingNames = typingUserIds
        .map((id) => members[id]?.name ?? 'Someone')
        .take(2)
        .toList();
    final additionalCount = typingCount - 2;
    if (additionalCount > 0) {
      return '${typingNames.join(', ')} and $additionalCount other${additionalCount > 1 ? 's' : ''} are typing...';
    }
    return '${typingNames.join(', ')} are typing...';
  }

  Future<void> fetchMessages() async {
    isLoading.value = true;
    _messageSubscription?.cancel();
    _messageSubscription = APIs.getGroupMessages(
      groupId,
      limit: _pageSize,
    ).listen((snapshot) {
      final newMessages =
          snapshot.docs.map((e) => Message.fromJson(e.data())).toList();
      messages.assignAll(newMessages);
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _pageSize;
      isLoading.value = false;

      if (_firstLoad && messages.isNotEmpty) {
        APIs.markGroupMessagesAsRead(groupId);
        _firstLoad = false;
        scrollToBottom();
      }

      final addedDocs = snapshot.docChanges
          .where((change) => change.type == DocumentChangeType.added);
      if (addedDocs.isNotEmpty) {
        if (_isAtBottom()) {
          scrollToBottom();
        } else {
          hasNewMessage.value = true;
        }
      }
    }, onError: (e) {
      log('Error fetching group messages: $e');
      Get.snackbar('Error', 'Failed to load messages');
      isLoading.value = false;
    });
  }

  Future<void> fetchMoreMessages() async {
    if (!_hasMore || _lastDocument == null || isLoadingMore.value) return;

    isLoadingMore.value = true;
    try {
      APIs.getGroupMessages(
        groupId,
        limit: _pageSize,
        startAfter: _lastDocument,
      ).listen((snapshot) {
        final newMessages =
            snapshot.docs.map((e) => Message.fromJson(e.data())).toList();
        if (newMessages.isNotEmpty) {
          messages.addAll(newMessages);
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length == _pageSize;
        } else {
          _hasMore = false;
        }
        isLoadingMore.value = false;
        APIs.markGroupMessagesAsRead(groupId);
      }, onError: (e) {
        log('Error fetching more group messages: $e');
        Get.snackbar('Error', 'Failed to load more messages');
        isLoadingMore.value = false;
      });
    } catch (e) {
      log('Error fetching more group messages: $e');
      Get.snackbar('Error', 'Failed to load more messages');
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchMembers() async {
    membersLoading.value = true;
    try {
      final companyPath = await APIs.getCompanyPath();
      final groupDoc = await APIs.firestore
          .collection('companies/$companyPath/groups')
          .doc(groupId)
          .get();
      if (groupDoc.exists) {
        final memberIds = List<String>.from(groupDoc['members']);
        adminId.value = groupDoc['adminId'] ?? '';
        final users = await APIs.getUsersByIds(memberIds);
        members.clear();
        for (var user in users) {
          members[user.id] = user;
        }
      }
    } catch (e) {
      log('Error fetching group members: $e');
      Get.snackbar('Error', 'Failed to load members');
    } finally {
      membersLoading.value = false;
    }
  }

  Future<void> sendMessage() async {
    late Message tempMessage;
    if (textController.text.isNotEmpty) {
      final messageText = textController.text;
      textController.clear();
      try {
        tempMessage = Message(
          msg: messageText,
          toId: groupId,
          read: '',
          type: Type.text,
          fromId: APIs.user.uid,
          sent: Timestamp.fromDate(DateTime.now()),
        );
        messages.insert(0, tempMessage);

        await APIs.sendGroupMessage(groupId, messageText, Type.text);
        await APIs.markGroupMessagesAsRead(groupId);
        _typingTimer?.cancel();
        APIs.setGroupTypingStatus(groupId, APIs.user.uid, false);
        _isTyping = false;

        if (_isAtBottom()) {
          scrollToBottom();
        } else {
          hasNewMessage.value = true;
        }
      } catch (e) {
        log('Error sending group message: $e');
        textController.text = messageText;
        messages.removeWhere((m) => m.sent == tempMessage.sent);
        Get.snackbar('Error', 'Failed to send message');
      }
    }
  }

  Future<void> sendGroupImage(File file) async {
    isUploading.value = true;
    try {
      final tempMessage = Message(
        msg: 'uploading',
        toId: groupId,
        read: '',
        type: Type.image,
        fromId: APIs.user.uid,
        sent: Timestamp.fromDate(DateTime.now()),
      );
      messages.insert(0, tempMessage);

      await APIs.sendGroupImage(groupId, file);
      await APIs.markGroupMessagesAsRead(groupId);

      messages.remove(tempMessage);

      if (_isAtBottom()) {
        scrollToBottom();
      } else {
        hasNewMessage.value = true;
      }
    } catch (e) {
      log('Error uploading group image: $e');
      Get.snackbar('Error', 'Failed to upload image');
      messages.removeWhere((m) => m.msg == 'uploading');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> sendGroupImages(List<File> files) async {
    isUploading.value = true;
    try {
      final tempMessage = Message(
        msg: 'uploading',
        toId: groupId,
        read: '',
        type: Type.image,
        fromId: APIs.user.uid,
        sent: Timestamp.fromDate(DateTime.now()),
      );
      messages.insert(0, tempMessage);

      await APIs.sendGroupImages(groupId, files);
      await APIs.markGroupMessagesAsRead(groupId);

      messages.remove(tempMessage);

      if (_isAtBottom()) {
        scrollToBottom();
      } else {
        hasNewMessage.value = true;
      }
    } catch (e) {
      log('Error uploading group images: $e');
      Get.snackbar('Error', 'Failed to upload images');
      messages.removeWhere((m) => m.msg == 'uploading');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> sendGroupVideo(File file) async {
    isUploading.value = true;
    try {
      final tempMessage = Message(
        msg: 'uploading',
        toId: groupId,
        read: '',
        type: Type.video,
        fromId: APIs.user.uid,
        sent: Timestamp.fromDate(DateTime.now()),
      );
      messages.insert(0, tempMessage);

      await APIs.sendGroupVideo(groupId, file);
      await APIs.markGroupMessagesAsRead(groupId);

      messages.remove(tempMessage);

      if (_isAtBottom()) {
        scrollToBottom();
      } else {
        hasNewMessage.value = true;
      }
    } catch (e) {
      log('Error uploading group video: $e');
      Get.snackbar('Error', 'Failed to upload video');
      messages.removeWhere((m) => m.msg == 'uploading');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> sendGroupDocument(List<File> files) async {
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
        await APIs.sendGroupMessage(groupId, msgContent, Type.document);
        await APIs.markGroupMessagesAsRead(groupId);
      }
    } catch (e) {
      log('Error uploading documents: $e');
      Get.snackbar('Error', 'Failed to upload documents');
      Get.back();
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> sendGroupAudio(File file) async {
    isUploading.value = true;
    try {
      final url = await APIs.uploadAudio(file);
      final fileName = file.path.split('/').last;
      final msgContent = '$url|$fileName';
      await APIs.sendGroupMessage(groupId, msgContent, Type.audio);
      await APIs.markGroupMessagesAsRead(groupId);
    } catch (e) {
      log('Error uploading audio: $e');
      Get.snackbar('Error', 'Failed to upload audio');
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
        await sendGroupImages(files);
      }
    } catch (e) {
      log('Error picking images: $e');
      Get.snackbar('Error', 'Failed to pick images');
    }
  }

  Future<void> pickCameraImage() async {
    try {
      final picker = ImagePicker();
      final image =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (image != null) {
        await sendGroupImage(File(image.path));
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
        await sendGroupVideo(File(video.path));
      }
    } catch (e) {
      log('Error picking video: $e');
      Get.snackbar('Error', 'Failed to pick video');
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
        await sendGroupDocument(files);
      }
    } catch (e) {
      log('Error picking documents: $e');
      Get.snackbar('Error', 'Failed to pick documents');
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
        await sendGroupAudio(file);
      }
    } catch (e) {
      log('Error picking audio: $e');
      Get.snackbar('Error', 'Failed to pick audio');
    }
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
          toId: groupId,
          read: '',
          type: Type.text,
          fromId: APIs.user.uid,
          sent: Timestamp.fromDate(DateTime.now()),
        );
        messages.insert(0, tempMessage);
        try {
          await APIs.sendGroupMessage(groupId, msg, Type.text);
          await APIs.markGroupMessagesAsRead(groupId);
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

  Future<void> startRecording() async {
    if (hasRecordedAudio.value) {
      await discardRecordedAudio();
    }
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      final dir = await getTemporaryDirectory();
      recordingPath =
          '${dir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
        await startRecording();
      } else {
        Get.snackbar('Permission Denied', 'Microphone permission is required');
      }
    }
  }

  Future<void> stopRecording() async {
    try {
      await record.stop();
      isRecording.value = false;
      _recordingTimer?.cancel();
      if (recordingPath != null) {
        final file = File(recordingPath!);
        if (await file.exists()) {
          hasRecordedAudio.value = true;
          await audioPlayer.setSource(DeviceFileSource(recordingPath!));
          final duration = await audioPlayer.getDuration();
          audioDuration.value = duration ?? Duration.zero;
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
          await APIs.sendGroupMessage(groupId, msgContent, Type.audio);
          await APIs.markGroupMessagesAsRead(groupId);
          await file.delete();
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

  Future<void> editMessage(Message message, String newText) async {
    if (message.fromId != APIs.user.uid) return;
    try {
      final companyPath = await APIs.getCompanyPath();
      final ref = APIs.firestore
          .collection('companies/$companyPath/groups/$groupId/messages')
          .doc(message.sent as String);
      final newMsgText = '$newText (edited)';
      await ref.update({'msg': newMsgText});
    } catch (e) {
      log('Error editing message: $e');
      Get.snackbar('Error', 'Failed to edit message');
    }
  }

  Future<void> leaveGroup() async {
    try {
      await APIs.leaveGroup(groupId);
      Get.offAllNamed('/chatting_home');
    } catch (e) {
      log('Error leaving group: $e');
      Get.snackbar('Error', e.toString());
    }
  }

  void toggleEmoji() {
    showEmoji.value = !showEmoji.value;
  }

  List<ChatUser> getMessageReaders(Message message) {
    final messageTimestamp = message.sent.millisecondsSinceEpoch;
    final readers = <ChatUser>[];
    for (var entry in lastRead.entries) {
      final userId = entry.key;
      final lastReadTimestamp = entry.value;
      try {
        final lastReadInt = int.parse(lastReadTimestamp);
        if (lastReadInt >= messageTimestamp && userId != message.fromId) {
          final user = members[userId];
          if (user != null) {
            readers.add(user);
          }
        }
      } catch (e) {
        log('Error parsing last read timestamp for user $userId: $e');
      }
    }
    return readers;
  }
}
