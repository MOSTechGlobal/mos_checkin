import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerFormView extends StatelessWidget {
  const ShimmerFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, // Light grey
      highlightColor: Colors.grey[100]!, // Almost white
      child: Column(
        children: [
          // Shimmer for CommonAppBar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 35.h),
                Row(
                  children: [
                    // Mimic back arrow button
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    // Mimic center section: optional icon and title placeholder
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon placeholder
                        Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Title placeholder
                        Container(
                          width: 100.w,
                          height: 20.h,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Shimmer for CustomDateFilterBar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              height: 36.h,
              decoration: BoxDecoration(
                color: colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Shimmer for List of Forms
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shimmer for Date Section Header
                    Container(
                      width: double.infinity,
                      padding:
                      EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
                      // margin:
                      // EdgeInsets.symmetric(horizontal:.h),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Container(
                        height: 14.h,
                        color: Colors.grey,
                      ),
                    ),
                    // Shimmer for Form Card
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 200.w,
                              height: 16.h,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Container(
                                  width: 80.w,
                                  height: 12.h,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  width: 100.w,
                                  height: 12.h,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Container(
                                  width: 60.w,
                                  height: 12.h,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  width: 80.w,
                                  height: 12.h,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
