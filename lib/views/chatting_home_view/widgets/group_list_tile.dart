import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../controllers/groups_list_controller.dart';
import '../models/group_info.dart';
import '../utils/app_colors.dart';
import '../utils/my_date_util.dart';

class GroupListTile extends StatelessWidget {
  final GroupInfo group;
  final GroupsListController controller;

  const GroupListTile({
    super.key,
    required this.group,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(group.groupId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Group'),
              content: Text('Delete group "${group.groupName}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('DELETE', style: TextStyle(color: Colors.red)),
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
      onDismissed: (_) => controller.deleteGroup(group.groupId),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'group_avatar_${group.groupId}',
          child: CircleAvatar(
            radius: 28,
            backgroundColor: accentColor.withOpacity(0.1),
            backgroundImage: group.groupImage.isNotEmpty
                ? NetworkImage(group.groupImage)
                : null,
            child: group.groupImage.isEmpty
                ? Text(
              group.groupName.isNotEmpty
                  ? group.groupName[0].toUpperCase()
                  : 'G',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: accentColor,
                fontSize: 18,
              ),
            )
                : null,
          ),
        ),
        title: Text(
          group.groupName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Obx(() {
          final typingUserIds = controller.typingStatus[group.groupId] ?? [];
          final isTyping = typingUserIds.isNotEmpty;

          if (isTyping) {
            final cachedNames = controller.getCachedUserNames(typingUserIds);
            if (cachedNames.isNotEmpty) {
              return Text(
                cachedNames.length > 2
                    ? '${cachedNames.take(2).join(", ")} and ${cachedNames.length - 2} others typing...'
                    : '${cachedNames.join(", ")} typing...',
                style: const TextStyle(
                  fontSize: 14,
                  color: accentColor,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }
            // Fetch names asynchronously and update UI when ready
            controller.fetchUserNames(typingUserIds).then((names) {
              if (names.isNotEmpty) {
                controller.typingStatus.refresh(); // Trigger UI update
              }
            });
            return const SizedBox.shrink(); // Show nothing until names are ready
          }

          final lastMsg = group.lastMsg;
          final isImage = lastMsg.startsWith('http') &&
              (lastMsg.contains('firebasestorage') ||
                  lastMsg.contains('.jpg') ||
                  lastMsg.contains('.png'));

          if (isImage) {
            return const Row(
              children: [
                Icon(Icons.image, size: 16, color: subtitleColor),
                SizedBox(width: 4),
                Text(
                  'Image',
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
              ],
            );
          }

          return Text(
            lastMsg.isNotEmpty ? lastMsg : 'No messages yet',
            style: const TextStyle(
              fontSize: 14,
              color: subtitleColor,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          );
        }),
        trailing: group.lastMsgTime.isNotEmpty
            ? Text(
          MyDateUtil.getLastActiveTimeOnly(
            context: context,
            lastActive: group.lastMsgTime,
          ),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        )
            : const SizedBox.shrink(),
        onTap: () => Get.toNamed(
          AppRoutes.groupChatView,
          arguments: {'groupId': group.groupId, 'groupName': group.groupName},
        ),
      ),
    );
  }
}