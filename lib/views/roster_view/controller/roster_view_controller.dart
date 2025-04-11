import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:intl/intl.dart';
import '../../../utils/api.dart';
import '../../../utils/prefs.dart';

class RosterViewController extends GetxController {
  var shifts = <Map<String, dynamic>>[].obs;
  var filteredShifts = <Map<String, dynamic>>[].obs;
  var clientId = Prefs.getClientID();
  RxBool isLoading = false.obs;

  // Date Range Filtering
  var selectedDateFrom = DateTime.now().subtract(const Duration(days: 7)).obs;
  var selectedDateTo = DateTime.now().add(const Duration(days: 7)).obs;

  // Status Filtering
  var selectedFilter = "All".obs; // Default: Show all shifts

  // Search Controller
  TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // _fetchPrefs();
    fetchShifts();
  }

  Future<void> fetchShifts() async {
    isLoading(true);
    try {
      final results = await Api.get('getApprovedShiftsByClientID/${clientId}');
      log(results.toString());
      log(clientId.toString());
      if (results['data'] is List) {
        shifts.value = List<Map<String, dynamic>>.from(results['data']);
        filteredShifts.assignAll(shifts);
      } else {
        log('Error: API did not return a list');
      }
    } catch (e) {
      log('Error fetching shifts: $e');
    } finally {
      isLoading(false);
    }
  }

  // void _fetchPrefs() async {
  //   isLoading(true);
  //   try {
  //     final id = await Prefs.getClientID();
  //     if (id != null) {
  //       clientId.value = id;
  //     }
  //   } catch (e) {
  //     log('Error fetching client ID: $e');
  //   } finally {
  //     isLoading(false);
  //   }
  // }

  // Group shifts by date and apply selected filter
  Map<String, List<Map<String, dynamic>>> get groupedShifts {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var shift in filteredShifts) {
      String shiftStatus = shift['ShiftStatus'] ?? "";
      if (selectedFilter.value != "All" && shiftStatus != selectedFilter.value) {
        continue; // Skip if it doesn't match the filter
      }

      String dateKey =DateFormat('yyyy-MM-dd').format(DateTime.parse(shift['ShiftStart']).toLocal());
      grouped.putIfAbsent(dateKey, () => []).add(shift);
    }

    return grouped;
  }

  // Sorting Dates for Display
  List<String> get sortedDates {
    return groupedShifts.keys.toList()..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
  }

  // Filter shifts based on date range
  void filterShifts() {
    DateTime from = selectedDateFrom.value;
    DateTime to = selectedDateTo.value;

    filteredShifts.value = shifts.where((shift) {
      DateTime shiftDate = DateTime.parse(shift['ShiftStart']).toLocal();
      return shiftDate.isAfter(from.subtract(const Duration(days: 1))) &&
          shiftDate.isBefore(to.add(const Duration(days: 1)));
    }).toList();
  }

  // Search shifts by client name
  void searchShifts(String query) {
    if (query.isEmpty) {
      filteredShifts.assignAll(shifts);
    } else {
      filteredShifts.value = shifts.where((shift) {
        return shift.values.any((value) {
          if (value is String) {
            return value.toLowerCase().contains(query.toLowerCase());
          }
          return false;
        });

      }).toList();
    }
  }

  // Update filter
  void updateFilter(String status) {
    selectedFilter.value = status;
  }

  // Get formatted date range
  String getFormattedDateRange() {
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(selectedDateFrom.value)} - ${formatter.format(selectedDateTo.value)}';
  }

  // Update date range
  void updateDateRange(DateTime from, DateTime to) {
    selectedDateFrom.value = from;
    selectedDateTo.value = to;
    filterShifts();
  }

  void clearSearch() {
    searchController.clear();
    filteredShifts.clear();
  }
}
