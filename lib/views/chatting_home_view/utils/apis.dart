import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import '../../../utils/prefs.dart';
import '../models/chat_user.dart';
import '../models/message.dart';

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;

  static User get user => auth.currentUser!;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      {int limit = 20, DocumentSnapshot? startAfter}) async* {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      log('Company path is null, returning empty stream');
      yield* const Stream.empty();
      return;
    }

    log('Building query for getAllUsers with limit: $limit, companyPath: $companyPath');
    if (startAfter != null) {
      log('Using startAfter document ID: ${startAfter.id}, data: ${startAfter.data()}');
    }

    try {
      var query = firestore
          .collection('companies/$companyPath/users')
          .where('id', isNotEqualTo: user.uid)
          .orderBy('id')
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      log('Executing query: companies/$companyPath/users, limit: $limit, ordered by id');
      yield* query.snapshots();
    } catch (e, stackTrace) {
      log('Error in getAllUsers query: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  // New function to fetch users by type ("user" or "worker")
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUsersByType(
      {int limit = 20, DocumentSnapshot? startAfter}) async* {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      log('Company path is null, returning empty stream');
      yield* const Stream.empty();
      return;
    }

    log('Building query for getUsersByType with limit: $limit, companyPath: $companyPath');
    if (startAfter != null) {
      log('Using startAfter document ID: ${startAfter.id}, data: ${startAfter.data()}');
    }

    try {
      var query = firestore
          .collection('companies/$companyPath/users')
          .where('id', isNotEqualTo: user.uid)
          .where('type', arrayContainsAny: ['user', 'worker'])
          .orderBy('id')
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      log('Executing query: companies/$companyPath/users, where type contains "user" or "worker", limit: $limit, ordered by id');
      yield* query.snapshots();
    } catch (e, stackTrace) {
      log('Error in getUsersByType query: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  // New function to fetch users by rmId or tlId matching current user's ID
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUsersByRmIdOrTlId(
      {int limit = 20, DocumentSnapshot? startAfter}) async* {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      log('Company path is null, returning empty stream');
      yield* const Stream.empty();
      return;
    }

    log('Building query for getUsersByRmIdOrTlId with limit: $limit, companyPath: $companyPath');
    if (startAfter != null) {
      log('Using startAfter document ID: ${startAfter.id}, data: ${startAfter.data()}');
    }

    try {
      var query = firestore
          .collection('companies/$companyPath/users')
          .where('id', isNotEqualTo: user.uid)
          .where(Filter.or(
            Filter('rmId', isEqualTo: user.uid),
            Filter('tlId', isEqualTo: user.uid),
          ))
          .orderBy('id')
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      log('Executing query: companies/$companyPath/users, where rmId == ${user.uid} or tlId == ${user.uid}, limit: $limit, ordered by id');
      yield* query.snapshots();
    } catch (e, stackTrace) {
      log('Error in getUsersByRmIdOrTlId query: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  // Combined function to fetch users satisfying either condition
  static Stream<QuerySnapshot<Map<String, dynamic>>> getFilteredUsers(
      {int limit = 20, DocumentSnapshot? startAfter}) async* {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      log('Company path is null, returning empty stream');
      yield* const Stream.empty();
      return;
    }

    log('Building query for getFilteredUsers with limit: $limit, companyPath: $companyPath');
    if (startAfter != null) {
      log('Using startAfter document ID: ${startAfter.id}, data: ${startAfter.data()}');
    }

    try {
      var query = firestore
          .collection('companies/$companyPath/users')
          .where('id', isNotEqualTo: user.uid)
          .where(Filter('type', arrayContainsAny: ['user', 'worker']))
          .orderBy('id')
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      log('Executing query: companies/$companyPath/users, where type contains "user" or "worker" or rmId == ${user.uid} or tlId == ${user.uid}, limit: $limit, ordered by id');
      yield* query.snapshots();
    } catch (e, stackTrace) {
      log('Error in getFilteredUsers query: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUserInfo() {
    return firestore
        .collection('users')
        .where('id', isEqualTo: user.uid)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser user) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: user.id)
        .snapshots();
  }

  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  static Future<void> sendMessage(ChatUser chatUser, String msg, Type type,
      {LocationType? locationType, int? duration}) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    final message = {
      'msg': msg,
      'toId': chatUser.id,
      'read': '',
      'type': type.name,
      'locationType': locationType?.name,
      'duration': duration,
      'fromId': user.uid,
      'sent': FieldValue.serverTimestamp(),
    };

    final ref = firestore.collection(
        'companies/$companyPath/chats/${getConversationID(chatUser.id)}/messages');
    await ref.add(message);

    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final senderChatRef = firestore
        .collection('companies/$companyPath/users/${user.uid}/my_chats')
        .doc(chatUser.id);
    final receiverChatRef = firestore
        .collection('companies/$companyPath/users/${chatUser.id}/my_chats')
        .doc(user.uid);

    final commonData = {
      'last_msg': msg,
      'last_msg_time': time,
      'to_id': chatUser.id,
      'from_id': user.uid,
    };

    await senderChatRef.set(commonData, SetOptions(merge: true));

    await receiverChatRef.set({
      ...commonData,
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser chatUser,
      {int limit = 20,
      DocumentSnapshot? startAfter}) async* {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      yield* const Stream.empty();
      return;
    }

    final convoID = getConversationID(chatUser.id);
    var query = firestore
        .collection('companies/$companyPath/chats/$convoID/messages')
        .orderBy('sent', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    yield* query.snapshots();
  }

  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await sendMessage(chatUser, msg, type);
  }

  static Future<void> sendChatImage(ChatUser chatUser, List<File> files) async {
    try {
      final companyPath = await getCompanyPath();
      if (companyPath == null) {
        throw Exception('Company path not found');
      }

      final List<String> imageUrls = [];

      for (var file in files) {
        final compressedFile = await _compressImage(file);
        final ext = compressedFile.path.split('.').last;
        final time = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = storage.ref().child(
            'companies/$companyPath/users/${user.uid}/images/$time.$ext');
        await ref.putFile(
            compressedFile, SettableMetadata(contentType: 'image/$ext'));
        final imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      await sendMessage(chatUser, imageUrls.join(','), Type.image);
    } catch (e) {
      log('Error uploading images: $e');
      rethrow;
    }
  }

  static Future<void> sendChatVideo(ChatUser chatUser, File file) async {
    try {
      log('Starting video upload process for user: ${chatUser.id}');
      final companyPath = await getCompanyPath();
      log('Company path: $companyPath');
      if (companyPath == null) {
        throw Exception('Company path not found');
      }

      // Verify input file exists
      if (!file.existsSync()) {
        throw Exception('Input video file does not exist: ${file.path}');
      }
      final compressedVideo = await _compressVideo(file);
      if (!compressedVideo.existsSync()) {
        throw Exception(
            'Compressed video file does not exist: ${compressedVideo.path}');
      }
      final ext = compressedVideo.path.split('.').last;
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      final videoRef = storage
          .ref()
          .child('companies/$companyPath/users/${user.uid}/videos/$time.$ext');
      await videoRef.putFile(
          compressedVideo, SettableMetadata(contentType: 'video/$ext'));
      final videoUrl = await videoRef.getDownloadURL();
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        compressedVideo.path,
        quality: 70,
        position: -1,
      );
      if (!thumbnailFile.existsSync()) {
        throw Exception('Thumbnail file does not exist: ${thumbnailFile.path}');
      }
      final thumbRef = storage.ref().child(
          'companies/$companyPath/users/${user.uid}/videos/${time}_thumb.jpg.jpg');
      await thumbRef.putFile(
          thumbnailFile, SettableMetadata(contentType: 'image/jpeg'));
      final thumbUrl = await thumbRef.getDownloadURL();
      await sendMessage(chatUser, '$videoUrl,$thumbUrl', Type.video);
      await VideoCompress.deleteAllCache();
    } catch (e) {
      log('Error uploading video: $e', stackTrace: StackTrace.current);
      rethrow;
    }
  }

  static Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );
      if (compressedFile == null) {
        throw Exception('Image compression failed');
      }
      return File(compressedFile.path);
    } catch (e) {
      log('Error compressing image: $e');
      return file;
    }
  }

  static Future<File> _compressVideo(File file) async {
    try {
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      if (info == null || info.file == null) {
        throw Exception('Video compression failed: No output file generated');
      }
      final compressedFile = info.file!;
      if (!compressedFile.existsSync()) {
        throw Exception(
            'Compressed file does not exist: ${compressedFile.path}');
      }
      return compressedFile;
    } catch (e) {
      log('Error compressing video: $e', stackTrace: StackTrace.current);
      return file;
    }
  }

  static Future<String> uploadDocument(File file) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }
    final ext = file.path.split('.').last;
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = storage
        .ref()
        .child('companies/$companyPath/users/${user.uid}/documents/$time.$ext');
    final uploadTask =
        ref.putFile(file, SettableMetadata(contentType: mimeType));
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      log('Upload progress: $progress%');
    });
    await uploadTask;
    return await ref.getDownloadURL();
  }

  static Future<String> uploadAudio(File file) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }
    final ext = file.path.split('.').last;
    final mimeType = lookupMimeType(file.path) ?? 'audio/mpeg';
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = storage
        .ref()
        .child('companies/$companyPath/users/${user.uid}/audio/$time.$ext');
    final uploadTask =
        ref.putFile(file, SettableMetadata(contentType: mimeType));
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      log('Upload progress: $progress%');
    });
    await uploadTask;
    return await ref.getDownloadURL();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyChats() async* {
    final companyPath = await getCompanyPath();
    yield* firestore
        .collection('companies/$companyPath/users/${user.uid}/my_chats')
        .orderBy('last_msg_time', descending: true)
        .snapshots();
  }

  static Future<String> createGroup(
      String groupName, List<ChatUser> members) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    final groupCountRef = firestore
        .collection('companies/$companyPath/metadata')
        .doc('groupcount');

    final newGroupNumber =
        await firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(groupCountRef);
      int currentCount = 0;
      if (snapshot.exists) {
        currentCount = snapshot.data()?['count'] ?? 0;
      }
      final newCount = currentCount + 1;
      transaction.set(
          groupCountRef, {'count': newCount}, SetOptions(merge: true));
      return newCount;
    });

    final groupId = 'group_$newGroupNumber';

    final allIds = members.map((e) => e.id).toList();
    if (!allIds.contains(user.uid)) {
      allIds.add(user.uid);
    }
    allIds.sort();
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final groupDoc = {
      'id': groupId,
      'name': groupName,
      'image': '',
      'createdBy': user.uid,
      'createdAt': time,
      'members': allIds,
      'adminId': user.uid,
      'typingUsers': {},
      'lastRead': {},
    };

    await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .set(groupDoc);

    for (var m in allIds) {
      await firestore
          .collection('companies/$companyPath/users/$m/my_groups')
          .doc(groupId)
          .set({
        'groupId': groupId,
        'groupName': groupName,
        'groupImage': '',
        'createdAt': time,
        'last_msg': 'Tap to start group chat',
        'last_msg_time': '',
      });
    }

    return groupId;
  }

  static Future<void> deleteGroup(String groupId) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .delete();
  }

  static Future<void> updateGroupName(String groupId, String newName) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    final groupDoc = await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .get();
    if (groupDoc.exists && groupDoc['adminId'] == user.uid) {
      await firestore
          .collection('companies/$companyPath/groups')
          .doc(groupId)
          .update({
        'name': newName,
      });
      final members = List<String>.from(groupDoc['members']);
      for (var m in members) {
        await firestore
            .collection('companies/$companyPath/users/$m/my_groups')
            .doc(groupId)
            .update({
          'groupName': newName,
        });
      }
    } else {
      throw Exception('Only the admin can rename the group');
    }
  }

  static Future<void> addMembersToGroup(
      String groupId, List<ChatUser> newMembers) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    final groupDoc = await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .get();
    if (!groupDoc.exists) {
      throw Exception('Group not found');
    }
    if (groupDoc['adminId'] != user.uid) {
      throw Exception('Only the admin can add members');
    }

    final groupData = groupDoc.data()!;
    List<String> currentMembers = List<String>.from(groupData['members']);
    final newMemberIds = newMembers.map((e) => e.id).toList();

    currentMembers
        .addAll(newMemberIds.where((id) => !currentMembers.contains(id)));
    currentMembers.sort();

    await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .update({
      'members': currentMembers,
    });

    final groupName = groupData['name'] as String;
    final createdAt = groupData['createdAt'] as String;
    final groupImage = groupData['image'] ?? '';
    final lastMessage = groupData['lastMessage'] ?? 'Tap to start group chat';
    final lastMessageTime = groupData['lastMessageTime'] ?? '';

    for (var memberId in newMemberIds) {
      await firestore
          .collection('companies/$companyPath/users/$memberId/my_groups')
          .doc(groupId)
          .set({
        'groupId': groupId,
        'groupName': groupName,
        'groupImage': groupImage,
        'createdAt': createdAt,
        'last_msg': lastMessage,
        'last_msg_time': lastMessageTime,
      });
    }
  }

  static Future<void> removeMemberFromGroup(
      String groupId, String memberId) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    final groupDoc = await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .get();
    if (!groupDoc.exists) return;
    if (groupDoc['adminId'] != user.uid) {
      throw Exception('Only the admin can remove members');
    }
    if (memberId == groupDoc['adminId']) {
      throw Exception('Admin cannot be removed');
    }

    final groupData = groupDoc.data()!;
    List<String> currentMembers = List<String>.from(groupData['members']);
    if (!currentMembers.contains(memberId)) return;
    currentMembers.remove(memberId);
    if (currentMembers.length < 2) {
      for (var m in currentMembers) {
        await firestore
            .collection('companies/$companyPath/users/$m/my_groups')
            .doc(groupId)
            .delete();
      }
      await firestore
          .collection('companies/$companyPath/groups')
          .doc(groupId)
          .delete();
      await _deleteCollection(
          'companies/$companyPath/groups/$groupId/messages');
      return;
    }

    currentMembers.sort();
    await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .update({'members': currentMembers});

    await firestore
        .collection('companies/$companyPath/users/$memberId/my_groups')
        .doc(groupId)
        .delete();
  }

  static Future<void> leaveGroup(String groupId) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    final groupDoc = await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .get();
    if (!groupDoc.exists) return;
    if (groupDoc['adminId'] == user.uid) {
      throw Exception('Admin cannot leave the group');
    }

    final groupData = groupDoc.data()!;
    List<String> currentMembers = List<String>.from(groupData['members']);
    if (!currentMembers.contains(user.uid)) return;
    currentMembers.remove(user.uid);
    if (currentMembers.length < 2) {
      for (var m in currentMembers) {
        await firestore
            .collection('companies/$companyPath/users/$m/my_groups')
            .doc(groupId)
            .delete();
      }
      await firestore
          .collection('companies/$companyPath/groups')
          .doc(groupId)
          .delete();
      await _deleteCollection(
          'companies/$companyPath/groups/$groupId/messages');
      return;
    }

    await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .update({
      'members': currentMembers,
    });

    await firestore
        .collection('companies/$companyPath/users/${user.uid}/my_groups')
        .doc(groupId)
        .delete();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyGroups() async* {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      yield* const Stream.empty();
      return;
    }

    yield* firestore
        .collection('companies/$companyPath/users/${user.uid}/my_groups')
        .orderBy('last_msg_time', descending: true)
        .snapshots();
  }

  static Future<void> deleteChat(String friendId) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    await firestore
        .collection('companies/$companyPath/users/${user.uid}/my_chats')
        .doc(friendId)
        .delete();
  }

  static Future<void> editMessage(
      ChatUser chatUser, Message message, String newText) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    if (message.fromId != user.uid) return;
    final convoID = getConversationID(chatUser.id);
    final ref = firestore
        .collection('companies/$companyPath/chats/$convoID/messages')
        .doc(message.sent as String);
    final newMsgText = '$newText (edited)';
    await ref.update({'msg': newMsgText});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getGroupMessages(
      String groupId,
      {int limit = 20,
      DocumentSnapshot? startAfter}) async* {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      yield* const Stream.empty();
      return;
    }

    var query = firestore
        .collection('companies/$companyPath/groups/$groupId/messages')
        .orderBy('sent', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    yield* query.snapshots();
  }

  static Future<void> sendGroupMessage(
      String groupId, String msg, Type type) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final message = {
      'msg': msg,
      'toId': groupId,
      'read': '',
      'type': type.name,
      'fromId': user.uid,
      'sent': FieldValue.serverTimestamp(),
    };

    final ref =
        firestore.collection('companies/$companyPath/groups/$groupId/messages');
    await ref.doc(time).set(message);

    final groupDoc = await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .get();
    if (groupDoc.exists) {
      final members = List<String>.from(groupDoc['members']);
      for (var m in members) {
        await firestore
            .collection('companies/$companyPath/users/$m/my_groups')
            .doc(groupId)
            .update({
          'last_msg': msg,
          'last_msg_time': time,
        });
      }
    }
  }

  static Future<void> sendGroupImage(String groupId, File file) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }

    try {
      final compressedFile = await _compressImage(file);
      final ext = compressedFile.path.split('.').last;
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = storage
          .ref()
          .child('companies/$companyPath/groups/$groupId/images/$time.$ext');
      await ref.putFile(
          compressedFile, SettableMetadata(contentType: 'image/$ext'));
      final imageUrl = await ref.getDownloadURL();
      await sendGroupMessage(groupId, imageUrl, Type.image);
    } catch (e) {
      log('Error uploading group image: $e');
      rethrow;
    }
  }

  static Future<void> sendGroupImages(String groupId, List<File> files) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }
    try {
      final List<String> imageUrls = [];
      for (var file in files) {
        final compressedFile = await _compressImage(file);
        final ext = compressedFile.path.split('.').last;
        final time = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = storage
            .ref()
            .child('companies/$companyPath/groups/$groupId/images/$time.$ext');
        await ref.putFile(
            compressedFile, SettableMetadata(contentType: 'image/$ext'));
        final imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }
      await sendGroupMessage(groupId, imageUrls.join(','), Type.image);
    } catch (e) {
      log('Error uploading group images: $e');
      rethrow;
    }
  }

  static Future<void> sendGroupVideo(String groupId, File file) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      throw Exception('Company path not found');
    }
    try {
      final compressedVideo = await _compressVideo(file);
      final ext = compressedVideo.path.split('.').last;
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = storage
          .ref()
          .child('companies/$companyPath/groups/$groupId/videos/$time.$ext');
      await ref.putFile(
          compressedVideo, SettableMetadata(contentType: 'video/$ext'));
      final videoUrl = await ref.getDownloadURL();
      await sendGroupMessage(groupId, videoUrl, Type.video);
    } catch (e) {
      log('Error uploading group video: $e');
      rethrow;
    }
  }

  static Future<List<ChatUser>> getUsersByIds(List<String> ids) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      return [];
    }

    final List<ChatUser> users = [];
    for (var id in ids) {
      final snapshot = await firestore
          .collection('companies/$companyPath/users')
          .doc(id)
          .get();
      if (snapshot.exists) {
        users.add(ChatUser.fromJson(snapshot.data()!));
      }
    }
    return users;
  }

  static Future<void> _deleteCollection(String path) async {
    final snapshots = await firestore.collection(path).get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  static Future<String?> getCompanyPath() async {
    try {
      final companyPath = await Prefs.getCompanyName();

      if (companyPath == 'dev') {
        return 'moscare_dev';
      }

      return companyPath;
    } catch (e) {
      print('Error fetching company path: $e');
      return 'default_company_path';
    }
  }

  static Future<void> markMessagesAsRead(ChatUser chatUser) async {
    try {
      final companyPath = await getCompanyPath();
      if (companyPath == null) {
        throw Exception('Company path not found');
      }

      final convoID = getConversationID(chatUser.id);
      final messagesRef = firestore
          .collection('companies/$companyPath/chats/$convoID/messages')
          .where('toId', isEqualTo: user.uid)
          .where('read', isEqualTo: '');

      final snapshot = await messagesRef.get();
      final batch = firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'read': DateTime.now().millisecondsSinceEpoch.toString(),
        });
      }
      await batch.commit();

      // Reset unreadCount to 0 for the current user's chat
      await firestore
          .collection('companies/$companyPath/users/${user.uid}/my_chats')
          .doc(chatUser.id)
          .update({'unreadCount': 0});
    } catch (e) {
      log('Error marking messages as read: $e');
    }
  }

  static Future<void> markGroupMessagesAsRead(String groupId) async {
    try {
      final companyPath = await getCompanyPath();
      if (companyPath == null) {
        throw Exception('Company path not found');
      }

      final time = DateTime.now().millisecondsSinceEpoch.toString();
      await firestore
          .collection('companies/$companyPath/groups')
          .doc(groupId)
          .update({
        'lastRead.${user.uid}': time,
      });
    } catch (e) {
      log('Error marking group messages as read: $e');
    }
  }

  static Future<void> setTypingStatus(
      String convoID, String userId, bool isTyping) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) return;
    await firestore
        .collection('companies/$companyPath/chats')
        .doc(convoID)
        .set({
      'typing_$userId': isTyping,
      'users': FieldValue.arrayUnion([userId]),
    }, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> getTypingStatus(
      String convoID) async* {
    final companyPath = await getCompanyPath();
    if (companyPath == null) {
      yield* const Stream.empty();
      return;
    }
    yield* firestore
        .collection('companies/$companyPath/chats')
        .doc(convoID)
        .snapshots();
  }

  static Future<void> setGroupTypingStatus(
      String groupId, String userId, bool isTyping) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) return;
    await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .update({
      'typingUsers.$userId': isTyping,
    });
  }

  static Future<void> updateLastRead(
      String groupId, String userId, String timestamp) async {
    final companyPath = await getCompanyPath();
    if (companyPath == null) return;
    await firestore
        .collection('companies/$companyPath/groups')
        .doc(groupId)
        .update({
      'lastRead.$userId': timestamp,
    });
  }
}
