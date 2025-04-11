import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'common_button.dart';

class CommonDatePickerModal extends StatefulWidget {
  final DateTime initialFromDate;
  final DateTime initialToDate;
  final Function(DateTime, DateTime) onDateSelected;
  final ColorScheme colorScheme;

  const CommonDatePickerModal({
    required this.initialFromDate,
    required this.initialToDate,
    required this.onDateSelected,
    required this.colorScheme,
    super.key,
  });

  @override
  _CommonDatePickerModalState createState() => _CommonDatePickerModalState();
}

class _CommonDatePickerModalState extends State<CommonDatePickerModal> {
  late DateTime tempFrom;
  late DateTime tempTo;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    tempFrom = widget.initialFromDate;
    tempTo = widget.initialToDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12.r,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 36.w,
            height: 4.h,
            margin: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: widget.colorScheme.outlineVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: widget.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${tempFrom.day} ${_getMonthName(tempFrom.month)} ${tempFrom.year}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: widget.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 20.sp,
                  color: widget.colorScheme.primary,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'To',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: widget.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${tempTo.day} ${_getMonthName(tempTo.month)} ${tempTo.year}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: widget.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // Segmented Control for Switching Between "From" and "To"
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color:
                    widget.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: widget.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 0
                              ? widget.colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            'From',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: selectedTab == 0
                                  ? widget.colorScheme.primary
                                  : widget.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          color: selectedTab == 1
                              ? widget.colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            'To',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: selectedTab == 1
                                  ? widget.colorScheme.primary
                                  : widget.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          // Date Picker Container
          Container(
            height: 170.h,
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color:
                  widget.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: widget.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: selectedTab == 0
                  ? CupertinoDatePicker(
                      key: const ValueKey('from'),
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: tempFrom,
                      maximumDate: tempTo,
                      onDateTimeChanged: (date) =>
                          setState(() => tempFrom = date),
                      backgroundColor: Colors.transparent,
                      itemExtent: 38.h,
                    )
                  : CupertinoDatePicker(
                      key: const ValueKey('to'),
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: tempTo,
                      minimumDate: tempFrom,
                      onDateTimeChanged: (date) =>
                          setState(() => tempTo = date),
                      backgroundColor: Colors.transparent,
                      itemExtent: 38.h,
                    ),
            ),
          ),
          SizedBox(height: 16.h),
          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CommonButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: widget.colorScheme.surface,
                    textColor: widget.colorScheme.onSurface,
                    isBorder: true,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CommonButton(
                    text: 'Apply',
                    onPressed: () {
                      widget.onDateSelected(tempFrom, tempTo);
                      Navigator.pop(context);
                    },
                    backgroundColor: widget.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
