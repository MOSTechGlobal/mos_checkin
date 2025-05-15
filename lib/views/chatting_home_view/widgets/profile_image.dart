import 'package:flutter/material.dart';

class ProfileImage extends StatelessWidget {
  final String url;
  final double size;

  const ProfileImage({super.key, required this.size, required this.url});

  @override
  Widget build(BuildContext context) {
    // Check if the URL is empty or invalid
    if (url.isEmpty || url == 'file:///') {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return CircleAvatar(
      radius: size * 0.5,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }
}