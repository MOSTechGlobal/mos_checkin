import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../controllers/chats_list_controller.dart';
import '../models/chat_user.dart';
import '../utils/app_colors.dart';
import '../utils/my_date_util.dart';

class ChatListTile extends StatelessWidget {
  final ChatUser user;
  final ChatsListController controller;

  const ChatListTile({super.key, required this.user, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(user.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Chat'),
              content: Text('Delete chat with ${user.name}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child:
                      const Text('DELETE', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => controller.deleteChat(user.id),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'avatar_${user.id}',
          child: CircleAvatar(
            radius: 28,
            backgroundColor: accentColor.withOpacity(0.1),
            backgroundImage:
                user.image.isNotEmpty ? NetworkImage(user.image) : null,
            child: user.image.isEmpty
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        fontSize: 18),
                  )
                : null,
          ),
        ),
        title: Text(
          user.name,
          style: TextStyle(
            fontWeight:
                user.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Obx(() {
          final isTyping = controller.typingStatus[user.id] == true;

          if (isTyping) {
            return const Text(
              'typing...',
              style: TextStyle(
                  fontSize: 14,
                  color: accentColor,
                  fontStyle: FontStyle.italic),
            );
          }

          final lastMsg = user.lastMessage;
          final isImage = lastMsg.startsWith('http') &&
              (lastMsg.contains('firebasestorage') ||
                  lastMsg.contains('.jpg') ||
                  lastMsg.contains('.png'));

          if (isImage) {
            return Row(
              children: [
                Icon(Icons.image,
                    size: 16,
                    color: user.unreadCount > 0 ? Colors.black : subtitleColor),
                const SizedBox(width: 4),
                Text(
                  'Image',
                  style: TextStyle(
                    fontSize: 14,
                    color: user.unreadCount > 0 ? Colors.black : subtitleColor,
                    fontWeight: user.unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            );
          }

          return Text(
            lastMsg.isNotEmpty ? lastMsg : 'No messages yet',
            style: TextStyle(
              fontSize: 14,
              color: user.unreadCount > 0 ? Colors.black : subtitleColor,
              fontWeight:
                  user.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          );
        }),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              MyDateUtil.getLastActiveTimeOnly(
                context: context,
                lastActive: user.lastActive,
              ),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (user.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor, // Use your app's accent color
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  user.unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        onTap: () => Get.toNamed(AppRoutes.chatScreenView, arguments: user),
      ),
    );
  }
}
