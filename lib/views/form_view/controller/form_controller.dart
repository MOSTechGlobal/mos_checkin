import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../utils/api.dart';
import '../../../utils/prefs.dart';

class FormController extends GetxController {
  var allForms = <Map<String, dynamic>>[].obs;
  var filteredForms = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  // New reactive map to store a single form's detail data
  var formData = <String, dynamic>{}.obs;

  Rx<DateTime> selectedDateFrom =
      DateTime.now().subtract(const Duration(days: 7)).obs;
  Rx<DateTime> selectedDateTo = DateTime.now().add(const Duration(days: 7)).obs;

  var selectedStatus = 'all'.obs; // Default status

  //search fields
  var searchText =''.obs;
  var searchController = TextEditingController();
  @override
  void onInit() {
    super.onInit();
    fetchAssignedForms();
    searchController.addListener((){
      searchText.value = searchController.text;
      filterForms();
    });
  }

  /// Fetches all completed forms from the API
  Future<void> fetchAssignedForms() async {
    allForms.clear();
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final userId = await Prefs.getClientID();

      final response = await Api.get('getAssignedFormsByClientId/$userId');
      log('Response: $response');

      if (response['success'] == true && response['data'] is List) {
        allForms.value = List<Map<String, dynamic>>.from(response['data']);

        if (allForms.isEmpty) {
          errorMessage.value = 'No forms available.';
        }
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      errorMessage.value =
          'Failed to fetch forms. Please check your network connection.';
      allForms.clear();
      filteredForms.clear();
    } finally {
      isLoading.value = false;
      filterForms();
    }
  }

  /// Filters forms based on the search query and selected date range
  void filterForms() {
    filteredForms.value = allForms.where((form) {
      final searchQuery = searchText.value.toLowerCase();
      final formName = (form['TemplateName'] ?? form['Name'] ?? '').toLowerCase();
      final matchesSearch = searchQuery.isEmpty || formName.contains(searchQuery);
      final dateField =
          form.containsKey('AssignedDate') ? 'AssignedDate' : 'CreatedAt';
      if (form[dateField] == null) return false;

      DateTime? formDate;
      try {
        formDate = DateTime.parse(form[dateField]!);
      } catch (e) {
        log('Invalid date format: ${form[dateField]}');
        return false;
      }

      final isWithinDateRange = formDate.isAfter(selectedDateFrom.value) &&
          formDate.isBefore(selectedDateTo.value);

      // If status is 'all', skip status filtering; otherwise, match the status
      final formStatus = (form['Status'] ?? '').toLowerCase();
      final matchesStatus = selectedStatus.value.toLowerCase() == 'all' ||
          formStatus == selectedStatus.value.toLowerCase();

      return isWithinDateRange && matchesStatus && matchesSearch;
    }).toList();
  }

  /// Returns the formatted date range
  String getFormattedDateRange() {
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(selectedDateFrom.value)} - ${formatter.format(selectedDateTo.value)}';
  }

  /// Groups the filtered forms by their dates
  Map<String, List<Map<String, dynamic>>> get groupedForms {
    if (filteredForms.isEmpty) {
      return {};
    }

    return {
      for (var form in filteredForms)
        DateFormat('yyyy-MM-dd')
                .format(DateTime.parse(form['AssignedDate']).toLocal()):
            filteredForms
                .where((f) =>
                    DateFormat('yyyy-MM-dd')
                        .format(DateTime.parse(f['AssignedDate']).toLocal()) ==
                    DateFormat('yyyy-MM-dd')
                        .format(DateTime.parse(form['AssignedDate']).toLocal()))
                .toList()
    };
  }

  /// Returns sorted dates from the grouped forms
  List<String> get sortedDates {
    if (groupedForms.isEmpty) return [];
    return groupedForms.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
  }

  void clearSearch() {
    searchController.clear();
    searchText.value = '';
    filterForms();
  }
}
