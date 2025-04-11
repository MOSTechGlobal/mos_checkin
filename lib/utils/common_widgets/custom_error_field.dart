import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomErrorField extends StatelessWidget {
  final String message;

  const CustomErrorField({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: 12.h,
            horizontal: 16.w,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFCF5300).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.outline,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: null, // Allow multiple lines
            overflow: TextOverflow.visible, // Ensure full visibility
          ),
        ),
      ),
    );
  }
}
