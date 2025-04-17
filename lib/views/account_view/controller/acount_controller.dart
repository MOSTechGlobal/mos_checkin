import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:s3_storage/s3_storage.dart';

import '../../../utils/api.dart';
import '../../../utils/prefs.dart';
import '../../home_view/controller/home_controller.dart';

class AccountController extends GetxController {
  // Reactive variables
  var showWeather = false.obs;
  var biometricsEnabled = false.obs;
  var  companyName = ''.obs;
  var  pfp = ''.obs;
  var isLoading = false.obs;

  final RxMap<dynamic, dynamic> clientData = <dynamic, dynamic>{}.obs;

  // For editing profile
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void onInit() {
    super.onInit();
    fetchPrefs();
    fetchWorkerData();
    // getPfp();
  }

  void fetchWorkerData() async {
    isLoading(true);
    try {
      final clientID = await Prefs.getClientID();
      final res = await Api.get('getClientMasterData/$clientID');
      clientData.assignAll(res['data'][0]);
      emailController.text = clientData['Email'] ?? '';
      phoneController.text = clientData['Phone'] ?? '';
      log('Client data: $clientData');
    } catch (e) {
      log('Error fetching worker data: $e');
    }finally{
      isLoading(false);
    }
  }

  void fetchPrefs() async {
    try {
      companyName.value = await Prefs.getCompanyName() ?? '';
      showWeather.value = await Prefs.getShowWeather();
      // biometricsEnabled.value = await Prefs.getBiometricsEnabled();
    } catch (e) {
      log('Error fetching preferences: $e');
    }
  }

  void savePrefs(bool value, String type) async {
    try {
      if (type == 'showWeather') {
        await Prefs.setShowWeather(value);
        showWeather.value = value;
        final homeController = Get.find<HomeController>();
        homeController.showWeather.value = value;
      } else {
        await Prefs.setBiometricsEnabled(value);
        biometricsEnabled.value = value;
      }
    } catch (e) {
      log('Error saving preferences: $e');
    }
  }

  Future<void> authenticate() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        log('Biometric authentication not available.');
        biometricsEnabled.value = false;
        Get.snackbar('Error', 'Biometric authentication not available.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        log('Biometric authentication not available.');
        biometricsEnabled.value = false;
        Get.snackbar('Error', 'Biometric authentication not available.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final isAuthenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to enable biometrics',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      biometricsEnabled.value = isAuthenticated;
      await Prefs.setBiometricsEnabled(isAuthenticated);
      log(isAuthenticated ? 'Authenticated' : 'Not authenticated');
    } catch (e) {
      log('Error authenticating: $e');
    }
  }

  void uploadPFP(XFile image) async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final company = await Prefs.getCompanyName();
      final clientID = await Prefs.getClientID();
      final extension = image.path.split('.').last;

      await s3Storage.putObject(
        'moscaresolutions',
        '$company/worker/$clientID/profile_picture/pfp.$extension',
        Stream<Uint8List>.value(Uint8List.fromList(await image.readAsBytes())),
        onProgress: (progress) => log('Progress: $progress'),
      );

      getPfp();
    } catch (e) {
      log('Error uploading document: $e');
    }
  }

  Future<void> getPfp() async {
    final possibleExtensions = ['jpg', 'png', 'jpeg', 'webp'];
    isLoading(true);
    try {
      log('Getting profile picture URL');
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final company = await Prefs.getCompanyName();
      final clientID = await Prefs.getClientID();

      for (var ext in possibleExtensions) {
        try {
          final url = await s3Storage.presignedGetObject(
            'moscaresolutions',
            '$company/worker/$clientID/profile_picture/pfp.$ext',
          );
          pfp.value = url;
          log('Profile picture URL found: $pfp');
          break;
        } catch (e) {
          log('Error getting profile picture with .$ext: $e');
        }
      }
    } catch (e) {
      log('Error getting profile picture: $e');
    }finally{
      isLoading(false
      );
    }
  }

  Future<void> editProfile(context) async {
    final clientID = await Prefs.getClientID();

    final body = {
      "WorkerID": clientID,
      "Email": emailController.text,
      "Phone": phoneController.text,
    };

    try {
      final res = await Api.post('editprofileofworker', body);
      log('Edit profile response: $res');

      if (res['success'] == true) {
        // Update reactive variables directly
        clientData['Email'] = emailController.text;
        clientData['Phone'] = phoneController.text;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        // Close the bottom sheet
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Error updating profile')),
        );
      }
    } catch (e) {
      log('Error editing profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating profile')),
      );
    }
  }

}
