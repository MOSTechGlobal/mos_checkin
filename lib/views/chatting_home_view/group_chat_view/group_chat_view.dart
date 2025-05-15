import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../routes/app_routes.dart';
import '../utils/my_date_util.dart';
import 'controller/group_chat_controller.dart';
import '../models/message.dart';
import '../widgets/message_card.dart';

class GroupChatView extends GetView<GroupChatController> {
  const GroupChatView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(GroupChatController(), tag: controller.groupId);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: true,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: _appBar(context, colorScheme),
          ),
          backgroundColor: const Color(0xFFECE5DD),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value ||
                            controller.membersLoading.value) {
                          return _buildShimmer();
                        }
                        if (controller.messages.isEmpty) {
                          return _buildEmptyState(colorScheme);
                        }

                        // Create a list to hold messages and date labels
                        List<dynamic> items = [];
                        String? currentDate;

                        // Iterate through messages to group by date
                        for (var msg in controller.messages) {
                          String messageDate =
                              MyDateUtil.getMessageDateLabel(context, msg.sent);
                          if (messageDate != currentDate) {
                            if (currentDate != null) {
                              items.add(currentDate);
                            }
                            currentDate = messageDate;
                          }
                          items.add(msg);
                        }
                        if (currentDate != null) {
                          items.add(currentDate);
                        }

                        // Add loading indicator if loading more messages
                        if (controller.isLoadingMore.value) {
                          items.add('loading');
                        }

                        return ListView.builder(
                          controller: controller.scrollController,
                          reverse: true,
                          key: const ValueKey('group_chat_list'),
                          itemCount: items.length,
                          padding: EdgeInsets.only(
                              top: Get.mediaQuery.size.height * .01),
                          physics: const ClampingScrollPhysics(),
                          clipBehavior: Clip.hardEdge,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            if (item == 'loading') {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            } else if (item is String) {
                              return _buildDateLabel(item);
                            } else {
                              return MessageCard(
                                key: ValueKey(item.sent),
                                message: item,
                                isGroupMessage: true,
                                sender: controller.members[item.fromId],
                                controller: controller,
                              );
                            }
                          },
                        );
                      }),
                    ),
                    Obx(() => AnimatedOpacity(
                          opacity: controller.typingText.isNotEmpty ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: controller.typingText.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, bottom: 8, top: 4),
                                  child: Text(
                                    controller.typingText,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        )),
                    Obx(() => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: controller.isUploading.value ? 50 : 0,
                          child: controller.isUploading.value
                              ? Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 15),
                                      Text(
                                        'Uploading...',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(),
                        )),
                    _chatInput(context),
                    Obx(() => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height:
                              controller.showEmoji.value ? Get.height * .35 : 0,
                          child: EmojiPicker(
                            textEditingController: controller.textController,
                          ),
                        )),
                  ],
                ),
                Obx(() {
                  return controller.hasNewMessage.value
                      ? Positioned(
                          bottom: 80,
                          right: 16,
                          child: FloatingActionButton(
                            shape: const CircleBorder(),
                            onPressed: controller.scrollToBottom,
                            backgroundColor: colorScheme.primary,
                            mini: true,
                            child: const Icon(Icons.arrow_downward,
                                color: Colors.white),
                          ),
                        )
                      : const SizedBox.shrink();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateLabel(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            date,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: colorScheme.primary,
      elevation: 0,
      title: InkWell(
        onTap: () => _showGroupInfo(context),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.onPrimary,
              radius: 20,
              backgroundImage: controller.groupImage.isNotEmpty
                  ? NetworkImage(controller.groupImage.value)
                  : null,
              child: controller.groupImage.isEmpty
                  ? Text(
                      controller.groupName.isNotEmpty
                          ? controller.groupName.value
                              .substring(0, 1)
                              .toUpperCase()
                          : 'G',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.groupName.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(() => Text(
                      '${controller.members.length} members',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showGroupInfo(BuildContext context) {
    Get.toNamed(AppRoutes.groupProfileView, arguments: {
      'groupId': controller.groupId,
      'groupName': controller.groupName
    });
  }

  Widget _chatInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Obx(() {
        if (controller.hasRecordedAudio.value) {
          return RecordedAudioPlayer(controller: controller);
        } else {
          return Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    controller: controller.textController,
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showMediaOptions(context),
                icon: Icon(Icons.attach_file, color: Colors.grey[600]),
              ),
              Obx(() {
                if (controller.isTextEmpty.value) {
                  return AudioRecordButton(controller: controller);
                } else {
                  return IconButton(
                    onPressed: controller.sendMessage,
                    icon: Icon(Icons.send, color: Colors.grey[600]),
                  );
                }
              }),
            ],
          );
        }
      }),
    );
  }

  void _showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 32,
                runSpacing: 20,
                children: [
                  _buildOption(
                    icon: Icons.insert_drive_file,
                    label: 'Document',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      controller.pickDocuments();
                    },
                  ),
                  _buildOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.pink,
                    onTap: () {
                      Navigator.pop(context);
                      controller.pickCameraImage();
                    },
                  ),
                  _buildOption(
                    icon: Icons.image,
                    label: 'Image',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      controller.pickImages();
                    },
                  ),
                  _buildOption(
                    icon: Icons.slow_motion_video,
                    label: 'Video',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      controller.pickVideo();
                    },
                  ),
                  _buildOption(
                    icon: Icons.headset,
                    label: 'Audio',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      controller.pickAudio();
                    },
                  ),
                  _buildOption(
                    icon: Icons.person,
                    label: 'Contact',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      controller.pickContact();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (_, __) => Align(
          alignment: __.isEven ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: BoxConstraints(maxWidth: Get.width * 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                Container(
                  width: Get.width * 0.4,
                  height: 12,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group,
              size: 60,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Messages Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Start a conversation in this group',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openImage(BuildContext context, Message message) {
    if (message.type == Type.image) {
      Get.to(() => _ImageViewScreen(imageUrl: message.msg));
    }
  }
}

class _ImageViewScreen extends StatelessWidget {
  final String imageUrl;

  const _ImageViewScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
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
          ),
        ),
      ),
    );
  }
}

class RecordedAudioPlayer extends StatelessWidget {
  final GroupChatController controller;

  const RecordedAudioPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          children: [
            IconButton(
              icon: Icon(
                controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                color: Colors.grey[600],
              ),
              onPressed: () {
                if (controller.isPlaying.value) {
                  controller.stopRecordedAudio();
                } else {
                  controller.playRecordedAudio();
                }
              },
            ),
            Expanded(
              child: Slider(
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.grey[300],
                value: controller.audioPosition.value.inSeconds.toDouble(),
                min: 0,
                max: controller.audioDuration.value.inSeconds.toDouble() > 0
                    ? controller.audioDuration.value.inSeconds.toDouble()
                    : 1.0,
                onChanged: (value) {
                  controller.audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${controller.audioPosition.value.inMinutes}:${controller.audioPosition.value.inSeconds.remainder(60).toString().padLeft(2, '0')} / ${controller.audioDuration.value.inMinutes}:${controller.audioDuration.value.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.grey),
              onPressed: controller.sendRecordedAudio,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: controller.discardRecordedAudio,
            ),
          ],
        ));
  }
}

class AudioRecordButton extends StatefulWidget {
  final GroupChatController controller;

  const AudioRecordButton({
    super.key,
    required this.controller,
  });

  @override
  State<AudioRecordButton> createState() => _AudioRecordButtonState();
}

class _AudioRecordButtonState extends State<AudioRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _micSizeAnimation;
  double dragOffset = 0;
  bool isCancelling = false;
  final double cancelThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _micSizeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
          onLongPressStart: (_) {
            widget.controller.startRecording();
          },
          onLongPressEnd: (_) {
            if (!isCancelling) {
              widget.controller.stopRecording();
            }
            setState(() {
              dragOffset = 0;
              isCancelling = false;
            });
          },
          onLongPressMoveUpdate: (details) {
            setState(() {
              if (details.offsetFromOrigin.dx < 0) {
                dragOffset = details.offsetFromOrigin.dx;
              } else {
                dragOffset = 0;
              }
              if (dragOffset <= -cancelThreshold && !isCancelling) {
                isCancelling = true;
                widget.controller.cancelRecording();
              }
            });
          },
          child: widget.controller.isRecording.value
              ? _buildRecordingState(context)
              : _buildDefaultState(),
        ));
  }

  Widget _buildDefaultState() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: const Icon(
        Icons.mic,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildRecordingState(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            width: (MediaQuery.of(context).size.width * 0.7) *
                (dragOffset / -cancelThreshold).clamp(0.0, 1.0),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          Positioned(
            left: 16.0,
            child: Opacity(
              opacity: (dragOffset / -cancelThreshold * 2).clamp(0.0, 1.0),
              child: const Text(
                "< Slide to cancel",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16.0,
            child: Opacity(
              opacity:
                  (1 - (dragOffset / -cancelThreshold * 2)).clamp(0.0, 1.0),
              child: Obx(() => Text(
                    '${widget.controller.recordingDuration.value.inMinutes.toString().padLeft(2, '0')}:${(widget.controller.recordingDuration.value.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
            ),
          ),
          Positioned(
            right: 10,
            child: ScaleTransition(
              scale: _micSizeAnimation,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
