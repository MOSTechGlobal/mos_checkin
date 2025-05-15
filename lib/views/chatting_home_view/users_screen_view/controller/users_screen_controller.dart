import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../../utils/prefs.dart';
import '../../models/chat_user.dart';
import '../../utils/apis.dart';

class UsersScreenController extends GetxController {
  final allUsers = <ChatUser>[].obs;
  final filteredList = <ChatUser>[].obs;
  final isSearching = false.obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final companyName = ''.obs;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    final company = await Prefs.getCompanyName();
    companyName.value = company ?? '';
    isLoading.value = true;
    APIs.getFilteredUsers(limit: _pageSize).listen((snapshot) {
      allUsers.clear();
      final data = snapshot.docs;
      for (var doc in data) {
        allUsers.add(ChatUser.fromJson(doc.data()));
      }
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _pageSize;
      isLoading.value = false;
    }, onError: (e) {
      log('Error fetching users: $e');
      Get.snackbar('Error', 'Failed to load users');
      isLoading.value = false;
    });
  }

  Future<void> fetchMoreUsers() async {
    if (!_hasMore || _lastDocument == null || isLoadingMore.value) return;

    isLoadingMore.value = true;
    try {
      log('Fetching more users with last document: ${_lastDocument?.id}');
      if (_lastDocument != null) {
        final lastDocData = _lastDocument!.data() as Map<String, dynamic>?;
        log('Last document data: $lastDocData');
      }

      APIs.getFilteredUsers(limit: _pageSize, startAfter: _lastDocument).listen(
        (snapshot) {
          final newUsers = snapshot.docs
              .map((doc) => ChatUser.fromJson(doc.data()))
              .toList();
          if (newUsers.isNotEmpty) {
            allUsers.addAll(newUsers);
            _lastDocument = snapshot.docs.last;
            _hasMore = snapshot.docs.length == _pageSize;
          } else {
            _hasMore = false;
          }
          isLoadingMore.value = false;
        },
        onError: (e, stackTrace) {
          log('Error fetching more users: $e\nStackTrace: $stackTrace');
          Get.snackbar('Error', 'Failed to load more users: $e');
          _hasMore = false;
          isLoadingMore.value = false;
        },
        onDone: () {
          log('Stream closed for fetchMoreUsers');
          isLoadingMore.value = false;
        },
      );
    } catch (e, stackTrace) {
      log('Exception in fetchMoreUsers: $e\nStackTrace: $stackTrace');
      Get.snackbar('Error', 'Failed to load more users: $e');
      isLoadingMore.value = false;
    }
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    filteredList.clear();
    if (!isSearching.value) {
      // Reset to show all users when search is closed
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
      // Build the query with the same filtering conditions as getFilteredUsers
      var query = FirebaseFirestore.instance
          .collection('companies/$companyPath/users')
          .where('id', isNotEqualTo: APIs.user.uid)
          .where(Filter('type', arrayContainsAny: ['user', 'worker']));

      // Execute the query
      final snapshot = await query.get();

      // Filter users based on the search term (name or email)
      final users = snapshot.docs
          .map((doc) => ChatUser.fromJson(doc.data()))
          .where((user) =>
              user.name.toLowerCase().contains(lowerVal) ||
              user.email.toLowerCase().contains(lowerVal))
          .toList();

      filteredList.assignAll(users);
    } catch (e, stackTrace) {
      log('Error searching users: $e\nStackTrace: $stackTrace');
      Get.snackbar('Error', 'Failed to search users');
    } finally {
      isLoading.value = false;
    }
  }
}
