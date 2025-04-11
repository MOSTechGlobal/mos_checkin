import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../shimmers/shimmer_form_view.dart';
import '../../utils/common_widgets/common_app_bar.dart';
import '../../utils/common_widgets/common_date_filter_bar.dart';
import '../../utils/common_widgets/common_error_widget.dart';
import '../../utils/common_widgets/common_search_bar.dart';
import 'controller/roster_view_controller.dart';
import 'widget/roster_shift_tile.dart';

class RostersView extends GetView<RosterViewController> {
  const RostersView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.onPrimary,
      body: Obx(() => controller.isLoading.value
          ? const ShimmerFormView()
          : Column(
            children: [
              CommonAppBar(
                title: 'Rosters',
                iconPath: 'assets/icons/roster.png',
                colorScheme: colorScheme,
              ),
              CommonDateFilterBar(
                colorScheme: colorScheme,
                dateRangeText: controller.getFormattedDateRange(),
                initialFromDate: controller.selectedDateFrom.value,
                initialToDate: controller.selectedDateTo.value,
                onDateSelected: (from, to) {
                  controller.isLoading.value = true;
                  controller.selectedDateFrom.value = from;
                  controller.selectedDateTo.value = to;
                  Future.delayed(const Duration(seconds: 2), () {
                    controller.filterShifts();
                    controller.isLoading.value = false;
                  });
                },
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric( horizontal:  8.w),
                child: CommonSearchBar(
                  colorScheme: colorScheme,
                  searchController: controller.searchController,
                  onChanged: (value) => controller.searchShifts(value),
                  onClear: () {
                    controller.clearSearch();
                  },
                ),
              ),
              SizedBox(height: 10.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem("All", "All", colorScheme ,null),
                        _buildLegendItem(
                            "Completed", "Completed",colorScheme, Colors.green[900]),
                        _buildLegendItem(
                            "In Progress", "In Progress",colorScheme ,Colors.amber),
                        _buildLegendItem("Not Started", "Not Started",colorScheme,
                            Colors.red[900]!),
                      ],
                    )),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: Obx(
                  () => controller.isLoading.value
                      ? const ShimmerFormView()
                      : controller.groupedShifts.isEmpty ||
                              controller.filteredShifts.isEmpty
                          ? const Expanded(
                              child: Center(
                                child: CommonErrorField(
                                  image: 'assets/images/no_result.png',
                                  message:
                                      'No Shifts found in the selected date range.',
                                  customMessage:
                                      'This is the Forms Screen where you can manage forms for the client profile. From here, you can add, review, and track all necessary forms required for the client.',
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              itemCount: controller.sortedDates.length,
                              itemBuilder: (context, index) {
                                final date = controller.sortedDates[index];
                                final shiftsForDate =
                                    controller.groupedShifts[date]!;
                                return _buildDateSection(
                                    date, shiftsForDate, colorScheme);
                              },
                            ),
                ),
              )
            ],
          )),
    );
  }

  Widget _buildLegendItem(String status, String label, ColorScheme colorScheme,Color? color) {
    bool isSelected = controller.selectedFilter.value == status;

    return GestureDetector(
      onTap: () => controller.updateFilter(status),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w,vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: isSelected
              ? []
              : [
            BoxShadow(
              color: colorScheme.shadow,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            if (color != null) ...[
              CircleAvatar(
                radius: 6, // Small circle size
                backgroundColor: color ?? Colors.transparent,
              ),
              const SizedBox(width: 8), // Space between circle and text
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(
      String date, List shiftsForDate, ColorScheme colorScheme) {
    final weekday = DateFormat('EEEE').format(DateTime.parse(date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          height: 30.h,
          padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 15.w),
          margin: EdgeInsets.symmetric(horizontal: 10.h),
          decoration: BoxDecoration(
            color: colorScheme.onSecondaryContainer,
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$weekday, ${DateFormat('d MMMM').format(DateTime.parse(date))}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.only(top: 5.h),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shiftsForDate.length,
          itemBuilder: (context, formIndex) {
            final shift = shiftsForDate[formIndex];
            return _buildShiftCard(context, shift, colorScheme);
          },
        ),
      ],
    );
  }

  Widget _buildShiftCard(
    BuildContext context,
    Map<String, dynamic> shift,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
      child: RosterShiftTile(shiftData: shift),
    );
  }
}
