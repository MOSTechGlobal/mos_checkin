import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'common_button.dart';

class CommonTimePicker extends FormField<DateTime> {
  CommonTimePicker({
    superuitkey,
    DateTime? initialTime,
    required Function(DateTime) onTimeChanged,
    Color? pickerColor,
    required String hintText,
    String? label,
    EdgeInsets? contentPadding,
    bool? readOnly,
    bool enabled = true,
    VoidCallback? onTapWhenDisabled, // Added callback for disabled tap
    super.validator,
  }) : super(
    initialValue: initialTime,
    builder: (FormFieldState<DateTime> state) {
      void showTimePickerModal(BuildContext context) {
        if (readOnly == true || !enabled) return;

        DateTime tempTime = state.value ?? initialTime ?? DateTime.now();

        showDialog(
          context: context,
          builder: (dialogContext) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Time',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color:
                            Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          child: Container(
                            width: 25.w,
                            height: 25.h,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color:
                                Theme.of(context).colorScheme.error,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.error,
                              size: 16.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      height: 200.h,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: tempTime,
                        onDateTimeChanged: (DateTime newTime) {
                          tempTime = newTime;
                        },
                        use24hFormat: false,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    CommonButton(
                      text: 'Save',
                      onPressed: () {
                        state.didChange(tempTime);
                        onTimeChanged(tempTime);
                        Navigator.pop(dialogContext);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      String formatTime(DateTime time) {
        return DateFormat('hh:mm a').format(time);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null && label.isNotEmpty)
            Padding(
              padding:
              EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(state.context).colorScheme.onSurface,
                ),
              ),
            ),
          GestureDetector(
            onTap: enabled
                ? () => showTimePickerModal(state.context)
                : onTapWhenDisabled, // Use callback when disabled
            child: Container(
              height: 40.h,
              decoration: BoxDecoration(
                color: pickerColor ??
                    Theme.of(state.context).colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(state.context).colorScheme.shadow,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: Padding(
                padding: contentPadding ??
                    EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.value != null
                          ? formatTime(state.value!)
                          : hintText,
                      style: TextStyle(
                        color: state.value != null
                            ? Theme.of(state.context)
                            .colorScheme
                            .onSurface
                            : Theme.of(state.context)
                            .colorScheme
                            .onSurface
                            .withOpacity(enabled ? 0.6 : 0.3),
                        fontSize: state.value != null ? 14.sp : 12.sp,
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      size: 16.sp,
                      color: Theme.of(state.context)
                          .colorScheme
                          .onSurface
                          .withOpacity(enabled ? 0.6 : 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (state.hasError)
            Padding(
              padding: EdgeInsets.only(top: 4.h, left: 6.w),
              child: Text(
                state.errorText!,
                style: TextStyle(
                  color: Theme.of(state.context).colorScheme.error,
                  fontSize: 12.sp,
                ),
              ),
            ),
        ],
      );
    },
  );
}