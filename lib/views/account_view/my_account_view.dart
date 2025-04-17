import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mos_checkin/utils/common_widgets/common_textfield.dart';

import '../../shimmers/shimmer_profile_section.dart';
import '../../utils/common_widgets/common_app_bar.dart';
import '../../utils/common_widgets/common_button.dart';
import 'controller/acount_controller.dart';

class MyAccountView extends GetView<AccountController> {
  const MyAccountView({super.key});

  void showPfpDialog(ColorScheme colorScheme, BuildContext context) {
    XFile? image0;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width: 150.w,
                            child: CommonButton(
                              backgroundColor: colorScheme.error,
                              text: 'Close',
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            )),

                        SizedBox(
                          width: 150.w,
                          child: CommonButton(
                            backgroundColor: Colors.green,
                            text: 'Save',
                            onPressed: () {
                              controller.uploadPFP(image0!);
                              Get.back();
                            },
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Change Profile Picture',
                      style: TextStyle(
                        fontSize: 20,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    controller.pfp.value != null
                        ? controller.isLoading.value
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.outlineVariant,
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(
                                    // File(image0!.path),
                                    controller.pfp.value,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                        : CircleAvatar(
                            radius: 50.r,
                            backgroundColor: colorScheme.secondaryContainer,
                            child: Image.asset('assets/images/dummyUser.png'),
                          ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.camera);
                            if (image != null) {
                              setStateModal(() {
                                image0 = image;
                              });
                            }
                          },
                          child: Container(
                              width: 150.w,
                              height: 50.h,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.outlineVariant,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Take a photo',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.sp,
                                      color: colorScheme.onSecondary),
                                ),
                              )),
                        ),
                        SizedBox(
                          width: 10.w,
                        ),
                        GestureDetector(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              setStateModal(() {
                                image0 = image;
                              });
                            }
                          },
                          child: Container(
                            width: 150.w,
                            height: 50.h,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.outlineVariant,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Choose from gallery',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                    color: colorScheme.onSecondary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showEditProfileDialog(ColorScheme colorScheme, context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10.r))),
      builder: (BuildContext ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return Container(
                decoration: BoxDecoration(
                    color: colorScheme.surface, // Set the background color
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(10.r))),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 20.sp,
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                size: 24.sp, color: colorScheme.error),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CommonTextField(
                        hintText: 'Email',
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        label: 'Email',
                        validator: (value) {
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (value== null) return 'Email is required';
                          if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      CommonTextField(
                        hintText: 'Phone Number',
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        label: 'Phone Number',
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Phone number is required';
                          if (value.length < 10) return 'Phone number must be 10 digits';
                          return null;
                        },
                      ),


                      const SizedBox(height: 20),
                      CommonButton(
                        text: 'Save',
                        onPressed: () {
                          controller.editProfile(context);
                        },
                        isSaving: controller.isLoading.value,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.onPrimary,
      body: Column(
        children: [
          CommonAppBar(
            title: 'My Account',
            iconPath: 'assets/icons/account.png',
            colorScheme: colorScheme,
          ),
          SizedBox(
            height: 10.h,
          ),
          Expanded(
            child: Obx(
              () => Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 12.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 20.h,
                    ),
                    controller.isLoading.value
                        ? const ProfileSectionShimmer()
                        : _profileSection(colorScheme, context),
                    SizedBox(
                      height: 30.h,
                    ),

                    ///BIOMETRIC TAB
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          'Biometrics',
                          style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500),
                        ),
                        trailing: Obx(() => Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: controller.biometricsEnabled.value,
                                onChanged: (value) {
                                  controller.biometricsEnabled.value = value;
                                  if (value) {
                                    controller.authenticate();
                                  } else {
                                    controller.savePrefs(
                                        value, 'biometricsEnabled');
                                  }
                                },
                                activeColor: colorScheme.primary,
                              ),
                            )),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    ///WEATHER TAB
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          'Show Weather Information',
                          style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500),
                        ),
                        trailing: Obx(() => Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: controller.showWeather.value,
                                onChanged: (value) {
                                  controller.showWeather.value = value;
                                  controller.savePrefs(value, 'showWeather');
                                  log(controller.showWeather.value.toString());
                                },
                                activeColor: colorScheme.primary,
                              ),
                            )),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    ///FORGET PASSWORD BUTTON
                    CommonButton(
                      onPressed: () {
                        Get.snackbar('Forget Password',
                            'Please contact your admin to reset your password',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: colorScheme.error,
                            colorText: colorScheme.onPrimary);
                      },
                      text: 'Forget Password',
                      textColor: colorScheme.onPrimary,
                    ),
                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Image.asset(
                            'assets/icons/swap.png',
                            height: 16.h,
                            width: 16.w,
                            fit: BoxFit.contain,
                          ),
                          trailing: Container(
                              height: 24.h,
                              width: 24.w,
                              decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle),
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Icon(Icons.arrow_forward_ios,
                                      size: 14.sp,
                                      color: colorScheme.onPrimary))),
                          title: Text(
                            'Switch Company',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14.sp,
                            ),
                          ),
                          onTap: () async {
                            Get.snackbar('Switch Company',
                                'Please contact your admin to switch company',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: colorScheme.error,
                                colorText: colorScheme.onPrimary);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void showProfileDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          backgroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Choose What you want to edit',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close the dialog
                      showPfpDialog(
                          colorScheme, context); // Show profile picture dialog
                    },
                    child: Container(
                      width: 100.w,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.onSurface.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Profile Picture',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close the dialog
                      showEditProfileDialog(
                          colorScheme, context); // Show edit profile dialog
                    },
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Profile Details',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _profileSection(colorScheme, context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => showProfileDialog(context, colorScheme),
          child: Stack(
            children: [
              Container(
                height: 80.h,
                width: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outline),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: controller.pfp.isNotEmpty
                      ? Image.network(
                          controller.pfp.value,
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/dummyUser.png',
                              width: 100.w,
                              height: 100.h,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/dummyUser.png',
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 12, // Adjust size as needed
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    Icons.edit,
                    size: 14, // Adjust icon size to fit well
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          '${controller.clientData['FirstName'] ?? ''} ${controller.clientData['LastName'] ?? ''}',
          style: TextStyle(
              color: colorScheme.secondary,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        Text(controller.companyName.toString().toUpperCase(),
            style: TextStyle(
                color: colorScheme.outline,
                fontSize: 12,
                fontWeight: FontWeight.w400)),
      ],
    );
  }
}
