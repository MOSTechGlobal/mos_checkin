import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../utils/api.dart';
import '../../../../utils/common_widgets/common_button.dart';
import '../../../../utils/common_widgets/common_textfield.dart';
import '../../../../utils/prefs.dart';

class ShiftRequestViewController extends GetxController {
  var selectedDateFrom = DateTime.now().subtract(const Duration(days: 7)).obs;
  var selectedDateTo = DateTime.now().add(const Duration(days: 7)).obs;

  var isLoading = false.obs;

  var shiftRequests = <Map<String, dynamic>>[].obs;
  var filteredShiftRequests = <Map<String, dynamic>>[].obs;
  var selectedStatus = 'all'.obs; // Default status

  var clientId = ''.obs;

  RxList<Map<String, dynamic>> filteredShifts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    everAll([selectedDateFrom, selectedDateTo], (_) => filterShifts());
    ever(selectedStatus, (_) => filterShifts());
    fetchClientShiftRequests();
  }

  String getFormattedDateRange() {
    final formatter = DateFormat('dd MMM yyyy'); // Format: DD Month YYYY
    return '${formatter.format(selectedDateFrom.value)} - ${formatter.format(selectedDateTo.value)}';
  }

  Future<void> fetchClientShiftRequests() async {
    final clientId = await Prefs.getClientID();
    isLoading.value = true;

    try {
      final response = await Api.get('getShiftRequestByClientId/$clientId');
      if (response.containsKey('data')) {
        shiftRequests.value = List<Map<String, dynamic>>.from(response['data']);
        log('Shift requests: $shiftRequests');
      } else {
        shiftRequests.clear();
      }
      filterShifts();
    } catch (e) {
      log('Error fetching shift requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get sortedDates {
    return groupedShiftRequests.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
  }

  Map<String, List<Map<String, dynamic>>> get groupedShiftRequests {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var request in filteredShiftRequests) {
      final requestDate = request['ShiftDate'] as String?;
      if (requestDate == null) continue;

      final formattedDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.parse(requestDate).toLocal());

      if (!grouped.containsKey(formattedDate)) {
        grouped[formattedDate] = [];
      }
      grouped[formattedDate]!.add(request);
    }

    return grouped;
  }

  void filterShifts() {
    filteredShiftRequests.assignAll(
      shiftRequests.where((note) {
        final createdOnString = note['RequestDate'] as String?;
        if (createdOnString == null) return false;

        final createdOn = DateTime.tryParse(createdOnString);
        if (createdOn == null) {
          log('Error parsing date: $createdOnString');
          return false;
        }

        // Date range filter
        final isWithinDateRange = (createdOn.isAfter(selectedDateFrom.value) ||
            createdOn.isAtSameMomentAs(selectedDateFrom.value)) &&
            createdOn.isBefore(selectedDateTo.value.add(const Duration(days: 1)));

        // Status filter
        final formStatus = (note['Status'] ?? '').toLowerCase();
        final matchesStatus = selectedStatus.value.toLowerCase() == 'all' ||
            formStatus == selectedStatus.value.toLowerCase();

        return isWithinDateRange && matchesStatus;
      }).toList(),
    );
    log('Filtered shifts: ${filteredShiftRequests.length} items with status: ${selectedStatus.value}');
  }

  Future<void> cancelShiftRequest(shiftRequest, BuildContext context) async {
    String reason = '';
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal during processing
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          'Cancel Shift Request',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: colorScheme.onSurface.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: isProcessing
                              ? null
                              : () => Navigator.pop(context),
                          child: Container(
                            width: 25,
                            height: 25,
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
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Please provide a reason for cancelling the shift request',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CommonTextField(
                              hintText: 'Reason',
                              onChanged: (value) => reason = value,
                              enabled: !isProcessing),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: CommonButton(
                            text: 'Cancel',
                            onPressed: isProcessing
                                ? null
                                : () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: CommonButton(
                            text: 'OK',
                            backgroundColor: colorScheme.error,
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    setState(() {
                                      isProcessing = true;
                                    });
                                    log('Initiating shift cancellation for ID: ${shiftRequest['ID']}');

                                    final Map<String, dynamic> data = {
                                      'Status': 'C',
                                      'StatusReason': 'by client: $reason',
                                      'UpdateUser': FirebaseAuth
                                          .instance.currentUser?.email,
                                    };

                                    try {
                                      final id = shiftRequest['ID'];
                                      log('Sending cancellation request to API with data: $data');
                                      final response = await Api.put(
                                          'updateShiftRequestStatus/$id', data);

                                      if (response['success']) {
                                        log('Shift request cancelled successfully for ID: $id');
                                        await fetchClientShiftRequests(); // Refresh list after cancel
                                        Navigator.pop(context); // Close dialog
                                        Navigator.pop(context); // Close dialog
                                        Future.delayed(Duration.zero, () {
                                          Get.snackbar(
                                            'Shift Request Cancelled',
                                            'Shift request cancelled successfully',
                                            backgroundColor: colorScheme.primary
                                                .withOpacity(0.5),
                                            colorText: colorScheme.onPrimary,
                                            duration:
                                                const Duration(seconds: 3),
                                          );
                                        });
                                      } else {
                                        log('Error cancelling shift request: ${response['message']}');
                                        Future.delayed(Duration.zero, () {
                                          Get.snackbar(
                                            'Failed to cancel shift request',
                                            'Failed to cancel shift request: ${response['message']}',
                                            backgroundColor: colorScheme.error
                                                .withOpacity(0.9),
                                            colorText: colorScheme.onPrimary,
                                            duration:
                                                const Duration(seconds: 3),
                                          );
                                        });
                                      }
                                    } catch (e) {
                                      log('Exception while cancelling shift request: $e',
                                          error: e);
                                      Future.delayed(Duration.zero, () {
                                        Get.snackbar(
                                          'Error',
                                          'An error occurred: $e',
                                          backgroundColor: colorScheme.error
                                              .withOpacity(0.9),
                                          colorText: colorScheme.onPrimary,
                                          duration: const Duration(seconds: 3),
                                        );
                                      });
                                    } finally {
                                      if (context.mounted) {
                                        setState(() {
                                          isProcessing = false;
                                        });
                                      }
                                    }
                                  },
                            isSaving: isProcessing,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
