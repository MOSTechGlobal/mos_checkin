import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mos_checkin/views/form_view/widgets/filter_popup_menu.dart';

import '../../shimmers/shimmer_form_view.dart';
import '../../utils/common_widgets/common_app_bar.dart';
import '../../utils/common_widgets/common_date_filter_bar.dart';
import '../../utils/common_widgets/common_error_widget.dart';
import 'controller/form_controller.dart';
import 'widgets/forms_details_view.dart';

class FormsView extends GetView<FormController> {
  const FormsView({super.key});

  Widget _buildDateSection(
      String date, List formsForDate, ColorScheme colorScheme) {
    final weekday = DateFormat('EEEE').format(DateTime.parse(date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
          margin:
              EdgeInsets.only(left: 10.h, right: 10.h, bottom: 6.h, top: 4.h),
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
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: formsForDate.length,
          itemBuilder: (context, formIndex) {
            final form = formsForDate[formIndex];
            return _buildFormCard(form, colorScheme, context);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.onPrimary,
      body: Obx(() => controller.isLoading.value
          ? const ShimmerFormView()
          : controller.errorMessage.isNotEmpty
              ? Column(
                  children: [
                    CommonAppBar(
                      title: 'Forms',
                      iconPath: 'assets/icons/forms.png',
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
                              initialFromDate:
                                  controller.selectedDateFrom.value,
                              initialToDate: controller.selectedDateTo.value,
                              onDateSelected: (from, to) {
                                controller.isLoading.value = true;
                                controller.selectedDateFrom.value = from;
                                controller.selectedDateTo.value = to;
                                Future.delayed(const Duration(seconds: 2), () {
                                  controller.filterForms();
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
                      child: Center(
                        child: CommonErrorField(
                          image: 'assets/images/no_result.png',
                          message: controller.errorMessage.value,
                          customMessage:
                              'This is the Forms Screen where you can manage forms for the client profile. From here, you can add, review, and track all necessary forms required for the client.',
                        ),
                      ),
                    ),
                  ],
                )
              : controller.filteredForms.isEmpty
                  ? Column(
                      children: [
                        CommonAppBar(
                          title: 'Forms',
                          iconPath: 'assets/icons/forms.png',
                          colorScheme: colorScheme,
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 14.w),
                          child: Row(
                            children: [
                              Expanded(
                                child: CommonDateFilterBar(
                                  colorScheme: colorScheme,
                                  dateRangeText:
                                      controller.getFormattedDateRange(),
                                  initialFromDate:
                                      controller.selectedDateFrom.value,
                                  initialToDate:
                                      controller.selectedDateTo.value,
                                  onDateSelected: (from, to) {
                                    controller.isLoading.value = true;
                                    controller.selectedDateFrom.value = from;
                                    controller.selectedDateTo.value = to;
                                    Future.delayed(const Duration(seconds: 2),
                                        () {
                                      controller.filterForms();
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
                        const Expanded(
                          child: Center(
                            child: CommonErrorField(
                              image: 'assets/images/no_result.png',
                              message:
                                  'No Forms found in the selected date range',
                              customMessage:
                                  'This is the Forms Screen where you can manage forms for the client profile. From here, you can add, review, and track all necessary forms required for the client.',
                            ),
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      child: Column(
                        children: [
                          CommonAppBar(
                              title: 'Forms',
                              iconPath: 'assets/icons/forms.png',
                              colorScheme: colorScheme),
                          Expanded(
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 14.w),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: CommonDateFilterBar(
                                          colorScheme: colorScheme,
                                          dateRangeText: controller
                                              .getFormattedDateRange(),
                                          initialFromDate:
                                              controller.selectedDateFrom.value,
                                          initialToDate:
                                              controller.selectedDateTo.value,
                                          onDateSelected: (from, to) {
                                            controller.isLoading.value = true;
                                            controller.selectedDateFrom.value =
                                                from;
                                            controller.selectedDateTo.value =
                                                to;
                                            Future.delayed(
                                                const Duration(seconds: 2), () {
                                              controller.filterForms();
                                              controller.isLoading.value =
                                                  false;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
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
                                    child: Obx(
                                  () => ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: controller.sortedDates.length,
                                    itemBuilder: (context, index) {
                                      final date =
                                          controller.sortedDates[index];
                                      final formsForDate =
                                          controller.groupedForms[date]!;
                                      return _buildDateSection(
                                          date, formsForDate, colorScheme);
                                    },
                                  ),
                                )),
                              ],
                            ),
                          )
                        ],
                      ),
                      onRefresh: () async {
                        controller.fetchAssignedForms();
                      })),
    );
  }

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

  Widget _buildFormCard(Map<String, dynamic> form, ColorScheme colorScheme,
      BuildContext context) {
    final String status = (form['Status'] ?? 'Unknown').toString();
    final String templateName =
        (form['TemplateName'] ?? form['Name'] ?? 'No Title').toString();
    final bool isCompleted = status.toLowerCase() == 'completed';

    DateTime? assignedDate;
    String dateText = 'N/A';

    if (form['AssignedDate'] != null || form['CreatedAt'] != null) {
      try {
        assignedDate =
            DateTime.parse(form['AssignedDate'] ?? form['CreatedAt']);
        dateText = DateFormat('dd/MM/yyyy').format(assignedDate);
      } catch (e) {
        dateText = 'Invalid Date';
      }
    }

    return GestureDetector(
      onTap: () async {
        await Get.to(
          () => FormDetailView(
            formId: form['FormInstanceId'],
            isCompleted: isCompleted,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFFD8FFCA)
              : const Color(0xffFFF3CA).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  customTextSpan(colorScheme, 'Form Name:', templateName),
                  customTextSpan(colorScheme, 'Assigned Date: ', dateText),
                  customTextSpan(colorScheme, 'Status: ', status),
                  // Fixed to show status instead of dateText
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isCompleted ? Colors.grey[400] : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget customTextSpan(
      ColorScheme colorScheme, String title, String subTitle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Text(
            '$title ',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subTitle,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
