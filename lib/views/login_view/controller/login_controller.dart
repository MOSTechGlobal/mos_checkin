import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/api.dart';
import '../../../utils/common_widgets/common_dialog.dart';
import '../../../utils/prefs.dart';

class LoginController extends GetxController {
  var email = ''.obs;
  var password = ''.obs;
  var company = ''.obs;

  /// Controls the "Check Company" -> "Password" step
  var isCompanyChecked = false.obs;
  var isLoading = false.obs;
  RxString clientId = ''.obs;
  RxString clientName = ''.obs;
  var isForgotPasswordSuccess = false.obs;

  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  var isPrivacyPolicyAgreed = false.obs;

  Future<void> checkCompany() async {
    isLoading(true);

    try {
      // First: checkCompany
      await Prefs.clearCompanyName();

      final checkCompanyResponse = await Api.post(
        'checkCompany',
        {
          'companyName': company.value,
          'email': email.value,
        },
      );

      if (checkCompanyResponse == null) {
        Get.snackbar(
          'Error',
          'Null response from server for checkCompany.',
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return;
      }

      if (checkCompanyResponse['success'] != true) {
        Get.dialog(CommonDialog(
          title: 'Warning!!',
          message:
          'You are not authorized to access the system. Please contact the administration for assistance.',
          confirmText: 'Okay',onConfirm: (){Get.back();},));
        return;
      }

      await Prefs.setCompanyName(company.value);

      // Second: validateUserWithEmail
      final userValidationResponse = await Api.post(
        'validateUserWithEmail',
        {
          'email': email.value,
          'type': 'client',
          'isMobileLogin': true,
        },
      );

      if (userValidationResponse == null) {
        Get.snackbar(
          'Error',
          'Null response from server for validateUserWithEmail.',
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return;
      }

      if (userValidationResponse['success'] != true) {
        Get.snackbar(
          'Error',
          userValidationResponse['message'] ?? 'User validation failed',
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return;
      }

      // If both calls returned success, allow user to enter Password
      isCompanyChecked(true);
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred while checking company: $e',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading(false);
    }
  }

  /// Step 2: After company & user are verified, let the user log in with Firebase
  Future<void> login() async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter Password',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }

    isLoading(true);

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: email.value, password: password.value);

      // Get Firebase token and store it locally
      final String? bearer = await userCredential.user?.getIdToken();
      if (bearer == null) {
        throw FirebaseAuthException(
          code: 'invalid-token',
          message: 'Failed to get user token.',
        );
      }

      // Save to Shared Preferences
      await Prefs.setToken(bearer);
      await Prefs.setEmail(email.value);
      await Prefs.setPassword(password.value);

      await _fetchClientData();

      log('Logged in successfully, token: $bearer');

      isLoading(false);

      // Navigate to Home Page using GetX
      Get.offNamed('/home');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Get.snackbar(
          'Error',
          'No user found for that email.',
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
      } else if (e.code == 'wrong-password') {
        Get.snackbar(
          'Error',
          'Wrong password provided for that user.',
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
      } else {
        Get.snackbar(
          'Error',
          e.message ?? 'An unexpected error occurred.',
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> _fetchClientData() async {
    try {
      log('Fetching client data for email: ${email.value}');
      final responseData =
          await Api.get('getClientMasterDataByEmail/${email.value}');
      if (responseData != null && responseData['data'] != null) {
        final clientData = responseData['data'];
        clientId.value = clientData['ClientID'].toString();
        clientName.value =
            "${clientData['FirstName']} ${clientData['LastName']}";
        await Prefs.setClientID(clientId.value);
        await Prefs.setClientName(clientName.value);
        log('Client ID: ${clientId.value}, Client Name: ${clientName.value}');
      } else {
        log('No client data found for email: ${email.value}');
      }
    } catch (e) {
      log('Error fetching client data: $e');
    }
  }

  void openPrivacyPolicy() async {
    final url = Uri.parse('https://mostech.solutions/privacy-policy/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> handleForgotPassword() async {
    if (email.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address.',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }

    isLoading(true);
    try {
      final response = await Api.post('sendPasswordResetEmail', {
        'email': email.value,
      });

      if (response == null || response['success'] != true) {
        throw Exception(response?['message'] ?? 'Failed to send password reset email.');
      }

      isForgotPasswordSuccess(true);
      Get.snackbar(
        'Success',
        'Password reset email sent successfully.',
        colorText: Colors.white,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceFirst('Exception: ', ''),
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading(false);
    }
  }
}
