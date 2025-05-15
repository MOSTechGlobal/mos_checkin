import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../chat_screen_view/controller/chat_screen_controller.dart';
import '../group_chat_view/controller/group_chat_controller.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../utils/apis.dart';
import '../utils/live_location_service.dart';
import '../utils/my_date_util.dart';
import '../utils/app_colors.dart';

class MessageCard extends StatelessWidget {
  final Message message;
  final ChatUser? chatUser;
  final bool isGroupMessage;
  final ChatUser? sender;
  final dynamic controller;
  final VoidCallback? onImageTap;

  const MessageCard({
    super.key,
    required this.message,
    this.chatUser,
    this.isGroupMessage = false,
    this.sender,
    required this.controller,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = APIs.user.uid == message.fromId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && isGroupMessage && sender != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: accentColor,
                backgroundImage: sender!.image.isNotEmpty
                    ? NetworkImage(sender!.image)
                    : null,
                child: sender!.image.isEmpty
                    ? Text(
                        sender!.name.isNotEmpty
                            ? sender!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
            ),
          Flexible(
            child: InkWell(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                padding: message.type == Type.image ||
                        message.type == Type.video
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isMe ? chatBubbleColor : receiverBubbleColor,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight: isMe
                        ? const Radius.circular(0)
                        : const Radius.circular(16),
                    bottomLeft: !isMe
                        ? const Radius.circular(0)
                        : const Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isGroupMessage &&
                        !isMe &&
                        sender != null &&
                        message.type == Type.text)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          sender!.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    if (message.type == Type.text)
                      _buildTextMessage(context, isMe)
                    else if (message.type == Type.image)
                      _buildImageMessage(context, isMe)
                    else if (message.type == Type.video)
                      _buildVideoMessage(context, isMe)
                    else if (message.type == Type.audio)
                      _buildAudioMessage(context, isMe)
                    else if (message.type == Type.document)
                      _buildDocumentMessage(context, isMe)
                    else if (message.type == Type.location)
                      _buildLocationMessage(context, isMe),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context, bool isMe) {
    if (message.msg.startsWith('contact:')) {
      final parts = message.msg.substring(8).split('|');
      if (parts.length == 2) {
        final name = parts[0];
        final phone = parts[1];
        return _buildContactMessage(context, isMe, name, phone);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.msg,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              MyDateUtil.getFormattedTime(context: context, time: message.sent),
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(width: 4),
            _buildReadStatus(),
            if (isMe && isGroupMessage) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showReaders(context),
                child: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.grey,
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildContactMessage(
      BuildContext context, bool isMe, String name, String phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isGroupMessage && !isMe && sender != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              sender!.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _launchDialer(phone),
                      child: Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              MyDateUtil.getFormattedTime(context: context, time: message.sent),
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(width: 4),
            _buildReadStatus(),
            if (isMe && isGroupMessage) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showReaders(context),
                child: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.grey,
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _launchDialer(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar('Error', 'Could not launch dialer');
    }
  }

  Widget _buildImageMessage(BuildContext context, bool isMe) {
    final imageUrls = message.msg
        .split(',')
        .where((url) => url.isNotEmpty && url != 'uploading')
        .toList();
    final imageCount = imageUrls.length;

    if (imageCount == 0) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isGroupMessage && !isMe && sender != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 2),
            child: Text(
              sender!.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        GestureDetector(
          onTap: onImageTap ??
              () {
                if (imageCount == 1) {
                  Get.to(() => _ImageViewScreen(imageUrl: imageUrls[0]));
                } else {
                  Get.to(() => _ImageGridViewScreen(imageUrls: imageUrls));
                }
              },
          child: _buildImageGrid(imageUrls, imageCount),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 4, top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                MyDateUtil.getFormattedTime(
                    context: context, time: message.sent),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(width: 4),
              _buildReadStatus(),
              if (isMe && isGroupMessage) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showReaders(context),
                  child: const Icon(
                    Icons.remove_red_eye,
                    color: Colors.grey,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoMessage(BuildContext context, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isGroupMessage && !isMe && sender != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 2),
            child: Text(
              sender!.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        GestureDetector(
          onTap: () => Get.to(() => _VideoViewScreen(videoUrl: message.msg)),
          child: _buildVideoThumbnail(message.msg),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 4, top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                MyDateUtil.getFormattedTime(
                    context: context, time: message.sent),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(width: 4),
              _buildReadStatus(),
              if (isMe && isGroupMessage) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showReaders(context),
                  child: const Icon(
                    Icons.remove_red_eye,
                    color: Colors.grey,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentMessage(BuildContext context, bool isMe) {
    final parts = message.msg.split('|');
    final url = parts[0];
    final fileName = parts.length > 1 ? parts[1] : 'Document';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isGroupMessage && !isMe && sender != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 2),
            child: Text(
              sender!.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.grey, size: 40),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.grey),
              onPressed: () => _downloadDocument(url, fileName),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.grey),
              onPressed: () async {
                final dir = await getApplicationDocumentsDirectory();
                final savePath = '${dir.path}/$fileName';
                final file = File(savePath);
                if (await file.exists()) {
                  final result = await OpenFile.open(savePath);
                  if (result.type != ResultType.done) {
                    Get.snackbar('Info', 'No app found to open this file');
                  }
                } else {
                  Get.snackbar('Info', 'File not downloaded yet');
                }
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 4, top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                MyDateUtil.getFormattedTime(
                    context: context, time: message.sent),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(width: 4),
              _buildReadStatus(),
              if (isMe && isGroupMessage) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showReaders(context),
                  child: const Icon(
                    Icons.remove_red_eye,
                    color: Colors.grey,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioMessage(BuildContext context, bool isMe) {
    final parts = message.msg.split('|');
    final url = parts[0];
    final fileName = parts.length > 1 ? parts[1] : 'Audio';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isGroupMessage && !isMe && sender != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 2),
            child: Text(
              sender!.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        AudioMessageWidget(url: url, fileName: fileName),
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 4, top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                MyDateUtil.getFormattedTime(
                    context: context, time: message.sent),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(width: 4),
              _buildReadStatus(),
              if (isMe && isGroupMessage) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showReaders(context),
                  child: const Icon(
                    Icons.remove_red_eye,
                    color: Colors.grey,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationMessage(BuildContext context, bool isMe) {
    final parts = message.msg.split(',');
    if (parts.length != 2) return Text('Invalid location data');
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return Text('Invalid location data');

    final mapUrl =
        'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=300x150&markers=$lat,$lng&key=AIzaSyAgvAY7JozF6rd2t8kNAILY5OmUa871HxM';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openMap(lat, lng),
          child: CachedNetworkImage(
            imageUrl: mapUrl,
            height: 150,
            width: 300,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 150,
              width: 300,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 150,
              width: 300,
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.error)),
            ),
          ),
        ),
        if (message.locationType == LocationType.live && isMe)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: ElevatedButton(
              onPressed: () {
                LiveLocationService().stopSharing();
              },
              child: Text('Stop Sharing'),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 4, top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                MyDateUtil.getFormattedTime(
                    context: context, time: message.sent),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(width: 4),
              _buildReadStatus(),
            ],
          ),
        ),
      ],
    );
  }

  void _openMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar('Error', 'Could not open map');
    }
  }

  Widget _buildReadStatus() {
    final isMe = APIs.user.uid == message.fromId;
    if (!isMe) return const SizedBox.shrink();

    bool isRead;
    if (isGroupMessage) {
      final groupController = controller as GroupChatController;
      final messageTimestamp = message.sent.millisecondsSinceEpoch;
      isRead = groupController.members.keys
          .where((id) => id != APIs.user.uid)
          .every((id) {
        final lastReadTimestamp = groupController.lastRead[id] ?? '0';
        try {
          final lastReadInt = int.parse(lastReadTimestamp);
          return lastReadInt >= messageTimestamp;
        } catch (e) {
          return false;
        }
      });
    } else {
      isRead = message.read.isNotEmpty;
    }
    return Icon(
      Icons.done_all,
      color: isRead ? Colors.blue : Colors.grey,
      size: 14,
    );
  }

  Widget _buildImageGrid(List<String> imageUrls, int imageCount) {
    final maxDisplay = imageCount > 4 ? 4 : imageCount;
    const gridPadding = EdgeInsets.all(2);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageCount == 1
            ? _buildSingleImageView(imageUrls[0])
            : imageCount == 3
                ? _buildThreeImageLayout(imageUrls)
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: imageCount == 2 ? 2 : 2,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    padding: gridPadding,
                    childAspectRatio: 1,
                    children: List.generate(maxDisplay, (index) {
                      if (index == 3 && imageCount > 4) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildGridImageItem(imageUrls[index]),
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Center(
                                child: Text(
                                  '+${imageCount - 4}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return _buildGridImageItem(imageUrls[index]);
                    }),
                  ),
      ),
    );
  }

  Widget _buildThreeImageLayout(List<String> imageUrls) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildGridImageItem(imageUrls[0]),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildGridImageItem(imageUrls[1])),
                const SizedBox(height: 2),
                Expanded(child: _buildGridImageItem(imageUrls[2])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleImageView(String imageUrl) {
    return SizedBox(
      height: 200,
      width: 200,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridImageItem(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(String videoData) {
    final urls = videoData.split(',');
    final thumbnailUrl =
        urls.length > 1 ? urls[1] : urls[0].replaceAll('.mp4', '_thumb.jpg');

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 200,
          width: 200,
          child: CachedNetworkImage(
            imageUrl: thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.videocam_off,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
        Container(
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
      ],
    );
  }

  Future<void> _downloadDocument(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';
      final file = File(savePath);

      if (await file.exists()) {
        final result = await OpenFile.open(savePath);
        if (result.type != ResultType.done) {
          Get.snackbar('Info', 'No app found to open this file');
        }
        return;
      }

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final List<int> bytes = [];

      response.stream.listen(
        (List<int> chunk) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          final progress = (receivedBytes / totalBytes) * 100;
          log('Download progress: $progress%');
        },
        onDone: () async {
          await file.writeAsBytes(bytes);
          Get.back();
          Get.snackbar('Success', 'Document downloaded to $savePath');
          final result = await OpenFile.open(savePath);
          if (result.type != ResultType.done) {
            Get.snackbar('Info', 'No app found to open this file');
          }
        },
        onError: (e) {
          Get.back();
          log('Error downloading document: $e');
          Get.snackbar('Error', 'Failed to download document');
        },
      );
    } catch (e) {
      Get.back();
      log('Error downloading document: $e');
      Get.snackbar('Error', 'Failed to download document');
    }
  }

  void _showMessageOptions(BuildContext context) {
    final isMe = APIs.user.uid == message.fromId;
    if (!isMe) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            Container(
              height: 4,
              margin: EdgeInsets.symmetric(
                  vertical: 12, horizontal: Get.width * .4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            if (message.type == Type.text)
              _OptionItem(
                icon: Icons.copy_rounded,
                name: 'Copy Text',
                onTap: () {
                  Navigator.pop(context);
                  // Implement copy functionality if needed
                },
              ),
            if (message.type == Type.image || message.type == Type.video)
              _OptionItem(
                icon: Icons.download_rounded,
                name: message.type == Type.image ? 'Save Image' : 'Save Video',
                onTap: () {
                  Navigator.pop(context);
                  // Implement save functionality if needed
                },
              ),
            if (message.type == Type.document)
              _OptionItem(
                icon: Icons.download_rounded,
                name: 'Save Document',
                onTap: () {
                  Navigator.pop(context);
                  final parts = message.msg.split('|');
                  final url = parts[0];
                  final fileName = parts.length > 1 ? parts[1] : 'Document';
                  _downloadDocument(url, fileName);
                },
              ),
            if (message.type == Type.text)
              _OptionItem(
                icon: Icons.edit,
                name: 'Edit Message',
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(context);
                },
              ),
            _OptionItem(
              icon: Icons.delete_forever,
              name: 'Delete Message',
              onTap: () {
                Navigator.pop(context);
                _deleteMessage();
              },
            ),
          ],
        );
      },
    );
  }

  void _editMessage(BuildContext context) {
    final textController =
        TextEditingController(text: message.msg.replaceAll(' (edited)', ''));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Edit your message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newText = textController.text.trim();
              if (newText.isNotEmpty) {
                try {
                  if (isGroupMessage) {
                    await (controller as GroupChatController)
                        .editMessage(message, newText);
                  } else {
                    await (controller as ChatScreenController)
                        .editMessage(message, newText);
                  }
                  Navigator.pop(context);
                } catch (e) {
                  Get.snackbar('Error', 'Failed to edit message');
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage() {
    Get.snackbar('Info', 'Delete message functionality not implemented yet');
  }

  void _showReaders(BuildContext context) {
    if (!isGroupMessage) return;
    final groupController = controller as GroupChatController;
    final readers = groupController.getMessageReaders(message);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              margin: EdgeInsets.symmetric(
                  vertical: 12, horizontal: Get.width * .4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Seen by ${readers.length} member${readers.length != 1 ? 's' : ''}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (readers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'No one has seen this message yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: readers.length,
                itemBuilder: (context, index) {
                  final reader = readers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: accentColor,
                      backgroundImage: reader.image.isNotEmpty
                          ? NetworkImage(reader.image)
                          : null,
                      child: reader.image.isEmpty
                          ? Text(
                              reader.name.isNotEmpty
                                  ? reader.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(reader.name),
                    subtitle: const Text('Seen'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem({
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 26, color: Colors.black87),
            const SizedBox(width: 20),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
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

class _ImageGridViewScreen extends StatelessWidget {
  final List<String> imageUrls;

  const _ImageGridViewScreen({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${imageUrls.length} Images',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () =>
                Get.to(() => _ImageViewScreen(imageUrl: imageUrls[index])),
            child: CachedNetworkImage(
              imageUrl: imageUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          );
        },
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
            : const CircularProgressIndicator(
                color: Colors.white,
              ),
      ),
    );
  }
}

class AudioMessageWidget extends StatefulWidget {
  final String url;
  final String fileName;

  const AudioMessageWidget(
      {super.key, required this.url, required this.fileName});

  @override
  _AudioMessageWidgetState createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  late AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    try {
      await _player.play(UrlSource(widget.url));
    } catch (e) {
      log('Error playing audio: $e');
      Get.snackbar('Error', 'Failed to play audio');
    }
  }

  Future<void> _pause() async {
    try {
      await _player.pause();
    } catch (e) {
      log('Error pausing audio: $e');
      Get.snackbar('Error', 'Failed to pause audio');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                _playerState == PlayerState.playing
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.grey[600],
              ),
              onPressed: () {
                if (_playerState == PlayerState.playing) {
                  _pause();
                } else {
                  _play();
                }
              },
            ),
            Expanded(
              child: Slider(
                activeColor: accentColor,
                inactiveColor: Colors.grey[300],
                value: _position.inSeconds.toDouble(),
                min: 0,
                max: _duration.inSeconds.toDouble() > 0
                    ? _duration.inSeconds.toDouble()
                    : 1.0,
                onChanged: (value) {
                  if (mounted) {
                    _player.seek(Duration(seconds: value.toInt()));
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${_position.inMinutes}:${_position.inSeconds.remainder(60).toString().padLeft(2, '0')} / ${_duration.inMinutes}:${_duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.fileName,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.grey),
              onPressed: () => _downloadAudio(widget.url, widget.fileName),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _downloadAudio(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';
      final file = File(savePath);

      if (await file.exists()) {
        Get.snackbar('Info', 'File already downloaded');
        return;
      }

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final List<int> bytes = [];

      response.stream.listen(
        (List<int> chunk) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          final progress =
              totalBytes > 0 ? (receivedBytes / totalBytes) * 100 : 0;
          log('Download progress: $progress%');
        },
        onDone: () async {
          await file.writeAsBytes(bytes);
          Get.back();
          Get.snackbar('Success', 'Audio downloaded to $savePath');
        },
        onError: (e) {
          Get.back();
          log('Error downloading audio: $e');
          Get.snackbar('Error', 'Failed to download audio');
        },
        cancelOnError: true,
      );
    } catch (e) {
      Get.back();
      log('Error downloading audio: $e');
      Get.snackbar('Error', 'Failed to download audio');
    }
  }
}
