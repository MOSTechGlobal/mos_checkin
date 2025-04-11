import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class ShiftRequestShimmer extends StatelessWidget {
  const ShiftRequestShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding:
                    EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
                    margin: EdgeInsets.symmetric(horizontal: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[400]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 150.w,
                        height: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Shift Cards Placeholder
                  ListView.builder(
                    shrinkWrap: true,
                    padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 2,
                    // 2 shift cards per date section
                    itemBuilder: (context, shiftIndex) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 120.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 8.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40.w,
                                    height: 40.h,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 100.w,
                                          height: 12.sp,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 8.h),
                                        Container(
                                          width: 80.w,
                                          height: 10.sp,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
