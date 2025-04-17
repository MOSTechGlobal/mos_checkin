import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CommonDatePicker extends FormField<DateTime> {
  CommonDatePicker({
    super.key,
    DateTime? initialDate,
    required Function(DateTime) onDateChanged,
    Color? pickerColor,
    required String hintText,
    String? label,
    EdgeInsets? contentPadding,
    bool? readOnly,
    bool enabled = true, // Added enabled parameter
    VoidCallback? onTapWhenDisabled, // Added callback for disabled tap
    super.validator,
  }) : super(
    initialValue: initialDate,
    builder: (FormFieldState<DateTime> state) {
      void showDatePickerModal(BuildContext context) {
        if (readOnly == true || !enabled) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext modalContext) {
            DateTime rawInitial = state.value ?? initialDate ?? DateTime.now();
            DateTime minimumDate = initialDate ?? DateTime.now();
            DateTime tempDate = rawInitial.isBefore(minimumDate) ? minimumDate : rawInitial;
            DateTime maximumDate = initialDate != null
                ? initialDate.add(Duration(days: 1))
                : DateTime.now().add(Duration(days: 1));
            return StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  height: 300.h,
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 8.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        height: 180.h,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: tempDate,
                          minimumDate: minimumDate,
                          maximumDate: maximumDate,
                          onDateTimeChanged: (DateTime newDate) {
                            final DateTime minDate = minimumDate;
                            final DateTime maxDate = maximumDate;
                            setState(() {
                              if (newDate.isBefore(minDate)) {
                                tempDate = minDate;
                              } else if (newDate.isAfter(maxDate)) {
                                tempDate = maxDate;
                              } else {
                                tempDate = newDate;
                              }
                            });
                          },
                        )
                        ,
                      ),
                      SizedBox(height: 10.h),
                      GestureDetector(
                        onTap: () {
                          state.didChange(tempDate);
                          onDateChanged(tempDate);
                          Navigator.pop(modalContext);
                        },
                        child: Container(
                          height: 40.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16.sp,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      }

      String _formatDate(DateTime date) {
        return DateFormat('dd MMM yyyy').format(date);
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
                ? () => showDatePickerModal(state.context)
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
                          ? _formatDate(state.value!)
                          : hintText,
                      style: TextStyle(
                        color: state.value != null
                            ? Theme.of(state.context)
                            .colorScheme
                            .onSurface
                            : Theme.of(state.context)
                            .colorScheme
                            .onSurface
                            .withOpacity(enabled ? 0.6 : 0.3), // Adjust opacity when disabled
                        fontSize: state.value != null ? 14.sp : 12.sp,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 16.sp,
                      color: Theme.of(state.context)
                          .colorScheme
                          .onSurface
                          .withOpacity(enabled ? 0.6 : 0.3), // Adjust opacity when disabled
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