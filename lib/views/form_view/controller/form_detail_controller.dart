import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/api.dart';
import '../../../utils/prefs.dart';
import 'form_controller.dart';

class FormDetailController extends GetxController {
  RxMap<String, dynamic> formData = <String, dynamic>{}.obs;
  RxMap<String, dynamic> completedFormData = <String, dynamic>{}.obs;
  var errorMessage = ''.obs;
  var isLoading = true.obs;
  RxBool isSubmitting = false.obs;

  // Updated to use String keys for fieldValues.
  RxMap<String, dynamic> fieldValues = <String, dynamic>{}.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> fetchFormInstance(String formId) async {
    try {
      final response = await Api.get('getFormInstance/$formId');

      if (response == null) {
        throw Exception('API response is null');
      }
      if (response != null && response is Map<String, dynamic>) {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'];

          // Extract 'formInstance' details
          if (data['formInstance'] != null) {
            formData.value = Map<String, dynamic>.from(data['formInstance']);
          }

          // Extract 'template' details including fields
          if (data['template'] != null) {
            formData['template'] = Map<String, dynamic>.from(data['template']);
          }

          // Extract 'assignments' if available
          if (data['assignments'] != null) {
            formData['assignments'] =
                List<Map<String, dynamic>>.from(data['assignments']);
          }
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception('Response is null or not in expected format');
      }
    } catch (e) {
      log('Error fetching form instance: $e');
      errorMessage.value = 'We couldn’t load your form details just now. Try again shortly';
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchCompletedFormData(String formId) async {
    log('Fetching completed form data for form ID: $formId');
    isLoading(true);
    try {
      final response = await Api.get('getResponseDataByInstanceID/$formId');
      log("API Response: $response"); // Log full response for debugging

      if (response != null && response is Map<String, dynamic>) {
        if (response['success'] == true && response['data'] is List) {
          final dataList = List<Map<String, dynamic>>.from(response['data']);
          if (dataList.isNotEmpty) {
            completedFormData.value =
                Map<String, dynamic>.from(dataList[0]); // Take the first item
          } else {
            completedFormData.value = {}; // Empty map if no data
          }
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception('Response is null or not in expected format');
      }
    } catch (e) {
      log('Error fetching completed form data: $e');
      errorMessage.value = 'We couldn’t load your form details just now. Try again shortly';
    } finally {
      isLoading(false);
    }
  }

  void submitForm(BuildContext context, String formId) async {
    isSubmitting(true);
    if (formKey.currentState!.validate()) {
      Map<String, dynamic> responses = {};

      if (formData['template'] != null &&
          formData['template']['fields'] != null) {
        for (var field in formData['template']['fields']) {
          final fieldKey = field['Name'] as String;
          final fieldName = field['Name'];
          final fieldValue = fieldValues[fieldKey];
          responses[fieldName] = fieldValue;
        }
      } else {
        log("Error: 'template' or 'fields' is null in formData");
        Get.snackbar('Error', 'Form data is invalid',
            backgroundColor: Colors.red);
        isSubmitting(false);
        return;
      }
      final userId = await Prefs.getClientID();

      Map<String, dynamic> submissionData = {
        'formInstanceId': formId,
        'responses': responses,
        'assignedToId': userId,
        'assignedToType': 'client',
      };

      try {
        final response = await Api.post('submitFormResponse', submissionData);

        if (response != null && response['success'] == true) {
          // Show success snackbar
          Future.delayed(Duration.zero, () {
            Get.snackbar('Success', 'Form submitted successfully',
                backgroundColor: Colors.green, colorText: Colors.white);
          });

          // Get the FormController instance and trigger fetchForms
          final formController = Get.find<FormController>();
          await formController.fetchAssignedForms(); // Fetch updated forms

          // Navigate back to FormsView
          Navigator.of(context).pop();
        } else {
          throw Exception(
              'Form submission failed: ${response?['error'] ?? 'Unknown error'}');
        }
      } catch (e) {
        log('Error submitting form: $e');
        Future.delayed(Duration.zero, () {
          Get.snackbar('Error', 'Failed to submit form: $e',
              backgroundColor: Colors.red, colorText: Colors.white);
        });
      } finally {
        isSubmitting(false);
      }
    } else {
      isSubmitting(false);
    }
  }
}
