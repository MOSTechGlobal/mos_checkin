import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../routes/app_routes.dart';
import 'controller/users_screen_controller.dart';

class UsersScreenView extends GetView<UsersScreenController> {
  const UsersScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Listen for scroll to bottom to load more users
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
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        title: Obx(
          () => controller.isSearching.value
              ? _buildSearchField()
              : const Text(
                  'Select Contact',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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

        final list = controller.isSearching.value
            ? controller.filteredList
            : controller.allUsers;

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.isSearching.value
                      ? 'No results found'
                      : 'No contacts available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (!controller.isSearching.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Contacts will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // New contact section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              width: double.infinity,
              child: Text(
                'Users on ${controller.companyName.value}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            // Contacts list
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: list.length +
                    (controller.isLoadingMore.value &&
                            !controller.isSearching.value
                        ? 1
                        : 0),
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 72,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  // Loading indicator at the bottom
                  if (controller.isLoadingMore.value &&
                      index == list.length &&
                      !controller.isSearching.value) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    );
                  }
                  final user = list[index];
                  return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        backgroundImage: user.image.isNotEmpty
                            ? NetworkImage(user.image)
                            : null,
                        child: user.image.isEmpty
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        user.about,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.chatScreenView, arguments: user);
                      });
                },
              ),
            ),
          ],
        );
      }),
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
