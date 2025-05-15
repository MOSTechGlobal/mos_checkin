import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/chat_user.dart';
import '../../models/message.dart';
import '../../utils/apis.dart';

class GroupProfileController extends GetxController {
  final groupId = ''.obs;
  final groupName = ''.obs;
  final adminId = ''.obs;
  final members = <String, ChatUser>{}.obs;
  final sharedImages = <String>[].obs;
  final isLoadingImages = false.obs;
  final isLoadingMoreImages = false.obs;
  final totalImageCount = 0.obs;
  final isLoading = true.obs;
  final membersLoading = true.obs;
  DocumentSnapshot? _lastImageDocument;
  final int _imagePageSize = 20;
  bool _hasMoreImages = true;
  final ScrollController scrollController = ScrollController();
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    groupId.value = args['groupId'] as String;
    groupName.value = args['groupName'] as String? ?? '';
    fetchGroupInfo();
    fetchMembers();
    fetchTotalImageCount();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.dispose();
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

  Future<void> fetchGroupInfo() async {
    try {
      isLoading.value = true;
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) {
        Get.snackbar('Error', 'Failed to load company path');
        isLoading.value = false;
        return;
      }

      final snapshot = await APIs.firestore
          .collection('companies/$companyPath/groups')
          .doc(groupId.value)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        groupName.value = data['name'] ?? '';
        adminId.value = data['adminId'] ?? '';
      }
    } catch (e, stackTrace) {
      log('Error fetching group info: $e\nStackTrace: $stackTrace');
      Get.snackbar('Error', 'Failed to load group info');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMembers() async {
    try {
      membersLoading.value = true;
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) {
        Get.snackbar('Error', 'Failed to load company path');
        membersLoading.value = false;
        return;
      }

      final groupDoc = await APIs.firestore
          .collection('companies/$companyPath/groups')
          .doc(groupId.value)
          .get();

      if (groupDoc.exists) {
        final memberIds = List<String>.from(groupDoc['members'] ?? []);
        final users = await APIs.getUsersByIds(memberIds);
        members.clear();
        for (var user in users) {
          members[user.id] = user;
        }
      }
    } catch (e, stackTrace) {
      log('Error fetching members: $e\nStackTrace: $stackTrace');
      Get.snackbar('Error', 'Failed to load members');
    } finally {
      membersLoading.value = false;
    }
  }

  Future<void> fetchTotalImageCount() async {
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) {
        Get.snackbar('Error', 'Failed to load company path');
        return;
      }

      final snapshot = await APIs.firestore
          .collection('companies/$companyPath/groups/${groupId.value}/messages')
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
    } catch (e, stackTrace) {
      log('Error fetching total image count: $e\nStackTrace: $stackTrace');
      Get.snackbar('Error', 'Failed to load image count');
    }
  }

  Future<void> fetchSharedImages() async {
    if (_retryCount >= _maxRetries) {
      log('Max retries reached for fetching images');
      isLoadingImages.value = false;
      Get.snackbar('Error', 'Unable to load images after multiple attempts');
      return;
    }

    isLoadingImages.value = true;
    sharedImages.clear();
    _retryCount++;

    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) {
        log('Company path is null');
        Get.snackbar('Error', 'Failed to load company path');
        isLoadingImages.value = false;
        return;
      }

      log('Fetching images for groupId: ${groupId.value}, companyPath: $companyPath, retry: $_retryCount');

      final query = APIs.firestore
          .collection('companies/$companyPath/groups/${groupId.value}/messages')
          .where('type', isEqualTo: Type.image.name)
          .orderBy('sent', descending: true)
          .limit(_imagePageSize);

      final snapshot = await query.get();
      final List<String> newImages = [];
      for (var doc in snapshot.docs) {
        final message = Message.fromJson(doc.data());
        final urls = message.msg
            .split(',')
            .where((url) => url.isNotEmpty && url != 'uploading' && Uri.parse(url).isAbsolute)
            .toList();
        newImages.addAll(urls);
        log('Message ID: ${doc.id}, URLs: $urls');
      }

      sharedImages.assignAll(newImages);
      log('Total images fetched: ${newImages.length}');
      if (snapshot.docs.isNotEmpty) {
        _lastImageDocument = snapshot.docs.last;
      }
      _hasMoreImages = snapshot.docs.length == _imagePageSize;
      isLoadingImages.value = false;
      _retryCount = 0;

      if (newImages.isEmpty && totalImageCount.value > 0) {
        log('No images fetched but count is ${totalImageCount.value}, retrying...');
        fetchSharedImages();
      }
    } catch (e, stackTrace) {
      log('Error fetching shared images: $e\nStackTrace: $stackTrace');
      Get.snackbar('Error', 'Failed to load images');
      isLoadingImages.value = false;
    }
  }

  Future<void> fetchMoreImages() async {
    if (!_hasMoreImages || _lastImageDocument == null) {
      log('No more images to fetch or last document is null');
      return;
    }

    isLoadingMoreImages.value = true;
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) {
        log('Company path is null');
        Get.snackbar('Error', 'Failed to load company path');
        isLoadingMoreImages.value = false;
        return;
      }

      log('Fetching more images for groupId: ${groupId.value}');

      final query = APIs.firestore
          .collection('companies/$companyPath/groups/${groupId.value}/messages')
          .where('type', isEqualTo: Type.image.name)
          .orderBy('sent', descending: true)
          .limit(_imagePageSize)
          .startAfterDocument(_lastImageDocument!);

      final snapshot = await query.get();
      final List<String> newImages = [];
      for (var doc in snapshot.docs) {
        final message = Message.fromJson(doc.data());
        final urls = message.msg
            .split(',')
            .where((url) => url.isNotEmpty && url != 'uploading' && Uri.parse(url).isAbsolute)
            .toList();
        newImages.addAll(urls);
        log('Message ID: ${doc.id}, URLs: $urls');
      }

      if (newImages.isNotEmpty) {
        sharedImages.addAll(newImages);
        _lastImageDocument = snapshot.docs.last;
        _hasMoreImages = snapshot.docs.length == _imagePageSize;
        log('Added ${newImages.length} more images, total: ${sharedImages.length}');
      } else {
        _hasMoreImages = false;
        log('No more images to fetch');
      }
      isLoadingMoreImages.value = false;
    } catch (e, stackTrace) {
      log('Error fetching more images: $e\nStackTrace: $stackTrace');
      Get.snackbar('Error', 'Failed to load more images');
      isLoadingMoreImages.value = false;
    }
  }

  Future<void> renameGroup(String newName) async {
    try {
      await APIs.updateGroupName(groupId.value, newName);
      groupName.value = newName;
      Get.snackbar('Success', 'Group name updated');
    } catch (e) {
      log('Error renaming group: $e');
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> leaveGroup() async {
    try {
      await APIs.leaveGroup(groupId.value);
      Get.back();
      Get.snackbar('Success', 'You have left the group');
    } catch (e) {
      log('Error leaving group: $e');
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> removeMember(String memberId) async {
    try {
      log('Attempting to remove member: $memberId from group: ${groupId.value}');
      await APIs.removeMemberFromGroup(groupId.value, memberId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Operation timed out');
        },
      );
      members.remove(memberId);
      log('Member $memberId removed successfully');
    } catch (e) {
      log('Error removing member: $e');
      throw e; // Let the view handle the snackbar
    }
  }
}