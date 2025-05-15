import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/chat_user.dart';
import '../../utils/apis.dart';
import 'dart:developer' as developer;

class GroupUserAddController extends GetxController {
  final allUsers = <ChatUser>[].obs;
  final filteredList = <ChatUser>[].obs;
  final selectedUsers = <ChatUser>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isSearching = false.obs;
  final groupNameController = TextEditingController();
  final groupName = ''.obs;
  final selectionState = <String, bool>{}.obs;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    // Sync groupName with controller
    groupNameController.addListener(() {
      groupName.value = groupNameController.text.trim();
    });
    fetchAllUsers();
  }

  void fetchAllUsers() {
    isLoading.value = true;
    APIs.getAllUsers(limit: _pageSize).listen((snapshot) {
      allUsers.clear();
      final users = snapshot.docs.map((e) => ChatUser.fromJson(e.data())).toList();
      allUsers.assignAll(users);
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _pageSize;
      // Initialize selection state for all users
      for (var user in users) {
        if (!selectionState.containsKey(user.id)) {
          selectionState[user.id] = false;
        }
      }
      isLoading.value = false;
      developer.log('Fetched ${users.length} users');
    }, onError: (e) {
      isLoading.value = false;
      developer.log('Error fetching users: $e');
      Get.snackbar('Error', 'Failed to load users: $e');
    });
  }

  Future<void> fetchMoreUsers() async {
    if (!_hasMore || _lastDocument == null || isLoadingMore.value) return;

    isLoadingMore.value = true;
    try {
      developer.log('Fetching more users with last document: ${_lastDocument?.id}');
      APIs.getAllUsers(limit: _pageSize, startAfter: _lastDocument).listen(
            (snapshot) {
          final newUsers = snapshot.docs.map((doc) => ChatUser.fromJson(doc.data())).toList();
          if (newUsers.isNotEmpty) {
            allUsers.addAll(newUsers);
            _lastDocument = snapshot.docs.last;
            _hasMore = snapshot.docs.length == _pageSize;
            // Initialize selection state for new users
            for (var user in newUsers) {
              if (!selectionState.containsKey(user.id)) {
                selectionState[user.id] = false;
              }
            }
          } else {
            _hasMore = false;
          }
          isLoadingMore.value = false;
        },
        onError: (e, stackTrace) {
          developer.log('Error fetching more users: $e\nStackTrace: $stackTrace');
          Get.snackbar('Error', 'Failed to load more users: $e');
          _hasMore = false;
          isLoadingMore.value = false;
        },
        onDone: () {
          developer.log('Stream closed for fetchMoreUsers');
          isLoadingMore.value = false;
        },
      );
    } catch (e, stackTrace) {
      developer.log('Exception in fetchMoreUsers: $e\nStackTrace: $stackTrace');
      Get.snackbar('Error', 'Failed to load more users: $e');
      isLoadingMore.value = false;
    }
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    filteredList.clear();
    if (!isSearching.value) {
      filteredList.assignAll(allUsers);
    }
  }

  void filterUsers(String val) async {
    filteredList.clear();
    if (val.isEmpty) {
      filteredList.assignAll(allUsers);
      return;
    }

    final companyPath = await APIs.getCompanyPath();
    if (companyPath == null) {
      Get.snackbar('Error', 'Company path not found');
      return;
    }

    isLoading.value = true;
    try {
      final lowerVal = val.toLowerCase();
      final snapshot = await FirebaseFirestore.instance
          .collection('companies/$companyPath/users')
          .where('id', isNotEqualTo: APIs.user.uid)
          .get();

      final users = snapshot.docs
          .map((doc) => ChatUser.fromJson(doc.data()))
          .where((user) =>
      user.name.toLowerCase().contains(lowerVal) ||
          user.email.toLowerCase().contains(lowerVal))
          .toList();

      filteredList.assignAll(users);
    } catch (e) {
      developer.log('Error searching users: $e');
      Get.snackbar('Error', 'Failed to search users');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSelection(ChatUser user) {
    final isSelected = selectionState[user.id] ?? false;
    selectionState[user.id] = !isSelected;
    if (!isSelected) {
      selectedUsers.add(user);
    } else {
      selectedUsers.removeWhere((u) => u.id == user.id);
    }
    selectionState.refresh(); // Ensure UI updates
    developer.log('Toggled selection for ${user.name}: ${selectionState[user.id]}');
  }

  Future<void> createGroup() async {
    if (groupName.isEmpty || selectedUsers.isEmpty) {
      Get.snackbar('Error', 'Group name and at least one user are required');
      return;
    }
    isLoading.value = true;
    try {
      await APIs.createGroup(groupName.value, selectedUsers.toList());
      developer.log('Group created: ${groupName.value} with ${selectedUsers.length} users');
      Get.back();
      // Reset form
      groupNameController.clear();
      groupName.value = '';
      selectedUsers.clear();
      selectionState.clear();
      for (var user in allUsers) {
        selectionState[user.id] = false;
      }
    } catch (e) {
      developer.log('Error creating group: $e');
      Get.snackbar('Error', 'Failed to create group: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    groupNameController.dispose();
    super.onClose();
  }
}