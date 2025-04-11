import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class MakeShiftRequestShimmer extends StatelessWidget {
  const MakeShiftRequestShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: colorScheme.outlineVariant,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Shimmer.fromColors(
            baseColor: colorScheme.outlineVariant.withOpacity(0.2),
            highlightColor: colorScheme.outlineVariant.withOpacity(0.4),
            period: const Duration(milliseconds: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Add Details" Title
                _buildTitlePlaceholder(),
                SizedBox(height: 10.h),

                // Basic Details Section
                _buildTextFieldPlaceholder(), // Name
                SizedBox(height: 10.h),
                _buildDateTimeSectionPlaceholder(), // Start Date + Time
                SizedBox(height: 10.h),
                _buildDateTimeSectionPlaceholder(), // End Date + Time
                SizedBox(height: 10.h),

                // Service Picker Section
                _buildServicePickerPlaceholder(),
                SizedBox(height: 10.h),

                // Recurring Shift Section
                _buildRecurringShiftPlaceholder(),
                SizedBox(height: 20.h),

                // Save Button
                _buildButtonPlaceholder(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Title placeholder ("Add Details")
  Widget _buildTitlePlaceholder() {
    return Container(
      width: 120.w,
      height: 18.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  // Text field placeholder (for name)
  Widget _buildTextFieldPlaceholder() {
    return Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  // Combined Date + Time section placeholder
  Widget _buildDateTimeSectionPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 180.w,
          height: 14.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ],
    );
  }

  // Service Picker placeholder
  Widget _buildServicePickerPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100.w,
          height: 14.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Positioned(
                right: 10.w,
                child: Container(
                  width: 16.w,
                  height: 16.h,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Recurring Shift placeholder
  Widget _buildRecurringShiftPlaceholder() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 40.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Positioned(
                right: 10.w,
                child: Container(
                  width: 20.w,
                  height: 20.h,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 80.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    width: 60.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    width: 80.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Button placeholder
  Widget _buildButtonPlaceholder() {
    return Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }
}