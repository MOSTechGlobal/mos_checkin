import 'dart:developer';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mos_checkin/views/shifts_view/make_shift_request_view/widgets/service_modal_view.dart';

import '../../../utils/common_widgets/common_app_bar.dart';
import '../../../utils/common_widgets/common_button.dart';
import 'controller/make_shift_request_controller.dart';

class MakeShiftRequestView extends GetView<MakeShiftRequestController> {
  final String clientId;
  final String clientName;

  const MakeShiftRequestView({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
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
                child: Center(child: _buildCard(context, colorScheme)),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 15.h),
      child: Column(
        children: [
          _buildFieldRow(
            'Client',
            clientName,
            null, // Non-editable
            isEditable: false,
          ),
          const Divider(),
          _buildFieldRow(
            'Start Date',
            controller.startDateController.value.isNotEmpty
                ? controller.startDateController.value
                : 'Select',
                () => _pickStartDate(context),
          ),
          const Divider(),
          _buildFieldRow(
            'Start Time',
            controller.startTimeController.value.isNotEmpty
                ? controller.startTimeController.value
                : 'Select',
                () => _pickStartTime(context),
          ),
          const Divider(),
          _buildFieldRow(
            'Two Days Shift',
            controller.twoDaysShift.value ? 'Yes' : 'No',
                () {
              controller.twoDaysShift.value = !controller.twoDaysShift.value;
              if (!controller.twoDaysShift.value &&
                  controller.selectedStartDate.value != null) {
                controller.selectedEndDate.value = controller.selectedStartDate.value;
                controller.endDateController.value =
                    controller.startDateController.value;
                if (controller.startTimeController.value.isNotEmpty) {
                  final startTime = DateFormat('hh:mm aa')
                      .parse(controller.startTimeController.value);
                  final endDateTime = startTime.add(const Duration(hours: 1));
                  controller.endTimeController.value =
                      DateFormat('hh:mm aa').format(endDateTime);
                }
              }
            },
          ),
          const Divider(),
          _buildFieldRow(
            'End Date',
            controller.endDateController.value.isNotEmpty
                ? controller.endDateController.value
                : 'Select',
                () => _pickEndDate(context),
            isEditable: controller.twoDaysShift.value &&
                controller.selectedStartDate.value != null &&
                controller.startTimeController.value.isNotEmpty,
          ),
          const Divider(),
          _buildFieldRow(
            'End Time',
            controller.endTimeController.value.isNotEmpty
                ? controller.endTimeController.value
                : 'Select',
                () => _pickEndTime(context),
            isEditable: controller.selectedStartDate.value != null &&
                controller.startTimeController.value.isNotEmpty &&
                controller.selectedEndDate.value != null,
          ),
          const Divider(),
          _buildFieldRow(
            'Service',
            controller.selectedService.value.isNotEmpty
                ? controller.shiftServices.firstWhere(
                  (service) =>
              service['Service_Code'].toString() ==
                  controller.selectedService.value,
              orElse: () => {'Description': 'Service not found'},
            )['Description']
                : 'Select',
                () => _showServicePicker(context),
            isEditable: controller.selectedStartDate.value != null &&
                controller.startTimeController.value.isNotEmpty &&
                controller.selectedEndDate.value != null &&
                controller.endTimeController.value.isNotEmpty,
          ),
          const Divider(),
          _buildRecurringShiftRow(context, colorScheme),
          const Divider(),
          _buildActionButtons(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value, VoidCallback? onTap,
      {bool isEditable = true}) {
    return InkWell(
      onTap: isEditable
          ? onTap
          : () {
        if (onTap == null) return;
        String message;
        switch (label) {
          case 'End Date':
            message = 'Please enable Two Days Shift to edit End Date';
            break;
          case 'End Time':
            message =
            'Please select Start Date, Start Time, and End Date first';
            break;
          case 'Service':
            message =
            'Please select Start Date, Start Time, End Date, and End Time first';
            break;
          default:
            message = 'This field is not editable';
        }
        Get.snackbar(
          'Attention',
          message,
          backgroundColor: Theme.of(Get.context!).colorScheme.error,
          colorText: Theme.of(Get.context!).colorScheme.onPrimary,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      value.isEmpty ? 'Select' : value,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(Get.context!).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isEditable
                        ? Theme.of(Get.context!).colorScheme.onSurface
                        : Theme.of(Get.context!)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringShiftRow(
      BuildContext context, ColorScheme colorScheme) {
    return Obx(() => Column(
          children: [
            _buildFieldRow(
              'Recurring Shift',
              controller.isRecurringShift.value ? 'Yes' : 'No',
              () {
                controller.isRecurringShift.value =
                    !controller.isRecurringShift.value;
                if (!controller.isRecurringShift.value) {
                  controller.selectedRecurringShiftType.value = '';
                  controller.repeatEveryController.text = '';
                }
              },
            ),
            if (controller.isRecurringShift.value) ...[
              const Divider(),
              _buildFieldRow(
                'Repeat Every',
                controller.selectedRecurringShiftType.value.isNotEmpty
                    ? controller.selectedRecurringShiftType.value == 'days'
                    ? controller.repeatEveryControllerText.value.isNotEmpty
                    ? '${controller.repeatEveryControllerText.value} days'
                    : 'Select number of days'
                    : controller.selectedRecurringShiftType.value.capitalizeFirst!
                    : 'Select',
                    () => _showRecurringDialog(context, colorScheme),
              ),
              if (controller.selectedRecurringShiftType.value == 'weeks') ...[
                const Divider(),
                _buildFieldRow(
                  'Week Days',
                  controller.selectedWeekDays.entries
                          .where((entry) => entry.value.value)
                          .map((entry) => entry.key)
                          .join(', ')
                          .isNotEmpty
                      ? controller.selectedWeekDays.entries
                          .where((entry) => entry.value.value)
                          .map((entry) => entry.key)
                          .join(', ')
                      : 'Select',
                  () => _showWeekDaysDialog(context, colorScheme),
                ),
              ],
              if (controller.selectedRecurringShiftType.value == 'months') ...[
                const Divider(),
                _buildFieldRow(
                  'Monthly Recurrence',
                  controller.isDayBasedRecurrence.value
                      ? 'On day ${controller.mDayControllerText.value}'
                      : 'On the ${controller.selectedOccurance.value} ${controller.selectedWeekDay.value}',
                  () => _showMonthlyRecurrenceDialog(context, colorScheme),
                ),
              ],
            ],
          ],
        ));
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton(
            label: controller.isSubmitting.value ? 'Saving...' : 'Save',
            onTap: controller.isSubmitting.value ||
                    controller.selectedService.value.isEmpty
                ? null
                : () => controller.extractData(context, colorScheme),
            color: colorScheme.primary,
            isLoading: controller.isSubmitting.value,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback? onTap,
    required Color color,
    bool isLoading = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: onTap == null ? Colors.grey : color,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(Get.context!).colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(Get.context!).colorScheme.onPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final initialDate = controller.selectedStartDate.value ?? DateTime.now();
    await showDialog(
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
                      'Select Start Date',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(context).colorScheme.error,
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
                  height: 300.h,
                  child: CalendarDatePicker(
                    initialDate: initialDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onDateChanged: (picked) {
                      controller.selectedStartDate.value = picked;
                      controller.startDateController.value =
                          DateFormat('dd-MM-yyyy').format(picked);
                      // Sync end date if not a two-day shift
                      if (!controller.twoDaysShift.value) {
                        controller.selectedEndDate.value = picked;
                        controller.endDateController.value =
                            DateFormat('dd-MM-yyyy').format(picked);
                      }
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickEndDate(BuildContext context) async {
    if (!controller.twoDaysShift.value ||
        controller.selectedStartDate.value == null ||
        controller.startTimeController.value.isEmpty) {
      Get.snackbar(
        'Attention',
        controller.twoDaysShift.value
            ? controller.selectedStartDate.value == null &&
            controller.startTimeController.value.isEmpty
            ? 'Please select both Start Date and Start Time first'
            : controller.selectedStartDate.value == null
            ? 'Please select a Start Date first'
            : 'Please select a Start Time first'
            : 'Please enable Two Days Shift to edit End Date',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onPrimary,
      );
      return;
    }

    final initialDate =
        controller.selectedEndDate.value ?? controller.selectedStartDate.value!;
    await showDialog(
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
                      'Select End Date',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(context).colorScheme.error,
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
                  height: 300.h,
                  child: CalendarDatePicker(
                    initialDate: initialDate,
                    firstDate: controller.selectedStartDate.value!,
                    lastDate:
                    controller.selectedStartDate.value!.add(Duration(days: 1)),
                    onDateChanged: (picked) {
                      controller.selectedEndDate.value = picked;
                      controller.endDateController.value =
                          DateFormat('dd-MM-yyyy').format(picked);
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartTime(BuildContext context) async {
    if (controller.selectedStartDate.value == null) {
      Get.snackbar(
        'Attention',
        'Please select a start date first',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onPrimary,
      );
      return;
    }

    final initialTime = controller.startTimeController.value.isNotEmpty
        ? DateFormat('hh:mm aa').parse(controller.startTimeController.value)
        : DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.fromDateTime(initialTime);

    await showDialog(
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
                      'Select Start Time',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(context).colorScheme.error,
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
                    initialDateTime: initialTime,
                    onDateTimeChanged: (DateTime newDateTime) {
                      selectedTime = TimeOfDay.fromDateTime(newDateTime);
                    },
                  ),
                ),
                SizedBox(height: 16.h),
                GestureDetector(
                  onTap: () {
                    if (selectedTime != null) {
                      final selectedDateTime = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                      controller.startTimeController.value =
                          DateFormat('hh:mm aa').format(selectedDateTime);
                      if (!controller.twoDaysShift.value) {
                        final endDateTime =
                        selectedDateTime.add(const Duration(hours: 1));
                        controller.endTimeController.value =
                            DateFormat('hh:mm aa').format(endDateTime);
                      }
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickEndTime(BuildContext context) async {
    if (controller.selectedStartDate.value == null ||
        controller.startTimeController.value.isEmpty ||
        controller.selectedEndDate.value == null) {
      Get.snackbar(
        'Attention',
        controller.selectedStartDate.value == null
            ? 'Please select a Start Date first'
            : controller.startTimeController.value.isEmpty
            ? 'Please select a Start Time first'
            : 'Please select an End Date first',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onPrimary,
      );
      return;
    }

    final initialTime = controller.endTimeController.value.isNotEmpty
        ? DateFormat('hh:mm aa').parse(controller.endTimeController.value)
        : (controller.startTimeController.value.isNotEmpty
        ? DateFormat('hh:mm aa')
        .parse(controller.startTimeController.value)
        .add(const Duration(hours: 1))
        : DateTime.now());
    TimeOfDay? selectedTime = TimeOfDay.fromDateTime(initialTime);

    await showDialog(
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
                      'Select End Time',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(context).colorScheme.error,
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
                    initialDateTime: initialTime,
                    onDateTimeChanged: (DateTime newDateTime) {
                      selectedTime = TimeOfDay.fromDateTime(newDateTime);
                    },
                  ),
                ),
                SizedBox(height: 16.h),
                GestureDetector(
                  onTap: () {
                    if (selectedTime != null) {
                      final selectedDateTime = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                      controller.endTimeController.value =
                          DateFormat('hh:mm aa').format(selectedDateTime);
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showServicePicker(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    if (controller.selectedStartDate.value == null ||
        controller.startTimeController.value.isEmpty ||
        controller.selectedEndDate.value == null ||
        controller.endTimeController.value.isEmpty) {
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
      return;
    }

    Get.dialog(
      Obx(() => ServiceModalView(
            allServices: controller.shiftServices.toSet(),
            currentServices: controller.selectedService.value.isNotEmpty
                ? {
                    controller.shiftServices.firstWhere(
                      (service) =>
                          service['Service_Code'] ==
                          controller.selectedService.value,
                      orElse: () => {
                        'Service_Code': '',
                        'Description': 'Service not found'
                      },
                    ),
                  }
                : {},
            agreementCode: clientId.toString(),
            startDate: controller.selectedStartDate.value!,
            startTime: controller.startTimeController.value,
            onAddServices: (selectedServices) {
              if (selectedServices.isNotEmpty) {
                controller.selectedService.value =
                    selectedServices.first['Service_Code'];
              }
            },
          )),
      barrierDismissible: false,
    );

    try {
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

      await controller.calculateShiftType(
          startDateTime, startDateTime.add(Duration(hours: 1)));
      final shiftType = controller.shiftTypes.isNotEmpty
          ? controller.shiftTypes.first
          : 'standard';
      controller.shiftType.value = shiftType;
      log('Calculated Shift Type: $shiftType');

      await controller.fetchShiftServices(clientId, shiftType);
    } catch (e) {
      log('Error in _showServicePicker: $e');
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to load services',
        colorText: colorScheme.onPrimary,
        backgroundColor: colorScheme.error,
      );
    }
  }

  Future<void> _showRecurringDialog(
      BuildContext context, ColorScheme colorScheme) async {
    final textController =
        TextEditingController(text: controller.repeatEveryController.text);
    final localRecurringType = RxString(
        controller.selectedRecurringShiftType.value.isNotEmpty
            ? controller.selectedRecurringShiftType.value
            : 'days');

    await showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repeat Every',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 25.w,
                        height: 25.h,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border:
                              Border.all(color: colorScheme.error, width: 2),
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
                SizedBox(height: 16.h),
                Obx(() => Row(
                      children: [
                        if (localRecurringType.value == 'days') ...[
                          Expanded(
                            child: TextField(
                              controller: textController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: colorScheme.outline),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  textController.text = '';
                                  return;
                                }
                                int? parsedValue = int.tryParse(value);
                                if (parsedValue == null ||
                                    parsedValue <= 0 ||
                                    parsedValue > 99) {
                                  Get.snackbar(
                                    'Invalid input',
                                    'Please enter a valid number between 1 and 99',
                                    backgroundColor: colorScheme.error,
                                    colorText: colorScheme.onPrimary,
                                  );
                                  textController.text = '1';
                                  textController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset: textController.text.length),
                                  );
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 10.w),
                        ],
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: localRecurringType.value,
                            items: const <String>['days', 'weeks', 'months']
                                .map((String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value.capitalize!),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              localRecurringType.value = value!;
                              if (value != 'days') {
                                textController.text = '';
                                controller.repeatEveryController.text = '';
                              } else {
                                textController.text = controller
                                        .repeatEveryController.text.isNotEmpty
                                    ? controller.repeatEveryController.text
                                    : '1';
                              }
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: colorScheme.outline),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
                SizedBox(height: 16.h),
                CommonButton(
                  text: 'Save',
                  onPressed: () {
                    if (localRecurringType.value == 'days' &&
                        (textController.text.isEmpty ||
                            int.tryParse(textController.text) == null ||
                            int.parse(textController.text) <= 0)) {
                      Get.snackbar(
                        'Invalid input',
                        'Please enter a valid number of days between 1 and 99',
                        backgroundColor: colorScheme.error,
                        colorText: colorScheme.onPrimary,
                      );
                      return;
                    }
                    controller.repeatEveryController.text = textController.text;
                    controller.repeatEveryControllerText.value = textController.text; // Update reactive variable
                    controller.selectedRecurringShiftType.value = localRecurringType.value;
                    log('Saved Recurring: ${textController.text}, ${localRecurringType.value}');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWeekDaysDialog(
      BuildContext context, ColorScheme colorScheme) async {
    final localWeekDays = Map<String, RxBool>.from(controller.selectedWeekDays);

    await showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Week Days',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 25.w,
                        height: 25.h,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border:
                              Border.all(color: colorScheme.error, width: 2),
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
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                      .map((day) => Obx(() => GestureDetector(
                            onTap: () {
                              localWeekDays[day]!.value =
                                  !localWeekDays[day]!.value;
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: localWeekDays[day]!.value
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: localWeekDays[day]!.value
                                        ? colorScheme.onSecondary
                                        : colorScheme.onSurface
                                            .withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          )))
                      .toList(),
                ),
                SizedBox(height: 16.h),
                CommonButton(
                  text: 'Save',
                  onPressed: () {
                    controller.selectedWeekDays.forEach((key, value) {
                      value.value = localWeekDays[key]!.value;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthlyRecurrenceDialog(
      BuildContext context, ColorScheme colorScheme) async {
    final dayController =
        TextEditingController(text: controller.mDayControllerText.value);
    final localOccurrence = controller.selectedOccurance.value;
    final localWeekDay = controller.selectedWeekDay.value;

    await showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Recurrence',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 25.w,
                        height: 25.h,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border:
                              Border.all(color: colorScheme.error, width: 2),
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
                SizedBox(height: 16.h),
                Obx(() => Row(
                      children: [
                        Radio(
                          value: true,
                          groupValue: controller.isDayBasedRecurrence.value,
                          onChanged: (value) {
                            controller.isDayBasedRecurrence.value =
                                value as bool;
                          },
                          activeColor: colorScheme.primary,
                        ),
                        Text('On day', style: TextStyle(fontSize: 14.sp)),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TextField(
                            controller: dayController,
                            keyboardType: TextInputType.number,
                            enabled: controller.isDayBasedRecurrence.value,
                            decoration: InputDecoration(
                              hintText: '1',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: colorScheme.outline),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty &&
                                  int.tryParse(value) != null &&
                                  int.parse(value) > 31) {
                                Get.snackbar(
                                  'Invalid input',
                                  'Please enter a valid number between 1 and 31',
                                  backgroundColor: colorScheme.error,
                                  colorText: colorScheme.onPrimary,
                                );
                                dayController.text = '1';
                              }
                            },
                          ),
                        ),
                      ],
                    )),
                SizedBox(height: 10.h),
                Obx(() => Row(
                      children: [
                        Radio(
                          value: false,
                          groupValue: controller.isDayBasedRecurrence.value,
                          onChanged: (value) {
                            controller.isDayBasedRecurrence.value =
                                value as bool;
                          },
                          activeColor: colorScheme.primary,
                        ),
                        Text('On the', style: TextStyle(fontSize: 14.sp)),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: localOccurrence,
                            items: const <String>[
                              '1st',
                              '2nd',
                              '3rd',
                              '4th',
                              'Last'
                            ]
                                .map((String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: controller.isDayBasedRecurrence.value
                                ? null
                                : (value) {
                                    controller.selectedOccurance.value = value!;
                                  },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: colorScheme.outline),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: localWeekDay,
                            items: const <String>[
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun'
                            ]
                                .map((String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: controller.isDayBasedRecurrence.value
                                ? null
                                : (value) {
                                    controller.selectedWeekDay.value = value!;
                                  },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: colorScheme.outline),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
                SizedBox(height: 16.h),
                CommonButton(
                  text: 'Save',
                  onPressed: () {
                    controller.mDayControllerText.value = dayController.text;
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
