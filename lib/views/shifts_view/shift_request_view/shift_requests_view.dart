import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mos_checkin/views/shifts_view/shift_request_view/widgets/shift_request_dialog.dart';

import '../../../shimmers/shimmer_view_shift_request.dart';
import '../../../utils/common_widgets/common_app_bar.dart';
import '../../../utils/common_widgets/common_date_filter_bar.dart';
import '../../../utils/common_widgets/common_dialog.dart';
import '../../../utils/common_widgets/common_error_widget.dart';
import 'controller/shift_request_view_controller.dart';
import 'widgets/filter_popup_menu.dart';

class ShiftRequestsView extends GetView<ShiftRequestViewController> {
  const ShiftRequestsView({super.key});

  void _showCustomMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Menu",
      barrierColor: Colors.transparent,
      pageBuilder: (context, anim1, anim2) {
        return const FilterPopupMenu();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.onPrimary,
      body: Obx(
        () => Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CommonAppBar(
              title: 'Shift Requests',
              iconPath: 'assets/icons/shift_req.png',
              colorScheme: colorScheme,
            ),
            Padding(
              padding: EdgeInsets.only(right: 14.w),
              child: Row(
                children: [
                  Expanded(
                    child: CommonDateFilterBar(
                      colorScheme: colorScheme,
                      dateRangeText: controller.getFormattedDateRange(),
                      initialFromDate: controller.selectedDateFrom.value,
                      initialToDate: controller.selectedDateTo.value,
                      onDateSelected: (from, to) {
                        controller.isLoading.value = true;
                        controller.selectedDateFrom.value = from;
                        controller.selectedDateTo.value = to;
                        Future.delayed(const Duration(seconds: 2), () {
                          controller.filteredShifts();
                          controller.isLoading.value = false;
                        });
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCustomMenu(context),
                    child: Image.asset(
                      'assets/icons/filter.png',
                      height: 20.h,
                      width: 20.w,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.fetchClientShiftRequests,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Obx(
                    () {
                      return controller.isLoading.value
                          ? const ShiftRequestShimmer()
                          : controller.filteredShiftRequests.isEmpty
                              ? const Center(
                                  child: CommonErrorField(
                                    image: 'assets/images/no_result.png',
                                    message: 'You’re all clear — no shifts for now',
                                    customMessage:
                                        'This is the shifts request screen where you can see the shifts requested by you and their status',
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: controller.sortedDates.length,
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final date = controller.sortedDates[index];
                                    final shiftForDate =
                                        controller.groupedShiftRequests[date]!;
                                    return _buildDateSection(context, date,
                                        shiftForDate, colorScheme);
                                  },
                                );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    String date,
    List shiftsForDate,
    ColorScheme colorScheme,
  ) {
    final weekday = DateFormat('EEEE').format(DateTime.parse(date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
          margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: colorScheme.onPrimaryContainer,
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Text(
            '$weekday, ${DateFormat('d MMMM').format(DateTime.parse(date))}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shiftsForDate.length,
          itemBuilder: (context, shiftIndex) {
            final shiftRequest = shiftsForDate[shiftIndex];
            return _buildShiftCard(shiftRequest, colorScheme, context);
          },
        ),
      ],
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shiftRequest,
      ColorScheme colorScheme, BuildContext context) {
    String shiftStart = shiftRequest['ShiftStart'].toString();
    String shiftEnd = shiftRequest['ShiftEnd'].toString();
    String shiftStartDate = shiftRequest['ShiftDate'].toString();
    String shiftEndDate = shiftRequest['ShiftEndDate'].toString();
    String shiftStatus = shiftRequest['Status'] ?? 'NULL';
    String service = shiftRequest['ServiceDescription'] ?? '';
    String recurrence = shiftRequest['RecurrenceSentence'] ?? '';

    DateTime startTime = DateFormat('HH:mm:ss').parse(shiftStart);
    DateTime endTime = DateFormat('HH:mm:ss').parse(shiftEnd);
    int durationHours = endTime.difference(startTime).inHours;
    String formattedStartTime = DateFormat('hh:mm aa').format(startTime);
    String formattedEndTime = DateFormat('hh:mm aa').format(endTime);
    String duration = "${durationHours}Hr";

    // Status Colors
    Color statusColor = shiftStatus == 'P'
        ? const Color(0xFFFFC600)
        : shiftStatus == 'A'
            ? colorScheme.secondary
            : colorScheme.error;

    return GestureDetector(
      onTap: () {
        Get.dialog(ShiftRequestDialog(
          service: service,
          shiftStart: shiftStartDate,
          shiftEnd: shiftEndDate,
          shiftStatus: shiftStatus,
          recurrence: recurrence,
          formattedStartTime: formattedStartTime,
          formattedEndTime: formattedEndTime,
          duration: duration,
        ));
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: colorScheme.outlineVariant,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upper Part
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.h,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      SizedBox(
                        width: 240.w,
                        child: Text(
                          service,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      _deleteShiftRequestDialog(shiftRequest, context);
                    },
                    child: Container(
                      width: 30.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_sharp,
                        size: 18,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Lower Part
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(14.r),
                  top: Radius.circular(15.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$formattedStartTime - $formattedEndTime',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            duration,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  // Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        shiftStatus == 'P'
                            ? 'Pending'
                            : shiftStatus == 'A'
                                ? 'Approved'
                                : shiftStatus == 'R'
                                    ? 'Rejected'
                                    : 'Cancelled',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  // Recurrence Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recurrence',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          recurrence,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  // Reason Row (if applicable)
                  if (shiftStatus == 'C' || shiftStatus == 'R') ...[
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reason',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            shiftRequest['StatusReason'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteShiftRequestDialog(shiftRequest, BuildContext context) {
    if (shiftRequest['Status'] == 'A') {
      Get.dialog(CommonDialog(
        title: 'Approved Shift Request',
        message:
            'You cannot cancel an approved shift request. Please contact your manager for assistance.',
        confirmText: 'OK',
        onConfirm: () {
          Navigator.pop(context);
        },
      ));
    } else if (shiftRequest['Status'] == 'R') {
      Get.dialog(CommonDialog(
        title: 'Rejected Shift Request',
        message:
            'You cannot cancel a rejected shift request. Please contact your manager for assistance.',
        subMessage: 'Reason: ${shiftRequest['StatusReason'] ?? 'N/A'}',
        confirmText: 'OK',
        onConfirm: () {
          Navigator.pop(context);
        },
      ));
    } else if (shiftRequest['Status'] == 'P') {
      if (shiftRequest['RequestDate'] != null) {
        final requestDate = DateFormat('yyyy-MM-dd').parse(
          shiftRequest['RequestDate'],
        );
        final now = DateTime.now();
        final difference = now.difference(requestDate).inDays;
        if (difference > 7) {
          Get.dialog(CommonDialog(
            title: 'Cancel Shift Request',
            message:
                'You cannot cancel a shift request that was requested more than 7 day ago. Please contact your manager for assistance.',
            confirmText: 'OK',
            onConfirm: () {
              Navigator.pop(context);
            },
          ));
        } else {
          Get.dialog(CommonDialog(
            title: 'Cancel Shift Request',
            message: 'Are you sure you want to cancel this shift request?',
            confirmText: 'Yes',
            onConfirm: () {
              controller.cancelShiftRequest(shiftRequest, context);
            },
          ));
        }
      }
    }
  }

// Widget shiftRequestPopUp(BuildContext context,ShiftRequest){
//   return BackdropFilter(
//     filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
//     child: Dialog(
//       backgroundColor: Colors.transparent,
//       insetPadding:
//       EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.onPrimary,
//           borderRadius: BorderRadius.circular(20.r),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 SizedBox(
//                   width: 200.w,
//                   child: Text(
//                     service,
//                     maxLines: 3,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 14.sp,
//                       color: Theme.of(context)
//                           .colorScheme
//                           .onSurface
//                           .withOpacity(0.8),
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () => Get.back(),
//                   // Return false on close
//                   child: Container(
//                     width: 25,
//                     height: 25,
//                     decoration: BoxDecoration(
//                       color: Colors.transparent,
//                       border: Border.all(
//                         color: Theme.of(context).colorScheme.error,
//                         width: 2,
//                       ),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.close,
//                       color: Theme.of(context).colorScheme.error,
//                       size: 16.sp,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 10.h),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Theme.of(context)
//                     .colorScheme
//                     .primary
//                     .withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Shift Start Date',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Text(
//                         shiftStart,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Divider(
//                       color: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.4)),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Shift End Date',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Text(
//                         shiftEnd,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Divider(
//                       color: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.4)),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Shift Status',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Text(
//                         shiftStatus == 'P'
//                             ? 'Pending'
//                             : shiftStatus == 'A'
//                             ? 'Approved'
//                             : shiftStatus == 'R'
//                             ? 'Rejected'
//                             : 'Cancelled',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Divider(
//                       color: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.4)),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Shift Recurrence',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       SizedBox(
//                         width: 140.w,
//                         child: Text(
//                           recurrence,
//                           maxLines: 3,
//                           overflow: TextOverflow.ellipsis,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color:
//                             Theme.of(context).colorScheme.onSurface,
//                             fontSize: 14.sp,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   Divider(
//                       color: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.4)),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Shift Start Time',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Text(
//                         formattedStartTime.toString(),
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Divider(
//                       color: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.4)),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Shift End Time',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Text(
//                         formattedEndTime.toString(),
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Divider(
//                       color: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.4)),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Shift Duration',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Text(
//                         duration.toString(),
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }
}
