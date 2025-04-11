import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/common_widgets/common_app_bar.dart';
import '../../../utils/common_widgets/common_button.dart';
import '../../../utils/common_widgets/common_date_picker.dart';
import '../../../utils/common_widgets/common_dropdown.dart';
import '../../../utils/common_widgets/common_error_widget.dart';
import '../../../utils/common_widgets/common_textfield.dart';
import '../controller/form_controller.dart';
import '../controller/form_detail_controller.dart';

class FormDetailView extends StatefulWidget {
  final int formId;
  final bool isCompleted;

  const FormDetailView({
    super.key,
    required this.formId,
    required this.isCompleted,
  });

  @override
  State<FormDetailView> createState() => _FormDetailViewState();
}

class _FormDetailViewState extends State<FormDetailView> {
  // Delete any previous instance so the new type is used.
  @override
  void initState() {
    super.initState();
    Get.delete<FormDetailController>(force: true);
    _initControllers();
    // Fetch data based on the form completion status
    log('Fetching form details: ${widget.isCompleted}');
    if (widget.isCompleted) {
      log('Fetching completed form data');
      controller.fetchCompletedFormData(widget.formId.toString());
    } else {
      controller.fetchFormInstance(widget.formId.toString());
    }
  }

  late final FormDetailController controller;
  final FormController formController = Get.find<FormController>();

  void _initControllers() {
    controller = Get.put<FormDetailController>(FormDetailController());
  }

  Widget _buildEditableFormFields() {
    final colorScheme = Theme.of(context).colorScheme;

    List<Widget> formWidgets = [];
    for (var field in controller.formData['template']['fields']) {
      final fieldKey = field['Name'] as String;
      final fieldType = field['Type'];
      final fieldLabel = field['Label'] == '' ? null : field['Label'];
      final fieldPlaceholder =
      field['Placeholder'] == '' ? null : field['Placeholder'];
      final fieldRequired = field['Required'] == true;

      Widget fieldWidget;

      switch (fieldType) {
        case 'text':
          fieldWidget = CommonTextField(
            label: fieldLabel,
            hintText: fieldPlaceholder ?? fieldLabel,
            onChanged: (value) {
              controller.fieldValues[fieldKey] = value;
            },
            validator: fieldRequired
                ? (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            }
                : null,
          );
          break;
        case 'number':
          fieldWidget = CommonTextField(
            label: fieldLabel,
            hintText: fieldPlaceholder ?? fieldLabel,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              controller.fieldValues[fieldKey] = value; // Use String key
            },
            validator: fieldRequired
                ? (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            }
                : null,
          );
          break;
        case 'select':
          List<String> options = [];
          if (field['Options'] != null) {
            options = (field['Options'] as String)
                .split(',')
                .map((e) => e.trim())
                .toList();
          }
          fieldWidget = CommonDropdown(
            label: fieldLabel,
            hintText: fieldPlaceholder ?? fieldLabel,
            validator: fieldRequired
                ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an option';
              }
              return null;
            }
                : null,
            onChanged: (String? value) {
              controller.fieldValues[fieldKey] = value; // Use String key
            },
            value: controller.fieldValues[fieldKey],
            items: options,
          );
          break;
        case 'date':
          DateTime? initialDate; // Optional initialDate
          if (controller.fieldValues[fieldKey] != null) {
            try {
              initialDate = DateTime.parse(controller.fieldValues[fieldKey]);
            } catch (e) {
              log('Invalid date format in fieldValues for $fieldKey: ${controller.fieldValues[fieldKey]}');
            }
          }

          fieldWidget = CommonDatePicker(
            initialDate: initialDate,
            // Pass as nullable
            onDateChanged: (date) {
              controller.fieldValues[fieldKey] = date.toIso8601String();
              setState(() {}); // Update UI to reflect the new date
            },
            label: fieldLabel,
            hintText: initialDate == null
                ? (fieldPlaceholder ?? fieldLabel ?? 'Select a date')
                : DateFormat('yyyy-MM-dd').format(initialDate),
            // Display the selected date as hint
            readOnly: false,
            validator: fieldRequired
                ? (value) {
              if (value == null) {
                return 'Please select a date';
              }
              return null;
            }
                : null,
          );
          break;
        case 'checkbox':
          if (!controller.fieldValues.containsKey(fieldKey)) {
            controller.fieldValues[fieldKey] = false; // Use String key
          }
          fieldWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              fieldLabel == null || fieldLabel == ''
                  ? const SizedBox()
                  : Padding(
                padding:
                EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                child: Text(
                  fieldLabel ?? '',
                  style: TextStyle(
                      fontSize: 14.sp, color: colorScheme.onSurface),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                padding: EdgeInsets.only(top: 1.h, bottom: 1.h, left: 12.w),
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        controller.fieldValues[fieldKey] =
                        !(controller.fieldValues[fieldKey] as bool);
                      });
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            fieldPlaceholder ?? fieldLabel ?? '',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8, // Reduce the checkbox size
                          child: Checkbox(
                            value: controller.fieldValues[fieldKey] as bool,
                            onChanged: (value) {
                              setState(() {
                                controller.fieldValues[fieldKey] = value;
                              });
                            },
                            activeColor: colorScheme.primary,
                            materialTapTargetSize: MaterialTapTargetSize
                                .shrinkWrap, // Reduces tap area padding
                          ),
                        )
                      ],
                    )),
              ),
            ],
          );
          break;
        default:
          fieldWidget = Container();
      }
      formWidgets.add(fieldWidget);
      formWidgets.add(SizedBox(height: 10.h));
    }
    return Column(children: formWidgets);
  }

  Widget _buildReadOnlyFormFields() {
    final colorScheme = Theme.of(context).colorScheme;

    List<Widget> formFields = [];

    controller.completedFormData.forEach((key, value) {
      Widget fieldWidget;

      if (value is bool) {
        fieldWidget = Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                key, // Label text
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: 14.sp,
                ),
              ),
              Flexible(
                child: Text(
                  value ? 'Yes' : 'No',
                  style: TextStyle(
                    color: colorScheme.outline,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    overflow: TextOverflow.ellipsis,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      } else {
        String displayValue;
        if (value is String) {
          // Check if the string can be parsed as DateTime
          DateTime? dateValue;
          try {
            dateValue = DateTime.parse(value);
            displayValue = DateFormat('yyyy-MM-dd').format(dateValue);
          } catch (e) {
            dateValue = null;
            displayValue = value;
          }
        } else {
          displayValue = value.toString();
        }

        fieldWidget = Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                key, // Label text
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: 14.sp,
                ),
              ),
              Flexible(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    color: colorScheme.outline,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    overflow: TextOverflow.ellipsis,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }

      formFields.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: fieldWidget,
      ));
    });

    return Column(
      children: formFields,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (controller.errorMessage.value.isNotEmpty) {
          return Expanded(
            child: Center(
              child: CommonErrorField(
                image: 'assets/images/no_result.png',
                message: controller.errorMessage.value,
                customMessage:
                'This is the Forms Screen where you can manage forms for the client profile. From here, you can add, review, and track all necessary forms required for the client.',
              ),
            ),
          );
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                CommonAppBar(
                  title: 'Form Details',
                  iconPath: 'assets/icons/forms.png',
                  colorScheme: colorScheme,
                ),
                Container(
                  width: double.infinity,
                  margin:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Padding(
                    padding:
                    EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                    child: Column(
                      children: [
                        widget.isCompleted
                            ? Form(child: _buildReadOnlyFormFields())
                            : Form(
                          key: controller.formKey,
                          child: _buildEditableFormFields(),
                        ),
                        if (!controller.isLoading.value &&
                            controller.errorMessage.value.isEmpty &&
                            !widget.isCompleted)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: CommonButton(
                              text: 'Submit',
                              onPressed: controller.isSubmitting.value
                                  ? null
                                  : () {
                                controller.submitForm(
                                    context, widget.formId.toString());
                              },
                              isSaving: controller.isSubmitting.value,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }),
    );
  }
}
