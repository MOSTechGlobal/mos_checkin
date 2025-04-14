import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mos_checkin/views/shifts_view/make_shift_request_view/widgets/service_modal_view.dart';

import '../../../shimmers/shimmer_make_shift_request.dart';
import '../../../utils/common_widgets/common_app_bar.dart';
import '../../../utils/common_widgets/common_button.dart';
import '../../../utils/common_widgets/common_date_picker.dart';
import '../../../utils/common_widgets/common_dropdown.dart';
import '../../../utils/common_widgets/common_textfield.dart';
import '../../../utils/common_widgets/common_time_picker.dart';
import '../../../utils/prefs.dart';
import 'controller/make_shift_request_controller.dart';

class MakeShiftRequestView extends GetView<MakeShiftRequestController> {
  final String clientId;
  final String clientName;

  const MakeShiftRequestView({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  Widget _buildBasicDetails(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Add Details",
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10.h),
        CommonTextField(
          label: 'First and Last Name',
          hintText: 'First and Last Name',
          readOnly: true,
          controller: TextEditingController()..text = clientName,
        ),
        SizedBox(height: 10.h),
        CommonDatePicker(
          onDateChanged: (pickedDate) {
            controller.selectedStartDate.value = pickedDate;
            controller.startDateController.value =
                DateFormat('dd-MM-yyyy').format(pickedDate);
            controller.endDateController.value =
                DateFormat('dd-MM-yyyy').format(pickedDate);
          },
          hintText: 'Select start date',
          label: 'Choose start date and time',
        ),
        SizedBox(height: 10.h),
        CommonTimePicker(
          associatedDate: controller.selectedStartDate.value, // <-- pass the date
          onTimeChanged: (pickedTime) {
            final now = DateTime.now();
            final selectedDateTime = DateTime(now.year, now.month, now.day,
                pickedTime.hour, pickedTime.minute);
            controller.startTimeController.value =
                DateFormat('hh:mm aa').format(selectedDateTime);
          },
          hintText: 'Select start time',
          enabled: controller.selectedStartDate.value != null,
          onTapWhenDisabled: () {
            Get.snackbar('Attention', 'Please select a start date first',
                colorText: colorScheme.onPrimary,
                backgroundColor: colorScheme.error);
          },
        ),

        // CommonTimePicker(
        //   onTimeChanged: (pickedTime) {
        //     final now = DateTime.now();
        //     final selectedDateTime = DateTime(now.year, now.month, now.day,
        //         pickedTime.hour, pickedTime.minute);
        //     final formattedTime = DateFormat('hh:mm aa').format(selectedDateTime);
        //     controller.startTimeController.value = formattedTime;
        //   },
        //   hintText: 'Select start time',
        //   enabled: controller.selectedStartDate.value != null,
        //   onTapWhenDisabled: () {
        //     Get.snackbar('Attention', 'Please select a start date first',colorText: colorScheme.onPrimary,backgroundColor: colorScheme.error);
        //   },
        // ),
        SizedBox(height: 10.h),
        CommonDatePicker(
          initialDate: controller.selectedStartDate.value,
          onDateChanged: (pickedDate) {
            controller.selectedEndDate.value = pickedDate;
            controller.endDateController.value =
                DateFormat('dd-MM-yyyy').format(pickedDate);
          },
          hintText: 'Select end date',
          label: 'Choose end date and time',
          enabled: controller.selectedStartDate.value != null &&
              controller.startTimeController.value.isNotEmpty,
          onTapWhenDisabled: () {
            Get.snackbar('Attention', controller.selectedStartDate.value == null
                ? 'Please select a start date first'
                : 'Please select a start time first',colorText: colorScheme.onPrimary,backgroundColor: colorScheme.error);
          },
        ),
        SizedBox(height: 10.h),
        CommonTimePicker(
          associatedDate: controller.selectedEndDate.value, // <-- pass the date
          onTimeChanged: (pickedTime) {
            final now = DateTime.now();
            final selectedDateTime = DateTime(now.year, now.month, now.day,
                pickedTime.hour, pickedTime.minute);
            controller.endTimeController.value =
                DateFormat('hh:mm aa').format(selectedDateTime);
          },
          hintText: 'Select start time',
          enabled: controller.selectedStartDate.value != null,
          onTapWhenDisabled: () {
            Get.snackbar('Attention', 'Please select a start date first',
                colorText: colorScheme.onPrimary,
                backgroundColor: colorScheme.error);
          },
        ),
        // CommonTimePicker(
        //   onTimeChanged: (pickedTime) {
        //     final now = DateTime.now();
        //     final selectedDateTime = DateTime(now.year, now.month, now.day,
        //         pickedTime.hour, pickedTime.minute);
        //     final formattedTime = DateFormat('hh:mm aa').format(selectedDateTime);
        //     controller.endTimeController.value = formattedTime;
        //   },
        //   hintText: 'Select end time',
        //   enabled: controller.selectedStartDate.value != null &&
        //       controller.startTimeController.value.isNotEmpty &&
        //       controller.selectedEndDate.value != null,
        //   onTapWhenDisabled: () {
        //     Get.snackbar('Attention',controller.selectedStartDate.value == null
        //         ? 'Please select a start date first'
        //         : controller.startTimeController.value.isEmpty
        //         ? 'Please select a start time first'
        //         : 'Please select an end date first',colorText: colorScheme.onPrimary,backgroundColor: colorScheme.error);
        //   },
        // ),
        SizedBox(height: 10.h),
        _buildServicePicker(context, colorScheme), // Moved here with dependencies
      ],
    );
  }

  Widget _buildServicePicker(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          child: Text(
            'Choose a service',
            style: TextStyle(fontSize: 14.sp, color: colorScheme.onSurface),
          ),
        ),
        GestureDetector(
          onTap:  (controller.selectedStartDate.value != null && controller.startTimeController.value.isNotEmpty)
              ? () => _showServicePicker(context)
              : () {
            Get.snackbar(
              'Attention',
              controller.selectedStartDate.value == null
                  ? 'Please select a start date first'
                  : controller.startTimeController.value.isEmpty
                  ? 'Please select a start time first'
                  : controller.endDateController.value.isEmpty
                  ? 'Please select an end date first'
                  : 'Please select end time first',
              colorText: colorScheme.onPrimary,
              backgroundColor: colorScheme.error,
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    controller.selectedService.value.isNotEmpty
                        ? controller.shiftServices.firstWhere( // Use shiftServices instead of services
                          (service) => service['Service_Code'].toString() == controller.selectedService.value,
                      orElse: () => {'Description': 'Service not found'},
                    )['Description']
                        : 'Select Service',
                    style: TextStyle(
                      color: controller.selectedService.value.isEmpty
                          ? colorScheme.onSurface.withOpacity(0.6)
                          : colorScheme.onSurface,
                      fontSize: controller.selectedService.value.isNotEmpty ? 14.sp : 12.sp,
                    ),
                    maxLines: null,
                  ),
                ),
                Container(
                  width: 16.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  void _showServicePicker(BuildContext context) async {
    final controller = Get.find<MakeShiftRequestController>(); // Assuming controller is accessed via GetX
    final colorScheme = Theme.of(context).colorScheme;

    // Ensure start date and time are available
    if (controller.selectedStartDate.value == null || controller.startTimeController.value.isEmpty) {
      Get.snackbar(
        'Attention',
        controller.selectedStartDate.value == null
            ? 'Please select a start date first'
            : 'Please select a start time first',
        colorText: colorScheme.onPrimary,
        backgroundColor: colorScheme.error,
      );
      return;
    }

    // Parse start date and time to calculate shift type
    final startDate = controller.selectedStartDate.value!;
    final startTimeStr = controller.startTimeController.value;
    final timeFormat = DateFormat('hh:mm aa');
    final startTime = timeFormat.parse(startTimeStr);
    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );

    // Calculate shift type
    await controller.calculateShiftType(startDateTime, startDateTime.add(Duration(hours: 1))); // Assuming 1-hour shift for end time
    final shiftType = controller.shiftTypes.isNotEmpty ? controller.shiftTypes.first : 'standard'; // Fallback to 'standard'
    controller.shiftType.value = shiftType; // Update observable shiftType
    log('Calculated Shift Type: $shiftType');

    // Fetch shift services
    final clientId = await Prefs.getClientID(); // Ensure you have the clientId
    await controller.fetchShiftServices(clientId, shiftType);

    // Show the service picker dialog with fetched shiftServices
    Get.dialog(
      ServiceModalView(
        allServices: controller.shiftServices.toSet(), // Use shiftServices instead of services
        currentServices: controller.selectedService.value.isNotEmpty
            ? {
          controller.shiftServices.firstWhere(
                (service) => service['Service_Code'] == controller.selectedService.value,
            orElse: () => {'Service_Code': '', 'Description': 'Service not found'},
          ),
        }
            : {},
        agreementCode: clientId.toString(),
        startDate: controller.selectedStartDate.value!, // Pass start date
        startTime: controller.startTimeController.value, // Pass start time
        onAddServices: (selectedServices) {
          if (selectedServices.isNotEmpty) {
            controller.selectedService.value = selectedServices.first['Service_Code'];
          }
        },
      ),
    );
  }


  // Widget for monthly recurrence options with consistent UI
  Widget _buildMonthlyRecurrenceOptions(
      BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow,
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  controller.isDayBasedRecurrence.value = true;
                },
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Radio(
                        visualDensity:
                        const VisualDensity(horizontal: -4, vertical: -4),
                        value: true,
                        groupValue: controller.isDayBasedRecurrence.value,
                        onChanged: (value) {
                          controller.isDayBasedRecurrence.value = value as bool;
                        },
                        activeColor: colorScheme.primary,
                      ),
                    ),
                    Text(
                      'On day',
                      style: TextStyle(
                          fontSize: 14.sp, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: CommonTextField(
                  controller: TextEditingController()
                    ..text = controller.mDayControllerText.value,
                  hintText: '1',
                  keyboardType: TextInputType.number,
                  enabled: controller.isDayBasedRecurrence.value,
                  paddingVertical: 5,
                  onChanged: (value) {
                    if (value.isNotEmpty &&
                        int.tryParse(value) != null &&
                        int.parse(value) > 31) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter a valid number between 1 and 31',
                            style: TextStyle(
                                fontSize: 14, color: colorScheme.onSecondary),
                          ),
                        ),
                      );
                      controller.mDayControllerText.value = '1';
                    } else {
                      controller.mDayControllerText.value = value;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow,
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  controller.isDayBasedRecurrence.value = false;
                },
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Radio(
                        value: false,
                        groupValue: controller.isDayBasedRecurrence.value,
                        onChanged: (value) {
                          controller.isDayBasedRecurrence.value = value as bool;
                        },
                        activeColor: colorScheme.primary,
                        visualDensity:
                        const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    ),
                    Text(
                      'On the',
                      style: TextStyle(
                          fontSize: 14.sp, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: CommonDropdown(
                  value: controller.selectedOccurance.value,
                  items: const <String>['1st', '2nd', '3rd', '4th', 'Last'],
                  hintText: 'Select',
                  onChanged: controller.isDayBasedRecurrence.value
                      ? null
                      : (value) {
                    controller.selectedOccurance.value = value!;
                  },
                  paddingVertical: 2,
                  enabled: !controller.isDayBasedRecurrence.value,
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: CommonDropdown(
                  value: controller.selectedWeekDay.value,
                  items: const <String>[
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ],
                  hintText: 'Select',
                  onChanged: controller.isDayBasedRecurrence.value
                      ? null
                      : (value) {
                    controller.selectedWeekDay.value = value!;
                  },
                  paddingVertical: 2,
                  enabled: !controller.isDayBasedRecurrence.value,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget for recurring shift options
  Widget _buildRecurringShiftOptions(
      BuildContext context, ColorScheme colorScheme) {
    return Obx(() => Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow,
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ],
          ),
          padding: EdgeInsets.only(left: 10.w, top: 5.h, bottom: 5.h),
          child: GestureDetector(
            onTap: () {
              // Toggle the value when the entire row is tapped
              controller.isRecurringShift.value =
              !controller.isRecurringShift.value;
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recurring Shift',
                    style: TextStyle(
                      fontSize:
                      controller.isRecurringShift.value ? 14.sp : 12.sp,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: controller.isRecurringShift.value ? 1 : 0.8,
                  // Reduce the checkbox size
                  child: Checkbox(
                    value: controller.isRecurringShift.value,
                    onChanged: (value) {
                      controller.isRecurringShift.value = value ?? false;
                    },
                    activeColor: colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize
                        .shrinkWrap, // Reduces tap area padding
                  ),
                )
              ],
            ),
          ),
        ),
        if (controller.isRecurringShift.value)
          Container(
            margin: EdgeInsets.symmetric(vertical: 10.h),
            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Repeat Every',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: CommonTextField(
                        hintText: 'number',
                        controller: controller.repeatEveryController,
                        keyboardType: TextInputType.number,
                        paddingVertical: 5,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            controller.repeatEveryController.text = '';
                            return;
                          }
                          int? parsedValue = int.tryParse(value);
                          if (parsedValue == null ||
                              parsedValue < 0 ||
                              parsedValue > 99) {
                            Get.snackbar(
                              'Invalid input',
                              'Please enter a valid number between 1 and 99',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: colorScheme.error,
                              colorText: colorScheme.onPrimary,
                            );
                            controller.repeatEveryController.text = '1';
                            controller.repeatEveryController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(
                                      offset: controller
                                          .repeatEveryController.text.length),
                                );
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Flexible(
                      child: CommonDropdown(
                        value: controller.selectedRecurringShiftType.value,
                        items: const <String>['days', 'weeks', 'months'],
                        hintText: 'Select',
                        onChanged: (value) {
                          controller.selectedRecurringShiftType.value =
                          value!;
                        },
                        iconWidth: 16,
                        paddingVertical: 3,
                      ),
                    ),
                  ],
                ),
                if (controller.selectedRecurringShiftType.value == 'weeks')
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    margin: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var day in [
                          'Mo',
                          'Tu',
                          'We',
                          'Th',
                          'Fr',
                          'Sa',
                          'Su'
                        ])
                          GestureDetector(
                            onTap: () {
                              controller.selectedWeekDays[day]?.value =
                              !controller.selectedWeekDays[day]!.value;
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                controller.selectedWeekDays[day]!.value
                                    ? colorScheme.primary
                                    : colorScheme.onSurface
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: controller
                                        .selectedWeekDays[day]!.value
                                        ? colorScheme.onSecondary
                                        : colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (controller.selectedRecurringShiftType.value == 'months')
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: _buildMonthlyRecurrenceOptions(
                        context, colorScheme),
                  ),
              ],
            ),
          ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.onPrimary,
      body: Column(
        children: [
          CommonAppBar(
            title: 'Make Service Request',
            iconPath: 'assets/icons/calendar.png',
            colorScheme: colorScheme,
          ),
          SizedBox(height: 4.h),
          Expanded(
            child: Obx(() {
              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 16.h),
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
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicDetails(context,colorScheme),
                        SizedBox(height: 10.h),
                        // _buildServicePicker(context, colorScheme),
                        // SizedBox(height: 10.h),
                        _buildRecurringShiftOptions(context, colorScheme),
                        SizedBox(height: 12.h),
                        CommonButton(
                          text: 'Save',
                          onPressed: controller.isSubmitting.value
                              ? null // Disable button while submitting
                              : controller.selectedService.value.isEmpty? null: () {
                            controller.extractData(
                                context, colorScheme);
                          },
                          isSaving: controller.isSubmitting.value,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
