import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? iconPath;
  final ColorScheme colorScheme;

  const CommonAppBar({
    super.key,
    required this.title,
    this.iconPath,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          SizedBox(height: 35.h),
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/icons/back_arrow.png",
                      width: 10.w,
                      height: 10.h,

                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconPath != null) ...[
                    Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          iconPath!,
                          color: colorScheme.onPrimary,
                          width: 12.w,
                          height: 12.w,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(70.h); // Customize height as needed
}
