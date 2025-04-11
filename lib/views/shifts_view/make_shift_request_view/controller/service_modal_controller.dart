// import 'dart:convert';
//
// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
//
// class ServiceModalController extends GetxController {
//   final RxSet<Map<String, dynamic>> allServices;
//   final RxSet<Map<String, dynamic>> currentServices;
//   final String agreementCode;
//   final Function(Set<Map<String, dynamic>>) onAddServices;
//   final DateTime startDate;
//   final String startTime;
//
//   ServiceModalController({
//     required this.startDate,
//     required this.startTime,
//     required Set<Map<String, dynamic>> allServices,
//     required Set<Map<String, dynamic>> currentServices,
//     required this.agreementCode,
//     required this.onAddServices,
//   })  : allServices = allServices.obs,
//         currentServices = currentServices.obs;
//
//   final RxSet<Map<String, dynamic>> filteredServices =
//       <Map<String, dynamic>>{}.obs;
//   final Rxn<Map<String, dynamic>> selectedService = Rxn<Map<String, dynamic>>();
//   final searchController = TextEditingController();
//   final RxList<String> shiftTypes = <String>[].obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//
//     if (currentServices.isNotEmpty) {
//       selectedService.value = currentServices.first;
//     }
//
//     _initShiftType();
//
//     searchController.addListener(() {
//       // filterServices(searchController.text);
//     });
//   }
//
//   Future<void> _initShiftType() async {
//     final hour = int.tryParse(startTime.split(":")[0]) ?? 0;
//     final minute = int.tryParse(startTime.split(":")[1]) ?? 0;
//
//     final start = DateTime(
//       startDate.year,
//       startDate.month,
//       startDate.day,
//       hour,
//       minute,
//     );
//
//     final end = start.add(const Duration(hours: 1));
//     // await calculateShiftType(start, end);
//     //
//     // filterServices('');
//   }
//
//   // void filterServices(String query) {
//   //   filteredServices.clear();
//   //   final queryLower = query.toLowerCase();
//   //
//   //   final filtered = allServices.where((service) {
//   //     final code = service['Service_Code']?.toString().toLowerCase() ?? '';
//   //     final description = service['Description']?.toString().toLowerCase() ?? '';
//   //     final matchesQuery =
//   //         code.contains(queryLower) || description.contains(queryLower);
//   //
//   //     final type = extractShiftType(code);
//   //
//   //     return matchesQuery && shiftTypes.contains(type);
//   //   });
//   //
//   //   filteredServices.addAll(filtered);
//   // }
//   //
//   // String extractShiftType(String serviceCode) {
//   //   final match = RegExp(r'_(night|public_holiday|sunday|saturday)_\d+$')
//   //       .firstMatch(serviceCode);
//   //   return match?.group(1) ?? '';
//   // }
//   //
//   //
//   // Future<void> calculateShiftType(DateTime start, DateTime end) async {
//   //   shiftTypes.clear();
//   //
//   //   bool isHoliday = await checkIfHoliday(start);
//   //   if (isHoliday) {
//   //     shiftTypes.add('public_holiday');
//   //   }
//   //
//   //   if (start.weekday == DateTime.saturday) {
//   //     shiftTypes.add('saturday');
//   //   } else if (start.weekday == DateTime.sunday) {
//   //     shiftTypes.add('sunday');
//   //   }
//   //
//   //   final dayStart = DateTime(start.year, start.month, start.day, 6, 0);
//   //   final dayEnd = DateTime(start.year, start.month, start.day, 18, 0);
//   //   if (start.isAfter(dayStart) && start.isBefore(dayEnd)) {
//   //     shiftTypes.add('standard');
//   //   } else {
//   //     shiftTypes.add('night');
//   //   }
//   //
//   //   // Just in case nothing got added
//   //   if (shiftTypes.isEmpty) {
//   //     shiftTypes.add('standard');
//   //   }
//   // }
//   //
//   // Future<bool> checkIfHoliday(DateTime date) async {
//   //   final year = date.year;
//   //   final response = await http.get(
//   //     Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$year/AU'),
//   //   );
//   //
//   //   if (response.statusCode == 200) {
//   //     final holidays = jsonDecode(response.body) as List<dynamic>;
//   //     return holidays.any((holiday) {
//   //       final holidayDate = DateTime.parse(holiday['date']);
//   //       return holidayDate.year == date.year &&
//   //           holidayDate.month == date.month &&
//   //           holidayDate.day == date.day;
//   //     });
//   //   } else {
//   //     return false;
//   //   }
//   // }
//
//   void selectService(Map<String, dynamic> service) {
//     selectedService.value = service;
//   }
//
//   void saveSelectedService() {
//     if (selectedService.value != null) {
//       onAddServices({selectedService.value!});
//     }
//   }
//
//   void clearSearch() {
//     searchController.clear();
//     // filterServices('');
//   }
//
//   @override
//   void onClose() {
//     searchController.dispose();
//     super.onClose();
//   }
// }