import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mos_checkin/views/home_view/widgets/menu_popup.dart';
import 'package:mos_checkin/views/home_view/widgets/today_shift_container.dart';
import 'package:mos_checkin/views/home_view/widgets/weather_widget.dart';

import '../../utils/common_widgets/common_button.dart';
import '../../utils/common_widgets/common_dialog.dart';
import 'controller/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WillPopScope(
      onWillPop: () async {
        bool? exitConfirmed = await showDialog(
          context: context,
          builder: (context) => CommonDialog(
            title: 'Exit?',
            message: 'Are you sure you want to exit the application?',
            confirmText: 'Exit',
            onConfirm: () {
              SystemNavigator.pop();
            },
          ),
        );
        return exitConfirmed ?? false;
      },
      child: Scaffold(
        backgroundColor: colorScheme.onPrimary,
        body: Obx(() {
          return RefreshIndicator(
            onRefresh: controller.onRefresh,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _appBar(colorScheme, context),
                        Column(
                          children: [
                            controller.showWeather.value
                                ? const WeatherWidget()
                                : const SizedBox.shrink(),
                            SizedBox(height: 8.h),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 8.h),
                              width: 330.w,
                              padding: EdgeInsets.only(top: 8.h),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF5F6FF),
                                    Color(0xFFEFF1FF)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow
                                        .withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w),
                                    child: Row(
                                      children: [
                                        _buildRoundIcon(
                                          colorScheme,
                                          'assets/icons/calendar.png',
                                          size: 14.sp,
                                          padding: 8.sp,
                                          backgroundColor: colorScheme
                                              .primary
                                              .withOpacity(0.15),
                                        ),
                                        SizedBox(width: 10.w),
                                        Text(
                                          "Approved Shifts",
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  ApproveShiftContainer(
                                    colorScheme: colorScheme,
                                    controller: controller,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _shiftRequestButton(colorScheme, context),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Builds the circular icon widget used in the header row.
  Widget _buildRoundIcon(
      ColorScheme colorScheme,
      String iconPath, {
        double size = 18,
        double padding = 7,
        Color? backgroundColor,
      }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        iconPath,
        width: size,
        height: size,
        color: colorScheme.primary,
      ),
    );
  }

  // Widget _buildRefreshButton(ColorScheme colorScheme) {
  //   return InkWell(
  //     onTap: () {
  //       controller.onRefresh();
  //     },
  //     borderRadius: BorderRadius.circular(20.r),
  //     child: Container(
  //       padding: EdgeInsets.all(8.r),
  //       decoration: BoxDecoration(
  //         color: colorScheme.primary.withOpacity(0.12),
  //         shape: BoxShape.circle,
  //       ),
  //       child: Icon(
  //         Icons.refresh_rounded,
  //         size: 20.r,
  //         color: colorScheme.primary,
  //       ),
  //     ),
  //   );
  // }

  void _showCustomMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Menu",
      barrierColor: Colors.transparent,
      pageBuilder: (context, anim1, anim2) {
        return const MenuPopup();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }

  Widget _appBar(ColorScheme colorScheme, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Column(
        children: [
          SizedBox(height: 36.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            color: colorScheme.onPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    _showCustomMenu(context);
                  },
                  child: Image.asset(
                    'assets/icons/menu.png',
                    width: 20.w,
                    height: 20.h,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome,",
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      controller.firstName.value,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // _buildRefreshButton(colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shiftRequestButton(ColorScheme colorScheme, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: CommonButton(
        text: 'Request Shift',
        onPressed: () {
          controller.handleRequestShift();
        },
      ),
    );
  }
}