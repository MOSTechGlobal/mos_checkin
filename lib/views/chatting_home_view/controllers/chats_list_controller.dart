import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../models/chat_user.dart';
import '../utils/apis.dart';

class ChatsListController extends GetxController {
  final recentChats = <ChatUser>[].obs;
  final isLoading = true.obs;
  final typingStatus = RxMap<String, bool>();
  final List<StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _typingSubscriptions = [];

  @override
  void onInit() {
    super.onInit();
    fetchChats();
  }

  @override
  void onClose() {
    for (var sub in _typingSubscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  void fetchChats() {
    APIs.getMyChats().listen((snapshot) {
      isLoading.value = false;
      recentChats.clear();
      for (var sub in _typingSubscriptions) {
        sub.cancel();
      }
      _typingSubscriptions.clear();
      final data = snapshot.docs;
      for (var doc in data) {
        final friendId = doc['to_id'] == APIs.user.uid ? doc['from_id'] : doc['to_id'];
        recentChats.add(ChatUser(
          id: friendId,
          name: '',
          email: '',
          about: '',
          image: '',
          isOnline: false,
          pushToken: '',
          lastActive: doc['last_msg_time'] ?? '',
          lastMessage: doc['last_msg'] ?? '',
          unreadCount: doc['unreadCount'] ?? 0,
        ));
        fetchUserDetails(friendId);
        _listenToTypingStatus(friendId);
      }
    });
  }

  void _listenToTypingStatus(String friendId) {
    final convoID = APIs.getConversationID(friendId);
    final subscription = APIs.getTypingStatus(convoID).listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        typingStatus[friendId] = data?['typing_$friendId'] ?? false;
      } else {
        typingStatus[friendId] = false;
      }
    });
    _typingSubscriptions.add(subscription);
  }

  void fetchUserDetails(String friendId) async {
    final companyPath = await APIs.getCompanyPath();
    if (companyPath == null) {
      print('Error: Company path not found');
      return;
    }

    APIs.firestore
        .collection('companies/$companyPath/users')
        .where('id', isEqualTo: friendId)
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs;
      if (docs.isNotEmpty) {
        final friendData = ChatUser.fromJson(docs[0].data());
        final index = recentChats.indexWhere((u) => u.id == friendId);
        if (index != -1) {
          recentChats[index] = ChatUser(
            id: friendData.id,
            name: friendData.name,
            email: friendData.email,
            about: friendData.about,
            image: friendData.image,
            isOnline: friendData.isOnline,
            pushToken: friendData.pushToken,
            lastActive: recentChats[index].lastActive,
            lastMessage: recentChats[index].lastMessage,
            unreadCount: recentChats[index].unreadCount,
          );
        }
      }
    });
  }

  Future<void> deleteChat(String friendId) async {
    await APIs.deleteChat(friendId);
  }
}
