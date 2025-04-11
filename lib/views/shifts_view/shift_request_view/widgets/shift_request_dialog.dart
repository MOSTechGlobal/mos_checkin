import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ShiftRequestDialog extends StatelessWidget {
  final String service;
  final String shiftStart;
  final String shiftEnd;
  final String shiftStatus;
  final String recurrence;
  final String formattedStartTime;
  final String formattedEndTime;
  final String duration;

  ShiftRequestDialog({
    required this.service,
    required this.shiftStart,
    required this.shiftEnd,
    required this.shiftStatus,
    required this.recurrence,
    required this.formattedStartTime,
    required this.formattedEndTime,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Incident Report',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 25.w,
                        height: 25.h,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: colorScheme.error,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: colorScheme.error,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(context, 'Shift Start Date', shiftStart),
                      _buildInfoRow(context, 'Shift End Date', shiftEnd),
                      _buildInfoRow(context, 'Shift Status', shiftStatus == 'P' ? 'Pending' : shiftStatus == 'A' ? 'Approved' : shiftStatus == 'R' ? 'Rejected' : 'Cancelled'),
                      _buildInfoRow(context, 'Shift Recurrence', recurrence),
                      _buildInfoRow(context, 'Shift Start Time', formattedStartTime),
                      _buildInfoRow(context, 'Shift End Time', formattedEndTime),
                      _buildInfoRow(context, 'Shift Duration', duration),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              width: 140.w,
              child: Text(
                value,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        Divider(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
        ),
      ],
    );
  }
}
