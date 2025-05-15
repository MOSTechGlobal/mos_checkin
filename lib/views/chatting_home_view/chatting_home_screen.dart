import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mos_checkin/views/chatting_home_view/widgets/chat_list_tile.dart';
import 'package:mos_checkin/views/chatting_home_view/widgets/group_list_tile.dart';
import 'package:shimmer/shimmer.dart';

import '../../routes/app_routes.dart';
import 'controllers/chats_list_controller.dart';
import 'controllers/chatting_home_controller.dart';
import 'controllers/groups_list_controller.dart';

class ChattingHomeScreen extends GetView<ChattingHomeController> {
  const ChattingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: true,
      child: DefaultTabController(
        length: 3, // Added a third tab for status/stories
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: colorScheme.primary,
            elevation: 0,
            title: const Text(
              'MosBoss',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.search, color: Colors.white),
            //     onPressed: () {
            //     },
            //   ),
            //   IconButton(
            //     icon: const Icon(Icons.more_vert, color: Colors.white),
            //     onPressed: () {
            //     },
            //   ),
            // ],
            bottom: TabBar(
              controller: controller.tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3.0,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: 'Chats'),
                Tab(text: 'Groups'),
              ],
            ),
          ),
          body: TabBarView(
            controller: controller.tabController,
            children: const [
              ChatsListScreen(),
              GroupsListScreen(),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatsListScreen extends GetView<ChatsListController> {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed(AppRoutes.usersScreenView);
        },
        backgroundColor: colorScheme.primary,
        label: const Text(
          'New Chat',
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.chat, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmer();
        }

        final chats = controller.recentChats;

        if (chats.isEmpty) {
          return _buildNoChatsUI();
        }

        return ListView.separated(
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 72,
            color: Colors.grey[200],
          ),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final user = chats[index];
            return ChatListTile(user: user, controller: controller);
          },
        );
      }),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 140, height: 14, color: Colors.white),
                        Container(width: 40, height: 10, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(width: 200, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoChatsUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No recent chats',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Start a conversation by tapping the chat icon below',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}

class GroupsListScreen extends GetView<GroupsListController> {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.group_add, color: Colors.white),
        onPressed: () => Get.toNamed(AppRoutes.groupUserAddView),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmer();
        }

        final groups = controller.myGroups;

        if (groups.isEmpty) {
          return _buildNoGroupsUI();
        }

        return ListView.separated(
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 72,
            color: Colors.grey[200],
          ),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return GroupListTile(group: group, controller: controller);
          },
        );
      }),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 140, height: 14, color: Colors.white),
                        Container(width: 40, height: 10, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(width: 200, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoGroupsUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create a group by tapping the button below',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}
