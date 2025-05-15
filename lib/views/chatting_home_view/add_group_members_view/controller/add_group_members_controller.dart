import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../group_chat_view/controller/group_chat_controller.dart';
import '../../models/chat_user.dart';
import '../../utils/apis.dart';
import 'dart:developer' as developer;

class AddGroupMembersController extends GetxController {
  final allUsers = <ChatUser>[].obs;
  final filteredList = <ChatUser>[].obs;
  final selectedUsers = <ChatUser>[].obs;
  final selectionState = <String, bool>{}.obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isSearching = false.obs;
  final currentMembers = <String>[].obs;
  final isAdmin = false.obs;
  late String groupId;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void onInit() async {
    super.onInit();
    groupId = Get.arguments['groupId'] as String;
    await fetchCurrentMembers();
  }

  Future<void> fetchCurrentMembers() async {
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) {
        Get.snackbar('Error', 'Failed to load company path');
        Get.back();
        return;
      }

      final groupDoc = await FirebaseFirestore.instance
          .collection('companies/$companyPath/groups')
          .doc(groupId)
          .get();

      if (groupDoc.exists) {
        currentMembers.value = List<String>.from(groupDoc['members']);
        isAdmin.value = groupDoc['adminId'] == APIs.user.uid;
        if (!isAdmin.value) {
          Get.snackbar('Error', 'Only the admin can add members');
          Get.back();
          return;
        }
        fetchAllUsers();
      } else {
        Get.snackbar('Error', 'Group not found');
        Get.back();
      }
    } catch (e) {
      developer.log('Error fetching current members: $e');
      Get.snackbar('Error', 'Failed to load group members');
      Get.back();
    }
  }

  void fetchAllUsers() {
    isLoading.value = true;
    APIs.getAllUsers(limit: _pageSize).listen((snapshot) {
      allUsers.clear();
      final users = snapshot.docs
          .map((e) => ChatUser.fromJson(e.data()))
          .where((user) => !currentMembers.contains(user.id))
          .toList();
      allUsers.assignAll(users);
      filteredList.assignAll(users);
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _pageSize;

      // Initialize selection state for all users
      for (var user in users) {
        selectionState[user.id] ??= false;
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
          final newUsers = snapshot.docs
              .map((doc) => ChatUser.fromJson(doc.data()))
              .where((user) => !currentMembers.contains(user.id))
              .toList();
          if (newUsers.isNotEmpty) {
            allUsers.addAll(newUsers);
            filteredList.addAll(newUsers);
            _lastDocument = snapshot.docs.last;
            _hasMore = snapshot.docs.length == _pageSize;

            // Initialize selection state for new users
            for (var user in newUsers) {
              selectionState[user.id] ??= false;
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
              !currentMembers.contains(user.id) &&
              (user.name.toLowerCase().contains(lowerVal) ||
                  user.email.toLowerCase().contains(lowerVal)));

      filteredList.assignAll(users);
    } catch (e) {
      developer.log('Error searching users: $e');
      Get.snackbar('Error', 'Failed to search users');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSelection(ChatUser user) {
    if (currentMembers.contains(user.id)) return;

    // Ensure selection state is initialized
    if (!selectionState.containsKey(user.id)) {
      selectionState[user.id] = false;
    }

    final isSelected = selectionState[user.id]!;
    selectionState[user.id] = !isSelected;

    if (!isSelected) {
      selectedUsers.add(user);
    } else {
      selectedUsers.removeWhere((u) => u.id == user.id);
    }

    selectionState.refresh();
    developer.log(
        'Toggled selection for ${user.name}: ${selectionState[user.id]}, Selected users: ${selectedUsers.length}');
  }

  Future<void> addMembers() async {
    if (selectedUsers.isEmpty) {
      Get.snackbar('Error', 'Please select at least one user');
      return;
    }

    // Show loading dialog
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      await APIs.addMembersToGroup(groupId, selectedUsers.toList());

      // Close loading dialog
      Get.back();

      // Navigate back and update group chat
      Get.back();
      final groupChatController = Get.find<GroupChatController>(tag: groupId);
      if (groupChatController != null) {
        groupChatController.fetchMembers();
      }
      Get.snackbar('Success', 'Members added successfully');
    } catch (e) {
      // Close loading dialog
      Get.back();

      developer.log('Error adding members: $e');
      Get.snackbar('Error', e.toString());
    }
  }
}
