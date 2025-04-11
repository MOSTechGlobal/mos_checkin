import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonErrorField extends StatelessWidget {
  final String? image; // Nullable image path (e.g., asset path or network URL)
  final String? message; // Nullable main error message
  final String? customMessage; // Nullable additional custom message

  const CommonErrorField({
    super.key,
    this.image,
    this.message,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine if only message is present
    final bool onlyMessage =
        image == null && customMessage == null && message != null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Center( // Wrap Column in Center for horizontal centering
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: onlyMessage
                ? MainAxisAlignment.center
                : MainAxisAlignment.start, // Vertical alignment
            crossAxisAlignment: CrossAxisAlignment.center, // Center children horizontally
            children: [
              // Image section (optional)
              if (image != null)
                Image.asset(
                  image!,
                  height: 200.h,
                  width: 200.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.error_outline,
                    size: 100.sp,
                    color: colorScheme.error.withOpacity(0.7),
                  ),
                ),

              // Minimalist container for messages
              Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Ensure inner column is centered
                children: [
                  // Error message (if provided)
                  if (message != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500, // Slightly lighter weight
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Divider between error and custom message (if both exist)
                  if (message != null && customMessage != null)
                    Divider(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      thickness: 1.h,
                      indent: 40.w,
                      endIndent: 40.w,
                    ),

                  // Custom message (if provided) with enhanced styling
                  if (customMessage != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        customMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.55),
                          fontSize: 14.sp,
                          letterSpacing: 0.4,
                          height: 1.4,
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}