import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../utils/app_colors.dart';
import '../widgets/profile_image.dart';
import 'controller/view_profile_controller.dart';

class ViewProfileView extends GetView<ViewProfileController> {
  const ViewProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.user.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: primaryColor,
                width: double.infinity,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Hero(
                      tag: 'user_avatar_${controller.user.value?.id}',
                      child: ProfileImage(
                        size: 120,
                        url: controller.user.value?.image ?? '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.user.value?.name ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (controller.user.value?.email != null &&
                  controller.user.value!.email.isNotEmpty)
                _buildInfoSection(
                  context,
                  'Email',
                  controller.user.value!.email,
                  Icons.email_outlined,
                  null,
                ),
              _buildInfoSection(
                context,
                'About',
                controller.user.value?.about ?? 'Hey there! I am using MosBoss',
                Icons.info_outline,
                null,
              ),
              _buildInfoSection(
                context,
                'Shared Media',
                '${controller.totalImageCount.value} images, ${controller.totalVideoCount.value} videos, ${controller.totalDocumentCount.value} documents',
                Icons.perm_media_outlined,
                    () => Get.to(() => const SharedMediaView()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoSection(
      BuildContext context,
      String title,
      String content,
      IconData icon,
      Function()? onTap,
      ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: accentColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class SharedMediaView extends GetView<ViewProfileController> {
  const SharedMediaView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text(
            'Shared Media',
            style: TextStyle(color: Colors.white),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Images'),
              Tab(text: 'Videos'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SharedImagesView(),
            SharedVideosView(),
            SharedDocumentsView(),
          ],
        ),
      ),
    );
  }
}

class SharedImagesView extends GetView<ViewProfileController> {
  const SharedImagesView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.fetchSharedImages();
    return Obx(() {
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
    });
  }
}

class SharedVideosView extends GetView<ViewProfileController> {
  const SharedVideosView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.fetchSharedVideos();
    return Obx(() {
      if (controller.isLoadingVideos.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.sharedVideos.isEmpty) {
        return const Center(child: Text('No videos shared yet'));
      }
      return GridView.builder(
        controller: controller.videoScrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: controller.sharedVideos.length +
            (controller.isLoadingMoreVideos.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.sharedVideos.length &&
              controller.isLoadingMoreVideos.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final videoData = controller.sharedVideos[index];
          final thumbnailUrl = videoData['thumbnail'] ?? '';
          final videoUrl = videoData['video'] ?? '';
          return GestureDetector(
            onTap: () => Get.to(() => _VideoViewScreen(videoUrl: videoUrl)),
            child: thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.videocam_off),
              ),
            )
                : Container(
              color: Colors.grey[200],
              child: const Icon(Icons.videocam, size: 50),
            ),
          );
        },
      );
    });
  }
}

class SharedDocumentsView extends GetView<ViewProfileController> {
  const SharedDocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.fetchSharedDocuments();
    return Obx(() {
      if (controller.isLoadingDocuments.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.sharedDocuments.isEmpty) {
        return const Center(child: Text('No documents shared yet'));
      }
      return ListView.builder(
        controller: controller.documentScrollController,
        padding: const EdgeInsets.all(8),
        itemCount: controller.sharedDocuments.length +
            (controller.isLoadingMoreDocuments.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.sharedDocuments.length &&
              controller.isLoadingMoreDocuments.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final docData = controller.sharedDocuments[index];
          final filename = docData['filename'] ?? 'Document';
          final url = docData['url'] ?? '';
          return ListTile(
            leading: const Icon(Icons.insert_drive_file, color: Colors.grey),
            title: Text(filename),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadDocument(url, filename),
            ),
            onTap: () => _openDocument(url, filename),
          );
        },
      );
    });
  }

  Future<void> _downloadDocument(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';
      final file = File(savePath);
      if (await file.exists()) {
        Get.snackbar('Info', 'Document already downloaded');
        return;
      }
      final response = await http.get(Uri.parse(url));
      await file.writeAsBytes(response.bodyBytes);
      Get.snackbar('Success', 'Document downloaded to $savePath');
    } catch (e) {
      log('Error downloading document: $e');
      Get.snackbar('Error', 'Failed to download document');
    }
  }

  Future<void> _openDocument(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';
      final file = File(savePath);
      if (await file.exists()) {
        final result = await OpenFile.open(savePath);
        if (result.type != ResultType.done) {
          Get.snackbar('Info', 'No app found to open this file');
        }
      } else {
        Get.snackbar('Info', 'Please download the document first');
      }
    } catch (e) {
      log('Error opening document: $e');
      Get.snackbar('Error', 'Failed to open document');
    }
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

class _VideoViewScreen extends StatefulWidget {
  final String videoUrl;

  const _VideoViewScreen({required this.videoUrl});

  @override
  _VideoViewScreenState createState() => _VideoViewScreenState();
}

class _VideoViewScreenState extends State<_VideoViewScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.videoUrl.split(',')[0];
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      }).catchError((e) {
        log('Error initializing video player: $e');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                child: _controller.value.isPlaying
                    ? const SizedBox.shrink()
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}