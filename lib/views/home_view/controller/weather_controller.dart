import 'dart:developer';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/intl.dart'; // For date formatting

class WeatherController extends GetxController {
  final String apiKey = dotenv.env['WEATHER_API_KEY']!;

  // Observables
  RxString temperature = '--'.obs;
  RxString city = '---'.obs;
  RxString icon = '01n'.obs;
  RxString description = '---'.obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString greeting = ''.obs;
  RxString formattedDate = ''.obs;
  RxString sunrise = ''.obs;
  RxString sunset = ''.obs;

  @override
  void onInit() {
    super.onInit();
    tz_data.initializeTimeZones();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Check location permissions
      bool hasPermission = await _checkAndRequestLocationPermission();
      if (!hasPermission) {
        throw 'Location permission denied';
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _fetchWeatherFromAPI(position.latitude, position.longitude);
    } catch (e) {
      log('Error fetching weather data: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchWeatherFromAPI(double latitude, double longitude) async {
    final String url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _displayWeather(data);

        // Calculate greeting and date based on timezone
        final timezone = data['timezone']; // Timezone offset in seconds
        calculateGreetingAndDate(timezone);

        // Display sunrise and sunset times
        _displaySunriseSunset(data['sys'], timezone);
      } else {
        throw 'Failed to fetch weather data';
      }
    } catch (e) {
      throw 'Error fetching weather data from API: $e';
    }
  }

  void _displayWeather(Map<String, dynamic> data) {
    city.value = data['name'] ?? '---';
    icon.value = data['weather'][0]['icon'] ?? '01n';
    description.value = data['weather'][0]['description'] ?? '---';
    temperature.value = (data['main']['temp']?.round() ?? '--').toString();
  }

  void calculateGreetingAndDate(int timezoneOffset) {
    // Get the current UTC time
    DateTime nowUtc = DateTime.now().toUtc();

    // Calculate the local time based on the timezone offset
    DateTime localTime = nowUtc.add(Duration(seconds: timezoneOffset));

    // Determine the greeting based on the local hour
    int hour = localTime.hour;
    if (hour >= 5 && hour < 12) {
      greeting.value = 'Good Morning';
    } else if (hour >= 12 && hour < 18) {
      greeting.value = 'Good Afternoon';
    } else {
      greeting.value = 'Good Evening';
    }

    // Format the local date
    formattedDate.value = DateFormat('EEEE, dd MMM').format(localTime);
  }

  void _displaySunriseSunset(Map<String, dynamic> sys, int timezoneOffset) {
    // Convert sunrise and sunset timestamps to DateTime
    int sunriseTimestamp = sys['sunrise'];
    int sunsetTimestamp = sys['sunset'];

    DateTime sunriseUtc = DateTime.fromMillisecondsSinceEpoch(sunriseTimestamp * 1000, isUtc: true);
    DateTime sunsetUtc = DateTime.fromMillisecondsSinceEpoch(sunsetTimestamp * 1000, isUtc: true);

    // Adjust for the timezone offset
    DateTime sunriseLocal = sunriseUtc.add(Duration(seconds: timezoneOffset));
    DateTime sunsetLocal = sunsetUtc.add(Duration(seconds: timezoneOffset));

    // Format the times
    sunrise.value = DateFormat('hh:mm a').format(sunriseLocal);
    sunset.value = DateFormat('hh:mm a').format(sunsetLocal);
  }

  Future<bool> _checkAndRequestLocationPermission() async {
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      PermissionStatus result = await Permission.location.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      // await openAppSettings(); // Redirect to app settings
      return false;
    }
    return false;
  }
}
