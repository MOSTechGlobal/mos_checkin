import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RosterShimmer extends StatelessWidget {
  final ColorScheme colorScheme;

  const RosterShimmer({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          SizedBox(height: 10.h),
          _buildShimmerBox(width: double.infinity, height: 40.h),
          SizedBox(height: 10.h),
          _buildShimmerList(),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Expanded(
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.symmetric(vertical: 5.h),
          child: _buildShimmerBox(width: double.infinity, height: 80.h),
        ),
      ),
    );
  }
}