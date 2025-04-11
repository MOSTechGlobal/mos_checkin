import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color textColor;
  final double width;
  final double borderRadius;
  final double fontSize;
  final double verticalPadding;
  final bool isSaving;
  final bool isBorder;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor, // Make it nullable
    this.textColor = Colors.white,
    this.width = double.infinity,
    this.borderRadius = 8.0,
    this.fontSize = 14.0,
    this.verticalPadding = 10.0,
    this.isSaving = false,
    this.isBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding.h),
        width: width.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onPressed == null
              ? Colors.grey
              : backgroundColor ?? Theme.of(Get.context!).colorScheme.primary,
          borderRadius: BorderRadius.circular(borderRadius.r),
          boxShadow: onPressed == null || isSaving
              ? []
              : [
            BoxShadow(
              color: backgroundColor != null ? backgroundColor!.withOpacity(0.3) :
              Theme.of(Get.context!).colorScheme.primary.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: isSaving
            ? SizedBox(
          width: 20.w,
          height: 20.h,
          child: CircularProgressIndicator(
            color: Theme.of(Get.context!).colorScheme.onPrimary,
            strokeWidth: 2,
          ),
        )
            : Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: fontSize.sp,
          ),
        ),
      ),
    );
  }
}
