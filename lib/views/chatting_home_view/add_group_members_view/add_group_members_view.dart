import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import 'controller/add_group_members_controller.dart';

class AddGroupMembersView extends GetView<AddGroupMembersController> {
  const AddGroupMembersView({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    // Listen for scroll to load more users
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 50 &&
          !controller.isLoadingMore.value &&
          !controller.isLoading.value &&
          !controller.isSearching.value) {
        controller.fetchMoreUsers();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 1,
        title: Obx(
          () => controller.isSearching.value
              ? _buildSearchField()
              : const Text(
                  'Add Members',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: controller.toggleSearch,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmer();
        }

        return Column(
          children: [
            // Selected users section
            Obx(() => controller.selectedUsers.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: Colors.grey[50],
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected contacts: ${controller.selectedUsers.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: controller.selectedUsers.map((user) {
                              return Container(
                                margin: const EdgeInsets.only(right: 16),
                                width: 70,
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor:
                                              accentColor.withOpacity(0.1),
                                          backgroundImage: user.image.isNotEmpty
                                              ? NetworkImage(user.image)
                                              : null,
                                          child: user.image.isEmpty
                                              ? Text(
                                                  user.name.isNotEmpty
                                                      ? user.name[0]
                                                          .toUpperCase()
                                                      : '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: accentColor,
                                                    fontSize: 18,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: GestureDetector(
                                            onTap: () => controller
                                                .toggleSelection(user),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox()),

            // Divider
            Obx(() => controller.selectedUsers.isNotEmpty
                ? Divider(height: 1, color: Colors.grey[300])
                : const SizedBox()),

            // All users list
            Expanded(
              child: Obx(() {
                final list = controller.isSearching.value
                    ? controller.filteredList
                    : controller.allUsers;

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.isSearching.value
                              ? 'No results found'
                              : 'No users available to add',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: scrollController,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 72,
                    color: Colors.grey[200],
                  ),
                  itemCount: list.length +
                      (controller.isLoadingMore.value &&
                              !controller.isSearching.value
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (controller.isLoadingMore.value &&
                        index == list.length &&
                        !controller.isSearching.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        ),
                      );
                    }

                    final user = list[index];
                    final isCurrentMember =
                        controller.currentMembers.contains(user.id);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: accentColor.withOpacity(0.1),
                        backgroundImage: user.image.isNotEmpty
                            ? NetworkImage(user.image)
                            : null,
                        child: user.image.isEmpty
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: isCurrentMember ? Colors.grey : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        user.about,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              isCurrentMember ? Colors.grey : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      trailing: Obx(() => Checkbox(
                        value: controller.selectionState[user.id] ?? false,
                        onChanged: isCurrentMember
                            ? null
                            : (_) => controller.toggleSelection(user),
                        activeColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                      onTap: isCurrentMember
                          ? null
                          : () => controller.toggleSelection(user),
                    );
                  },
                );
              }),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(() => controller.selectedUsers.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: lightGreen,
              onPressed: controller.addMembers,
              child: const Icon(Icons.check, color: Colors.white),
            )
          : const SizedBox()),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search...',
        hintStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, color: Colors.white70),
          onPressed: () {
            controller.filterUsers('');
            controller.toggleSearch();
          },
        ),
      ),
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      autofocus: true,
      onChanged: controller.filterUsers,
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
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 250,
                      height: 12,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
