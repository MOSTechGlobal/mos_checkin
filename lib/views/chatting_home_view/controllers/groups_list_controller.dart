import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../models/chat_user.dart';
import '../models/group_info.dart';
import '../utils/apis.dart';

class GroupsListController extends GetxController {
  final myGroups = <GroupInfo>[].obs;
  final isLoading = true.obs;
  final typingStatus =
      <String, List<String>>{}.obs; // Map of groupId to list of typing user IDs
  final userNameCache = <String, String>{}.obs; // Cache of userId to name
  final List<StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _groupSubscriptions = [];

  @override
  void onInit() {
    super.onInit();
    fetchGroups();
  }

  @override
  void onClose() {
    for (var sub in _groupSubscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  void fetchGroups() {
    APIs.getMyGroups().listen((snapshot) async {
      isLoading.value = false;
      myGroups.clear();
      final data = snapshot.docs;
      for (var doc in data) {
        final groupId = doc['groupId'] ?? '';
        final groupInfo = GroupInfo(
          groupId: groupId,
          groupName: doc['groupName'] ?? '',
          groupImage: doc['groupImage'] ?? '',
          lastMsg: doc['last_msg'] ?? '',
          lastMsgTime: doc['last_msg_time'] ?? '',
        );
        myGroups.add(groupInfo);
        _listenToGroupStatus(groupId);
      }
    }, onError: (e) {
      log('Error fetching groups: $e');
    });
  }

  void _listenToGroupStatus(String groupId) async {
    try {
      final companyPath = await APIs.getCompanyPath();
      if (companyPath == null) {
        log('Error: Company path not found for group $groupId');
        typingStatus[groupId] = [];
        return;
      }

      final subscription = APIs.firestore
          .collection('companies/$companyPath/groups')
          .doc(groupId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data();
          final typingUsersMap =
              data?['typingUsers'] as Map<String, dynamic>? ?? {};
          final typingUserIds = typingUsersMap.entries
              .where((e) => e.value == true && e.key != APIs.user.uid)
              .map((e) => e.key)
              .toList();
          typingStatus[groupId] = typingUserIds;

          // Pre-fetch user names for typing users
          if (typingUserIds.isNotEmpty) {
            await fetchUserNames(typingUserIds);
          }

          // Update group image and name if changed
          final index = myGroups.indexWhere((g) => g.groupId == groupId);
          if (index != -1) {
            myGroups[index] = GroupInfo(
              groupId: myGroups[index].groupId,
              groupName: data?['name'] ?? myGroups[index].groupName,
              groupImage: data?['image'] ?? myGroups[index].groupImage,
              lastMsg: myGroups[index].lastMsg,
              lastMsgTime: myGroups[index].lastMsgTime,
            );
          }
        } else {
          typingStatus[groupId] = [];
          log('Group $groupId does not exist');
        }
      }, onError: (e) {
        log('Error listening to group $groupId status: $e');
        typingStatus[groupId] = [];
      });
      _groupSubscriptions.add(subscription);
    } catch (e) {
      log('Error setting up group status listener for $groupId: $e');
      typingStatus[groupId] = [];
    }
  }

  Future<List<String>> fetchUserNames(List<String> userIds) async {
    try {
      final users = await APIs.getUsersByIds(userIds);
      final names = <String>[];
      for (var user in users) {
        userNameCache[user.id] = user.name; // Cache name
        names.add(user.name);
      }
      log('Fetched names for users $userIds: $names');
      return names;
    } catch (e) {
      log('Error fetching user names for $userIds: $e');
      return userIds; // Fallback to user IDs
    }
  }

  List<String> getCachedUserNames(List<String> userIds) {
    final names = <String>[];
    for (var id in userIds) {
      final name = userNameCache[id];
      if (name != null && name.isNotEmpty) {
        names.add(name);
      } else {
        names.add(id); // Fallback to ID if name not cached
      }
    }
    return names;
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await APIs.deleteGroup(groupId);
      myGroups.removeWhere((group) => group.groupId == groupId);
      typingStatus.remove(groupId);
      log('Deleted group $groupId');
    } catch (e) {
      log('Error deleting group $groupId: $e');
    }
  }
}
