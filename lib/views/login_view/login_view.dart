import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../utils/common_widgets/common_button.dart';
import '../../utils/common_widgets/common_textfield.dart';
import 'controller/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.tertiary,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          final logoHeight = totalHeight * 0.35;

          return Stack(
            children: [
              // Top logo area
              Container(
                height: logoHeight,
                width: double.infinity,
                color: colorScheme.tertiary,
                alignment: Alignment.center,
                child: Container(
                  height: 130.h,
                  width: 130.w,
                  padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo_mosCheckIn.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Login form area
              DraggableScrollableSheet(
                initialChildSize: 0.65,
                minChildSize: 0.65,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 20.h),
                          child: Obx(() {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Log in",
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                SizedBox(height: 50.h),

                                // Before "Check Company" is pressed
                                if (!controller.isCompanyChecked.value) ...[
                                  CommonTextField(
                                    label: "Company Name",
                                    controller:
                                    controller.companyNameController,
                                    hintText: "Company Name",
                                    onChanged: (value) =>
                                        controller.company(value),
                                  ),
                                  SizedBox(height: 4.h),
                                  CommonTextField(
                                    label: "Email",
                                    controller: controller.emailController,
                                    hintText: "Email",
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (value) => controller
                                        .email(value), // Sync with RxString
                                  ),
                                  SizedBox(height: 30.h),
                                  CommonButton(
                                    text: "Check Company",
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.checkCompany,
                                    isSaving: controller.isLoading.value,
                                  )
                                ] else ...[
                                  CommonTextField(
                                    label: "Password",
                                    controller: controller.passwordController,
                                    hintText: "Password",
                                    isPassword : true,
                                    onChanged: (value) => controller
                                        .password(value), // Sync with RxString
                                  ),
                                  SizedBox(height: 4.h),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        Obx(
                                              () => Checkbox(
                                            value: controller
                                                .isPrivacyPolicyAgreed.value,
                                            onChanged: (value) => controller
                                                .isPrivacyPolicyAgreed(value!),
                                            activeColor: colorScheme.primary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: controller.openPrivacyPolicy,
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'Agree to ',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400,
                                                color: colorScheme.outline,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.blue,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 30.h),
                                  CommonButton(
                                    text: "Login",
                                    onPressed:
                                    controller.isPrivacyPolicyAgreed.value
                                        ? controller.isLoading.value
                                        ? null
                                        : controller.login
                                        : null,
                                    isSaving: controller.isLoading.value,
                                  ),
                                ],
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
