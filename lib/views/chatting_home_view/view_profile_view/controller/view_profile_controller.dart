import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/chat_user.dart';
import '../../models/message.dart';
import '../../utils/apis.dart';

class ViewProfileController extends GetxController {
  final user = Rxn<ChatUser>();
  final sharedImages = <String>[].obs;
  final sharedVideos = <Map<String, String>>[].obs;
  final sharedDocuments = <Map<String, String>>[].obs;
  final isLoadingImages = false.obs;
  final isLoadingVideos = false.obs;
  final isLoadingDocuments = false.obs;
  final isLoadingMoreImages = false.obs;
  final isLoadingMoreVideos = false.obs;
  final isLoadingMoreDocuments = false.obs;
  final totalImageCount = 0.obs;
  final totalVideoCount = 0.obs;
  final totalDocumentCount = 0.obs;
  DocumentSnapshot? _lastImageDocument;
  DocumentSnapshot? _lastVideoDocument;
  DocumentSnapshot? _lastDocumentDocument;
  final int _pageSize = 20;
  bool _hasMoreImages = true;
  bool _hasMoreVideos = true;
  bool _hasMoreDocuments = true;
  final ScrollController scrollController = ScrollController();
  final ScrollController videoScrollController = ScrollController();
  final ScrollController documentScrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    user.value = Get.arguments as ChatUser;
    fetchUserInfo();
    fetchTotalImageCount();
    fetchTotalVideoCount();
    fetchTotalDocumentCount();
    scrollController.addListener(_onScroll);
    videoScrollController.addListener(_onVideoScroll);
    documentScrollController.addListener(_onDocumentScroll);
  }

  @override
  void onClose() {
    scrollController.dispose();
    videoScrollController.dispose();
    documentScrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 50 &&
        !isLoadingMoreImages.value &&
        _hasMoreImages) {
      fetchMoreImages();
    }
  }

  void _onVideoScroll() {
    if (videoScrollController.position.pixels >=
        videoScrollController.position.maxScrollExtent - 50 &&
        !isLoadingMoreVideos.value &&
        _hasMoreVideos) {
      fetchMoreVideos();
    }
  }

  void _onDocumentScroll() {
    if (documentScrollController.position.pixels >=
        documentScrollController.position.maxScrollExtent - 50 &&
        !isLoadingMoreDocuments.value &&
        _hasMoreDocuments) {
      fetchMoreDocuments();
    }
  }

  void fetchUserInfo() {
    APIs.getUserInfo(user.value!).listen((snapshot) {
      final data = snapshot.docs;
      if (data.isNotEmpty) {
        user.value = ChatUser.fromJson(data[0].data());
      }
    }, onError: (e) {
      log('Error fetching user info: $e');
      Get.snackbar('Error', 'Failed to load user info');
    });
  }

  Future<void> fetchTotalImageCount() async {
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) return;
      final convoID = APIs.getConversationID(user.value!.id);
      final snapshot = await APIs.firestore
          .collection('companies/$companyPath/chats/$convoID/messages')
          .where('type', isEqualTo: Type.image.name)
          .get();
      int count = 0;
      for (var doc in snapshot.docs) {
        final message = Message.fromJson(doc.data());
        final urls = message.msg
            .split(',')
            .where((url) => url.isNotEmpty && url != 'uploading')
            .toList();
        count += urls.length;
      }
      totalImageCount.value = count;
    } catch (e) {
      log('Error fetching total image count: $e');
      Get.snackbar('Error', 'Failed to load image count');
    }
  }

  Future<void> fetchTotalVideoCount() async {
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) return;
      final convoID = APIs.getConversationID(user.value!.id);
      final snapshot = await APIs.firestore
          .collection('companies/$companyPath/chats/$convoID/messages')
          .where('type', isEqualTo: Type.video.name)
          .get();
      totalVideoCount.value = snapshot.docs.length;
    } catch (e) {
      log('Error fetching total video count: $e');
      Get.snackbar('Error', 'Failed to load video count');
    }
  }

  Future<void> fetchTotalDocumentCount() async {
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) return;
      final convoID = APIs.getConversationID(user.value!.id);
      final snapshot = await APIs.firestore
          .collection('companies/$companyPath/chats/$convoID/messages')
          .where('type', isEqualTo: Type.document.name)
          .get();
      totalDocumentCount.value = snapshot.docs.length;
    } catch (e) {
      log('Error fetching total document count: $e');
      Get.snackbar('Error', 'Failed to load document count');
    }
  }

  Future<void> fetchSharedImages() async {
    isLoadingImages.value = true;
    sharedImages.clear();
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) return;
      final convoID = APIs.getConversationID(user.value!.id);
      final query = APIs.firestore
          .collection('companies/$companyPath/chats/$convoID/messages')
          .where('type', isEqualTo: Type.image.name)
          .orderBy('sent', descending: true)
          .limit(_pageSize);
      final snapshot = await query.get();
      final List<String> newImages = [];
      for (var doc in snapshot.docs) {
        final message = Message.fromJson(doc.data());
        final urls = message.msg
            .split(',')
            .where((url) => url.isNotEmpty && url != 'uploading' && Uri.parse(url).isAbsolute)
            .toList();
        newImages.addAll(urls);
      }
      sharedImages.assignAll(newImages);
      if (snapshot.docs.isNotEmpty) {
        _lastImageDocument = snapshot.docs.last;
      }
      _hasMoreImages = snapshot.docs.length == _pageSize;
    } catch (e) {
      log('Error fetching shared images: $e');
      Get.snackbar('Error', 'Failed to load images');
    } finally {
      isLoadingImages.value = false;
    }
  }

  Future<void> fetchSharedVideos() async {
    isLoadingVideos.value = true;
    sharedVideos.clear();
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) return;
      final convoID = APIs.getConversationID(user.value!.id);
      final query = APIs.firestore
          .collection('companies/$companyPath/chats/$convoID/messages')
          .where('type', isEqualTo: Type.video.name)
          .orderBy('sent', descending: true)
          .limit(_pageSize);
      final snapshot = await query.get();
      final List<Map<String, String>> newVideos = [];
      for (var doc in snapshot.docs) {
        final message = Message.fromJson(doc.data());
        final urls = message.msg.split(',');
        final videoUrl = urls[0];
        final thumbnailUrl = urls.length > 1 ? urls[1] : '';
        if (Uri.parse(videoUrl).isAbsolute) {
          newVideos.add({'video': videoUrl, 'thumbnail': thumbnailUrl});
        }
      }
      sharedVideos.assignAll(newVideos);
      if (snapshot.docs.isNotEmpty) {
        _lastVideoDocument = snapshot.docs.last;
      }
      _hasMoreVideos = snapshot.docs.length == _pageSize;
    } catch (e) {
      log('Error fetching shared videos: $e');
      Get.snackbar('Error', 'Failed to load videos');
    } finally {
      isLoadingVideos.value = false;
    }
  }

  Future<void> fetchSharedDocuments() async {
    isLoadingDocuments.value = true;
    sharedDocuments.clear();
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) return;
      final convoID = APIs.getConversationID(user.value!.id);
      final query = APIs.firestore
          .collection('companies/$companyPath/chats/$convoID/messages')
          .where('type', isEqualTo: Type.document.name)
          .orderBy('sent', descending: true)
          .limit(_pageSize);
      final snapshot = await query.get();
      final List<Map<String, String>> newDocuments = [];
      for (var doc in snapshot.docs) {
        final message = Message.fromJson(doc.data());
        final parts = message.msg.split('|');
        final url = parts[0];
        final filename = parts.length > 1 ? parts[1] : 'Document';
        if (Uri.parse(url).isAbsolute) {
          newDocuments.add({'url': url, 'filename': filename});
        }
      }
      sharedDocuments.assignAll(newDocuments);
      if (snapshot.docs.isNotEmpty) {
        _lastDocumentDocument = snapshot.docs.last;
      }
      _hasMoreDocuments = snapshot.docs.length == _pageSize;
    } catch (e) {
      log('Error fetching shared documents: $e');
      Get.snackbar('Error', 'Failed to load documents');
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  Future<void> fetchMoreImages() async {
    if (!_hasMoreImages || _lastImageDocument == null) return;
    isLoadingMoreImages.value = true;
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) return;
      final convoID = APIs.getConversationID(user.value!.id);
      final query = APIs.firestore
          .collection('companies/$companyPath/chats/$convoID/messages')
          .where('type', isEqualTo: Type.image.name)
          .orderBy('sent', descending: true)
          .startAfterDocument(_lastImageDocument!)
          .limit(_pageSize);
      final snapshot = await query.get();
      final List<String> newImages = [];
      for (var doc in snapshot.docs) {
        final message = Message.fromJson(doc.data());
        final urls = message.msg
            .split(',')
            .where((url) => url.isNotEmpty && url != 'uploading' && Uri.parse(url).isAbsolute)
            .toList();
        newImages.addAll(urls);
      }
      if (newImages.isNotEmpty) {
        sharedImages.addAll(newImages);
        _lastImageDocument = snapshot.docs.last;
        _hasMoreImages = snapshot.docs.length == _pageSize;
      } else {
        _hasMoreImages = false;
      }
    } catch (e) {
      log('Error fetching more images: $e');
      Get.snackbar('Error', 'Failed to load more images');
    } finally {
      isLoadingMoreImages.value = false;
    }
  }

  Future<void> fetchMoreVideos() async {
    if (!_hasMoreVideos || _lastVideoDocument == null) return;
    isLoadingMoreVideos.value = true;
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) return;
      final convoID = APIs.getConversationID(user.value!.id);
      final query = APIs.firestore
          .collection('companies/$companyPath/chats/$convoID/messages')
          .where('type', isEqualTo: Type.video.name)
          .orderBy('sent', descending: true)
          .startAfterDocument(_lastVideoDocument!)
          .limit(_pageSize);
      final snapshot = await query.get();
      final List<Map<String, String>> newVideos = [];
      for (var doc in snapshot.docs) {
        final message = Message.fromJson(doc.data());
        final urls = message.msg.split(',');
        final videoUrl = urls[0];
        final thumbnailUrl = urls.length > 1 ? urls[1] : '';
        if (Uri.parse(videoUrl).isAbsolute) {
          newVideos.add({'video': videoUrl, 'thumbnail': thumbnailUrl});
        }
      }
      if (newVideos.isNotEmpty) {
        sharedVideos.addAll(newVideos);
        _lastVideoDocument = snapshot.docs.last;
        _hasMoreVideos = snapshot.docs.length == _pageSize;
      } else {
        _hasMoreVideos = false;
      }
    } catch (e) {
      log('Error fetching more videos: $e');
      Get.snackbar('Error', 'Failed to load more videos');
    } finally {
      isLoadingMoreVideos.value = false;
    }
  }

  Future<void> fetchMoreDocuments() async {
    if (!_hasMoreDocuments || _lastDocumentDocument == null) return;
    isLoadingMoreDocuments.value = true;
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) return;
      final convoID = APIs.getConversationID(user.value!.id);
      final query = APIs.firestore
          .collection('companies/$companyPath/chats/$convoID/messages')
          .where('type', isEqualTo: Type.document.name)
          .orderBy('sent', descending: true)
          .startAfterDocument(_lastDocumentDocument!)
          .limit(_pageSize);
      final snapshot = await query.get();
      final List<Map<String, String>> newDocuments = [];
      for (var doc in snapshot.docs) {
        final message = Message.fromJson(doc.data());
        final parts = message.msg.split('|');
        final url = parts[0];
        final filename = parts.length > 1 ? parts[1] : 'Document';
        if (Uri.parse(url).isAbsolute) {
          newDocuments.add({'url': url, 'filename': filename});
        }
      }
      if (newDocuments.isNotEmpty) {
        sharedDocuments.addAll(newDocuments);
        _lastDocumentDocument = snapshot.docs.last;
        _hasMoreDocuments = snapshot.docs.length == _pageSize;
      } else {
        _hasMoreDocuments = false;
      }
    } catch (e) {
      log('Error fetching more documents: $e');
      Get.snackbar('Error', 'Failed to load more documents');
    } finally {
      isLoadingMoreDocuments.value = false;
    }
  }
}