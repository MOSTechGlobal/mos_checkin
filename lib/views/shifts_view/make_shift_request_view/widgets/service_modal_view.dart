import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/make_shift_request_controller.dart';

class ServiceModalView extends StatelessWidget {
  final Set<Map<String, dynamic>> allServices;
  final Set<Map<String, dynamic>> currentServices;
  final String agreementCode;
  final DateTime startDate; // Added startDate parameter
  final String startTime; // Added startTime parameter
  final Function(Set<Map<String, dynamic>>) onAddServices;

  const ServiceModalView({
    super.key,
    required this.allServices,
    required this.currentServices,
    required this.agreementCode,
    required this.startDate, // Nullable start date
    required this.startTime, // Nullable start time
    required this.onAddServices,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final serviceController = Get.find<MakeShiftRequestController>();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(maxHeight: 500.h),
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
                    'Select Service',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: colorScheme.onSurface,
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
              SizedBox(height: 16.h),
              // CommonSearchBar(
              //   colorScheme: colorScheme,
              //   searchController: serviceController.searchController,
              //   onChanged: (value) { // Optional: explicit filtering
              //     final query = value.toLowerCase();
              //     if (query.isEmpty) {
              //       serviceController.filteredServices.value = serviceController.shiftServices.value;
              //     } else {
              //       serviceController.filteredServices.value = serviceController.shiftServices.where((service) {
              //         final code = service['Service_Code']?.toString().toLowerCase() ?? '';
              //         final description = service['Description']?.toString().toLowerCase() ?? '';
              //         return code.contains(query) || description.contains(query);
              //       }).toList();
              //     }
              //     log('Filtered Services: ${serviceController.filteredServices.length}');
              //   },
              //   onClear: serviceController.clearSearch,
              // ),
              SizedBox(height: 8.h),
              Expanded(
                child: Obx(
                  () => serviceController.isServiceLoading.value? CircularProgressIndicator(): ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: serviceController.shiftServices.length,
                    itemBuilder: (context, index) {
                      final service =
                          serviceController.shiftServices.elementAt(index);
                      final isSelected =
                          serviceController.selectedService.value == service;
                      final backgroundColor = index % 2 == 0
                          ? colorScheme.primaryContainer
                          : colorScheme.secondaryContainer;

                      return InkWell(
                        onTap: () {
                          serviceController.selectService(service);
                          onAddServices({service});
                          Get.back();
                        },
                        child: Container(
                          margin: EdgeInsets.only(top: 6.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            border: isSelected
                                ? Border.all(
                                    color: colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service['Service_Code'] ?? 'No Code',
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      service['Description'] ??
                                          'No Description',
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 10.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface
                                            .withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: colorScheme.onSurface,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
