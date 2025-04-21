import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mos_checkin/views/home_view/controller/weather_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_routes.dart';
import '../../../utils/api.dart';
import '../../../utils/prefs.dart';
import '../../../utils/upgrader_service.dart';

class HomeController extends GetxController {
  String? userName;
  RxString firstName = ''.obs;
  RxString userEmail = ''.obs;

  var shifts = <dynamic>[].obs;
  var services = <Map<String, dynamic>>[].obs;
  var shiftsRequested = <dynamic>[].obs;
  var clientData = <dynamic>[].obs;
  var client = {}.obs;
  int? clientID = 0;

  final Set<String> selectedSegment = {'Today'};

  var errorMessage = ''.obs;
  var isLoading = true.obs;
  var isServiceLoading = false.obs;
  var showWeather = true.obs;
  var isApprovedShiftsLoading = true.obs;
  final RxList<dynamic> displayApprovedShifts = <dynamic>[].obs;

  var currentDate = DateTime.now().toUtc();
  final UpgraderService _upgraderService = UpgraderService();

  @override
  Future<void> onInit() async {
    userName = await Prefs.getClientName();
    final String? email = await Prefs.getEmail();
    userEmail.value = email ?? '';
    clientID = await Prefs.getClientID();
    firstName.value = userName?.split(' ')[0] ?? 'Guest';
    await fetchClientShifts();
    _fetchPrefs();
    // Future.delayed(3.seconds, () {
    //   fetchClientServices();
    // });

    _checkForUpdates();

    super.onInit();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> onRefresh() async {
    fetchClientShifts();
    final weatherController = Get.find<WeatherController>();
    weatherController.fetchWeatherData();
  }

  Future<void> _checkForUpdates() async {
    await _upgraderService.checkForUpdates();
  }

  Future<void> signOut(ColorScheme colorScheme, BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sign Out', style: TextStyle(color: colorScheme.error)),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: colorScheme.primary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Get.offAllNamed(AppRoutes.login); // Navigate with GetX
              },
              style: TextButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
              ),
              child: Text(
                'Sign Out',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        );
      },
    );
  }

  void _fetchPrefs() async {
    showWeather.value = await Prefs.getShowWeather();
  }

  Future<void> fetchClientShifts() async {
    isApprovedShiftsLoading.value = true;
    final user = FirebaseAuth.instance.currentUser?.email;
    if (user == null) return;

    try {
      final clientShifts = await Api.get('getShiftRequestByClientId/$clientID');
      shifts.assignAll(clientShifts['data'] ?? []);

      // Get the current date without time for comparison
      final currentDate = DateTime.now().toUtc();
      final today = DateTime(currentDate.year, currentDate.month, currentDate.day);

      // Filter shifts to include only those with Status 'A' and ShiftDate today or in the future
      displayApprovedShifts.value = shifts.where((shift) {
        // Ensure shift has Status 'A'
        if (shift['Status'] != 'A') return false;

        // Parse ShiftDate and compare
        try {
          final shiftDateStr = shift['ShiftDate'] as String?;
          if (shiftDateStr == null) return false;
          final shiftDate = DateTime.parse(shiftDateStr);
          // Compare dates without time
          final shiftDateOnly = DateTime(shiftDate.year, shiftDate.month, shiftDate.day);
          return shiftDateOnly.isAfter(today) || shiftDateOnly.isAtSameMomentAs(today);
        } catch (e) {
          log('Error parsing ShiftDate for shift ID ${shift['ID']}: $e');
          return false;
        }
      }).toList();

      log('displayApprovedShifts shifts: $displayApprovedShifts');

      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        try {
          await Api.post('upsertClientFCMToken', {
            'ClientID': clientID.toString(),
            'FCMToken': fcmToken,
          });
        } catch (e) {
          log('Error inserting FCM token: $e');
        }
      }

      if (shifts.isEmpty) {
        errorMessage.value = 'No shifts found';
      }
    } catch (e) {
      log('Error fetching client shifts: $e');
    } finally {
      isLoading.value = false;
      isApprovedShiftsLoading.value = false;
    }
  }

  void handleRequestShift() {
    Get.toNamed(
      '/makeShiftRequest',
      arguments: {
        'clientId': clientID.toString(),
        'clientName': userName,
        // 'services': services,
      },
    );
  }

  DateTime parseDateString(String dateString) {
    final formats = [
      "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      "yyyy-MM-dd'T'HH:mm:ss'Z'",
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss",
      "yyyy-MM-dd",
    ];

    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateString, true);
      } catch (e) {
        // Ignore and try the next format
      }
    }
    throw FormatException('Cannot parse date string: $dateString');
  }
}
