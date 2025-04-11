import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWeather extends StatelessWidget {
  const ShimmerWeather({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 80.w,
                height: 16.h,
                color: baseColor,
              ),
              Container(
                width: 20.w,
                height: 20.h,
                color: baseColor,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50.w,
                height: 50.h,
                color: baseColor,
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60.w,
                        height: 24.h,
                        color: baseColor,
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        width: 20.w,
                        height: 16.h,
                        color: baseColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    width: 100.w,
                    height: 14.h,
                    color: baseColor,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 80.w,
                height: 12.h,
                color: baseColor,
              ),
              Container(
                width: 80.w,
                height: 12.h,
                color: baseColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}