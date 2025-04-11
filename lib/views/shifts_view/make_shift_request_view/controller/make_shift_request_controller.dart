import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../../utils/api.dart';
import '../../../../utils/common_widgets/common_dialog.dart';
import '../../../../utils/prefs.dart';

class MakeShiftRequestController extends GetxController {
  var endDate = ''.obs;
  var startDate = ''.obs;
  var services = <Map<String, dynamic>>[].obs;
  var isSubmitting = false.obs;

  RxString startDateController = ''.obs;
  RxString endDateController = ''.obs;
  RxString startTimeController = ''.obs;
  RxString endTimeController = ''.obs;

  final dayController = TextEditingController();
  final occuranceController = TextEditingController();
  final repeatEveryController = TextEditingController();
  final mDayController = TextEditingController();

  RxString dayControllerText = ''.obs;
  RxString occuranceControllerText = ''.obs;
  RxString repeatEveryControllerText = ''.obs;
  RxString mDayControllerText = ''.obs;

  var isServiceLoading = false.obs;
  var shiftType = ''.obs;
  final RxList<String> shiftTypes = <String>[].obs;
  var shiftServices = <Map<String, dynamic>>[].obs;
  var filteredServices = <Map<String, dynamic>>[].obs; // Still needed for UI updates

  final searchController = TextEditingController();

  var selectedStartDate = Rxn<DateTime>();
  var selectedEndDate = Rxn<DateTime>();
  var selectedService = ''.obs;
  var selectedRecurringShiftType = 'days'.obs;

  var isRecurringShift = false.obs;
  var isDayBasedRecurrence = true.obs;
  var clientCaseManagers = {}.obs;

  Map<String, RxBool> selectedWeekDays = {
    'Mo': false.obs,
    'Tu': false.obs,
    'We': false.obs,
    'Th': false.obs,
    'Fr': false.obs,
    'Sa': false.obs,
    'Su': false.obs,
  };

  var dDay = Rxn<int>();
  var wWeek = Rxn<int>();
  var wMO = false.obs;
  var wTU = false.obs;
  var wWE = false.obs;
  var wTH = false.obs;
  var wFR = false.obs;
  var wSA = false.obs;
  var wSU = false.obs;
  var mOccurance = Rxn<int>();
  var mOccDay = Rxn<int>();
  var mOccMonth = Rxn<int>();
  var mDay = Rxn<int>();
  var mMonth = Rxn<int>();
  var type = ''.obs;

  var selectedWeekDay = 'Mon'.obs;
  var selectedOccurance = '1st'.obs;

  @override
  void onInit() async {
    final now = DateTime.now();
    startDateController.value = DateFormat('dd-MM-yyyy').format(now);
    endDateController.value = DateFormat('dd-MM-yyyy').format(now);
    startTimeController.value = DateFormat('hh:mm aa').format(now);
    endTimeController.value = DateFormat('hh:mm aa').format(now.add(const Duration(hours: 1)));
    repeatEveryController.text = '1';
    mDayController.text = '1';
    fetchClientCaseManagerData();

    // Add search listener to filter directly
    searchController.addListener(() {
      final query = searchController.text.toLowerCase();
      if (query.isEmpty) {
        filteredServices.value = shiftServices.value;
      } else {
        filteredServices.value = shiftServices.where((service) {
          final code = service['Service_Code']?.toString().toLowerCase() ?? '';
          final description = service['Description']?.toString().toLowerCase() ?? '';
          return code.contains(query) || description.contains(query);
        }).toList();
      }
      log('Filtered Services: ${filteredServices.length}');
    });

    super.onInit();
  }

  String formSentence() {
    // ... (unchanged)
    if (!isRecurringShift.value) {
      return 'This is a one-time shift on ${startDateController.value} from ${startTimeController.value} to ${endTimeController.value}.';
    } else if (selectedRecurringShiftType.value == 'days') {
      return 'This is a daily shift recurring every ${repeatEveryController.text.isEmpty ? '1' : repeatEveryController.text} day(s).';
    } else if (selectedRecurringShiftType.value == 'weeks') {
      var selectedDays = selectedWeekDays.entries
          .where((entry) => entry.value.value)
          .map((entry) => entry.key)
          .toList();
      return 'This is a weekly shift recurring every ${repeatEveryController.text} week(s) on ${selectedDays.join(', ')}.';
    } else if (selectedRecurringShiftType.value == 'months') {
      return isDayBasedRecurrence.value
          ? 'This is a monthly shift occurring on the ${mDayController.text} of every ${repeatEveryController.text} month(s).'
          : 'This is a monthly shift on the ${selectedOccurance.value} occurrence of ${selectedWeekDay.value}, every ${repeatEveryController.text} month(s).';
    }
    return '';
  }

  Future<void> fetchShiftServices(dynamic clientID, [String? shiftType]) async {
    try {
      final effectiveShiftType = shiftType ?? 'standard';
      log('Fetching shift services for ClientID: $clientID, ShiftType: $effectiveShiftType');
      final shiftServicesData = await Api.get('getServiceAsPerAgreement/$clientID/$effectiveShiftType');
      log('Shift Services Response: $shiftServicesData');

      if (shiftServicesData['data'] != null && shiftServicesData['data'].isNotEmpty) {
        shiftServices.value = (shiftServicesData['data'] as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        filteredServices.value = shiftServices.value; // Initialize filteredServices
        log('Shift Services Fetched: ${shiftServices.length}');
      } else {
        log('No shift services found for Client ID: $clientID and shift type: $effectiveShiftType');
        shiftServices.clear();
        filteredServices.clear();
      }
    } catch (e) {
      log('Error fetching shift services: $e');
      shiftServices.clear();
      filteredServices.clear();
    }
  }

  void clearSearch() {
    searchController.clear();
    filteredServices.value = shiftServices.value; // Reset to full list
  }

  void selectService(Map<String, dynamic> service) {
    selectedService.value = service['Service_Code'].toString();
    log('Selected Service: ${selectedService.value}');
  }

  String extractShiftType(String serviceCode) {
    final match = RegExp(r'_(night|public_holiday|sunday|saturday)_\d+$').firstMatch(serviceCode);
    return match?.group(1) ?? '';
  }

  Future<void> calculateShiftType(DateTime start, DateTime end) async {
    // ... (unchanged)
    shiftTypes.clear();

    bool isHoliday = await checkIfHoliday(start);
    if (isHoliday) {
      shiftTypes.add('public_holiday');
    }

    if (start.weekday == DateTime.saturday) {
      shiftTypes.add('saturday');
    } else if (start.weekday == DateTime.sunday) {
      shiftTypes.add('sunday');
    }

    final dayStart = DateTime(start.year, start.month, start.day, 6, 0);
    final dayEnd = DateTime(start.year, start.month, start.day, 18, 0);
    if (start.isAfter(dayStart) && start.isBefore(dayEnd)) {
      shiftTypes.add('standard');
    } else {
      shiftTypes.add('night');
    }

    if (shiftTypes.isEmpty) {
      shiftTypes.add('standard');
    }
  }

  Future<bool> checkIfHoliday(DateTime date) async {
    // ... (unchanged)
    final year = date.year;
    final response = await http.get(
      Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$year/AU'),
    );

    if (response.statusCode == 200) {
      final holidays = jsonDecode(response.body) as List<dynamic>;
      return holidays.any((holiday) {
        final holidayDate = DateTime.parse(holiday['date']);
        return holidayDate.year == date.year &&
            holidayDate.month == date.month &&
            holidayDate.day == date.day;
      });
    } else {
      return false;
    }
  }

  void extractData(BuildContext context, ColorScheme colorScheme) async {
    // ... (unchanged)
    dDay.value = null;
    wWeek.value = null;
    wMO.value = false;
    wTU.value = false;
    wWE.value = false;
    wTH.value = false;
    wFR.value = false;
    wSA.value = false;
    wSU.value = false;
    mOccurance.value = mOccDay.value =
        mOccMonth.value = mDay.value = mMonth.value = null;

    if (selectedRecurringShiftType.value == 'weeks') {
      wWeek.value = int.tryParse(repeatEveryController.text) ?? 1;
      wMO.value = selectedWeekDays['Mo']?.value ?? false;
      wTU.value = selectedWeekDays['Tu']?.value ?? false;
      wWE.value = selectedWeekDays['We']?.value ?? false;
      wTH.value = selectedWeekDays['Th']?.value ?? false;
      wFR.value = selectedWeekDays['Fr']?.value ?? false;
      wSA.value = selectedWeekDays['Sa']?.value ?? false;
      wSU.value = selectedWeekDays['Su']?.value ?? false;
      type.value = 'Weekly';
    }

    if (selectedRecurringShiftType.value == 'months') {
      if (isDayBasedRecurrence.value) {
        mDay.value = (int.tryParse(mDayController.text) ?? 1);
        mMonth.value = (int.parse(repeatEveryController.text));
      } else {
        mOccurance.value = _getOccuranceFromString(selectedOccurance.value);
        mOccDay.value = _getDayFromString(selectedWeekDay.value);
        mOccMonth.value = (int.parse(repeatEveryController.text));
      }
      type.value = 'Monthly';
    }

    if (selectedRecurringShiftType.value == 'days') {
      dDay.value = int.tryParse(repeatEveryController.text) ?? 1;
      type.value = 'Daily';
    }

    Map<String, dynamic> intervalData = {
      "dDay": dDay.value,
      "wWeek": wWeek.value,
      "wMO": wMO.value,
      "wTU": wTU.value,
      "wWE": wWE.value,
      "wTH": wTH.value,
      "wFR": wFR.value,
      "wSA": wSA.value,
      "wSU": wSU.value,
      "mOccurance": mOccurance.value,
      "mOccDay": mOccDay.value,
      "mOccMonth": mOccMonth.value,
      "mDay": mDay.value,
      "mMonth": mMonth.value,
      "type": type.value.toString(),
    };

    Get.dialog(
      CommonDialog(
        title: 'Make Service Request?',
        confirmText: 'Yes',
        message: formSentence(),
        onConfirm: () async {
          Get.back();

          Get.dialog(
            Dialog(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Submitting Request...',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            barrierDismissible: false,
          );

          await submitRequest(intervalData, context);

          if (Get.isDialogOpen!) {
            Get.back();
          }
        },
      ),
    );
  }

  Future<void> fetchClientCaseManagerData() async {
    // ... (unchanged)
    var clientID = await Prefs.getClientID();
    try {
      final resGeneralData =
      await Api.get('getClientCaseManagerDataById/$clientID');

      clientCaseManagers.value =
      resGeneralData['data'].isNotEmpty ? resGeneralData['data'][0] : {};

      log(clientID.toString());
      log('Client Case Manager Data: $clientCaseManagers');
    } catch (e) {
      log('Error fetching client case manager data: $e');
    }
  }

  int _getOccuranceFromString(String occurance) {
    // ... (unchanged)
    const occuranceMap = {
      '1st': 1,
      '2nd': 2,
      '3rd': 3,
      '4th': 4,
      'Last': 5,
    };
    return occuranceMap[occurance] ?? 1;
  }

  int _getDayFromString(String day) {
    // ... (unchanged)
    const dayMap = {
      'Mon': 1,
      'Tue': 2,
      'Wed': 3,
      'Thu': 4,
      'Fri': 5,
      'Sat': 6,
      'Sun': 7,
    };
    return dayMap[day] ?? 1;
  }

  Future<void> submitRequest(var intervalData, BuildContext context) async {
    // ... (unchanged)
    isSubmitting.value = true;
    if (selectedService.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a service',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isSubmitting.value = false;
      return;
    }

    String convertDateToMySQLFormat(String date) {
      DateFormat inputFormat = DateFormat('dd-MM-yyyy');
      DateFormat outputFormat = DateFormat('yyyy-MM-dd');
      DateTime parsedDate = inputFormat.parse(date);
      return outputFormat.format(parsedDate);
    }

    String convertTimeToMySQLFormat(String time) {
      DateFormat inputFormat = DateFormat('hh:mm aa');
      DateFormat outputFormat = DateFormat('HH:mm:ss');
      DateTime parsedTime = inputFormat.parse(time);
      return outputFormat.format(parsedTime);
    }

    String convertToMySQLDateTime(String date, String time) {
      DateFormat dateInputFormat = DateFormat('dd-MM-yyyy');
      DateFormat timeInputFormat = DateFormat('hh:mm aa');
      DateFormat outputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

      DateTime parsedDate = dateInputFormat.parse(date);
      DateTime parsedTime = timeInputFormat.parse(time);

      // Combine date and time into a single DateTime
      DateTime combined = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedTime.hour,
        parsedTime.minute,
        parsedTime.second,
      );

      return outputFormat.format(combined);
    }


    final user = FirebaseAuth.instance.currentUser;
    final clientID = await Prefs.getClientID();
    final jsonIntervalData = const JsonEncoder().convert(intervalData);
    Map<String, dynamic> data = {
      "ClientID": clientID,
      "ShiftDate":
      convertDateToMySQLFormat(startDateController.value).toString(),
      "ShiftEndDate":
      convertDateToMySQLFormat(endDateController.value).toString(),
      "ShiftStart":
      convertTimeToMySQLFormat(startTimeController.value).toString(),
      "ShiftEnd": convertTimeToMySQLFormat(endTimeController.value).toString(),
      "RequestDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "RequestBy": user!.email,
      "Status": "P",
      "MakerUser": user.email,
      "ServiceCode": selectedService.value,
      "IntervalData":
      isRecurringShift.value ? jsonIntervalData.toString() : null,
      'RecurrenceSentence': formSentence(),
    };
    log('Data: $data');
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final res = await Api.post('postShiftRequest', data);
      if (res != null && res['success']) {
        Future.delayed(Duration.zero, () {
          Get.snackbar('Success', 'Shift request submitted successfully',
              backgroundColor: colorScheme.primary,
              colorText: colorScheme.onPrimary);
        });
        Navigator.of(context).pop();
        await Api.post('sendNotificationToID', {
          "ids": [
            'us_${clientCaseManagers['CaseManager']}',
            'us_${clientCaseManagers['CaseManager2']}'
          ],
          "title": 'Shift Requested',
          "body": 'Client with ClientID $clientID has requested for a shift',
        });
      } else {
        Future.delayed(Duration.zero, () {
          Get.snackbar('Error', '${res['message']}',
              backgroundColor: colorScheme.error,
              colorText: colorScheme.onError);
        });
        log('Error fetching shifts: ${res['message']}');
      }
    } catch (e) {
      log('Error in submitting shift request: $e');
      Get.snackbar('Error', 'Failed to submit shift request',
          backgroundColor: colorScheme.error, colorText: colorScheme.onError);
    } finally {
      isSubmitting.value = false;
      Navigator.of(context).pop();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}