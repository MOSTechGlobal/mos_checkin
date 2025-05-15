import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../utils/apis.dart';
import '../utils/app_colors.dart';
import '../widgets/profile_image.dart';
import 'controller/group_profile_controller.dart';

class GroupProfileView extends GetView<GroupProfileController> {
  const GroupProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Group Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value || controller.membersLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header
              Container(
                color: primaryColor,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: accentColor,
                      radius: 60,
                      child: Text(
                        controller.groupName.value.isNotEmpty
                            ? controller.groupName.value[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.groupName.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${controller.members.length} members',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Members section
              _buildMembersSection(context),

              // Shared Images section
              _buildInfoSection(
                context,
                'Shared Images',
                '${controller.totalImageCount.value} images',
                Icons.image_outlined,
                    () => Get.to(() => const SharedGroupImagesView()),
              ),

              // Admin actions
              if (controller.adminId.value == APIs.user.uid)
                _buildAdminActions(context),

              // Leave group
              _buildInfoSection(
                context,
                'Leave Group',
                'Exit this group',
                Icons.exit_to_app,
                    () => _showLeaveGroupDialog(context),
                color: Colors.red,
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMembersSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Members (${controller.members.length})',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.members.length,
            itemBuilder: (context, index) {
              final member = controller.members.values.elementAt(index);
              return ListTile(
                leading: ProfileImage(
                  size: 40,
                  url: member.image,
                ),
                title: Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  member.id == controller.adminId.value ? 'Admin' : 'Member',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                trailing: controller.adminId.value == APIs.user.uid &&
                    member.id != APIs.user.uid
                    ? IconButton(
                  icon:
                  const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _showRemoveMemberDialog(
                    context,
                    member.id,
                    member.name,
                  ),
                )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child: Column(
        children: [
          _buildInfoSection(
            context,
            'Rename Group',
            'Change group name',
            Icons.edit,
                () => _showRenameGroupDialog(context),
          ),
          _buildInfoSection(
            context,
            'Add Members',
            'Invite new members',
            Icons.add_circle_outline,
                () => Get.toNamed(AppRoutes.addGroupMembersView,
                arguments: {'groupId': controller.groupId.value}),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context,
      String title,
      String content,
      IconData icon,
      Function()? onTap, {
        Color? color,
      }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: color ?? accentColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: color ?? Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: onTap != null
            ? Icon(Icons.arrow_forward_ios, size: 16, color: color)
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showRenameGroupDialog(BuildContext context) {
    final textController =
    TextEditingController(text: controller.groupName.value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Group'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter new group name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                await controller.renameGroup(newName);
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(
      BuildContext context, String memberId, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $memberName from the group?'),
        actions: [
          TextButton(
            onPressed: () {
              log('Remove member dialog cancelled');
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              log('Remove member confirmed for memberId: $memberId');
              Navigator.pop(context); // Close the confirmation dialog
              log('Navigation stack before dialog: ${Get.nestedKey(Get.currentRoute)}');
              log('Showing loading dialog');
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
                barrierColor: Colors.black54,
                name: 'remove_member_loading',
              );
              log('Navigation stack after dialog: ${Get.nestedKey(Get.currentRoute)}');
              try {
                log('Calling controller.removeMember');
                await controller.removeMember(memberId);
                log('removeMember completed successfully');
                // Delay snackbar to avoid interference
                Future.delayed(const Duration(milliseconds: 100), () {
                  Get.snackbar('Success', 'Member removed');
                });
              } catch (e) {
                log('Error in removeMember: $e');
                Future.delayed(const Duration(milliseconds: 100), () {
                  Get.snackbar('Error', 'Failed to remove member: $e');
                });
              } finally {
                log('Entering finally block, isDialogOpen: ${Get.isDialogOpen}, currentRoute: ${Get.currentRoute}');
                if (Get.isDialogOpen ?? false) {
                  log('Closing loading dialog');
                  Get.back(); // Try closing the dialog
                  // Double-check if dialog is still open
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (Get.isDialogOpen ?? false) {
                    log('Dialog still open, forcing close');
                    Get.back(); // Try again
                  }
                } else {
                  log('No dialog open to close');
                }
                log('Navigation stack after closing dialog: ${Get.nestedKey(Get.currentRoute)}');
              }
            },
            child: const Text(
              'REMOVE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () {
              log('Leave group dialog cancelled');
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              log('Leave group confirmed');
              // Close the confirmation dialog
              Navigator.pop(context);
              // Show loading dialog
              log('Showing loading dialog for leave group');
              Get.dialog(
                const Center(
                  child: CircularProgressIndicator(),
                ),
                barrierDismissible: false,
                barrierColor: Colors.black54,
                name: 'leave_group_loading',
              );
              try {
                log('Calling controller.leaveGroup');
                await controller.leaveGroup();
                log('leaveGroup completed successfully');
              } catch (e) {
                log('Error in leaveGroup: $e');
                rethrow;
              } finally {
                log('Entering finally block for leave group, isDialogOpen: ${Get.isDialogOpen}');
                if (Get.isDialogOpen ?? false) {
                  log('Closing loading dialog for leave group');
                  Get.back();
                } else {
                  log('No dialog open to close for leave group');
                }
              }
            },
            child: const Text(
              'LEAVE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class SharedGroupImagesView extends GetView<GroupProfileController> {
  const SharedGroupImagesView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.fetchSharedImages();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Shared Images',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingImages.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.sharedImages.isEmpty) {
          return const Center(child: Text('No images shared yet'));
        }

        return GridView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: controller.sharedImages.length +
              (controller.isLoadingMoreImages.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.sharedImages.length &&
                controller.isLoadingMoreImages.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final imageUrl = controller.sharedImages[index];
            return GestureDetector(
              onTap: () => Get.to(() => _ImageViewScreen(
                imageUrl: imageUrl,
                imageUrls: controller.sharedImages,
                currentIndex: index,
              )),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _ImageViewScreen extends StatefulWidget {
  final String imageUrl;
  final List<String>? imageUrls;
  final int? currentIndex;

  const _ImageViewScreen({
    required this.imageUrl,
    this.imageUrls,
    this.currentIndex,
  });

  @override
  _ImageViewScreenState createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<_ImageViewScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls == null || widget.imageUrls!.length <= 1) {
      return _buildSingleImageView(context);
    }
    return _buildGalleryView(context);
  }

  Widget _buildSingleImageView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _isFullScreen
          ? null
          : AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isFullScreen = !_isFullScreen;
          });
        },
        child: Center(
          child: Hero(
            tag: 'image_${widget.imageUrl}',
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.image_not_supported,
                  color: Colors.white,
                  size: 50,
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _isFullScreen
          ? null
          : AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/${widget.imageUrls!.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isFullScreen = !_isFullScreen;
          });
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls!.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Center(
              child: Hero(
                tag: 'image_${widget.imageUrls![index]}',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls![index],
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 50,
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}