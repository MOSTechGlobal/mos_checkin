import 'dart:ui'; // for ImageFilter

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/common_widgets/common_dialog.dart';
import '../controller/home_controller.dart';

class MenuPopup extends StatefulWidget {
  const MenuPopup({super.key});

  @override
  State<MenuPopup> createState() => _MenuPopupState();
}

class _MenuPopupState extends State<MenuPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final HomeController homeController = Get.find<HomeController>();
  final user = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Slide in from left
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void showLogoutDialog(BuildContext context, ColorScheme colorScheme) {
    Get.dialog(
      CommonDialog(
        title: 'Sign Out',
        message: 'Are you sure you want to sign out?',
        confirmText: 'Sign Out',
        onConfirm: () async {
          await FirebaseAuth.instance.signOut();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Get.offAllNamed(AppRoutes.login);
        },
      ),
    );
  }

  void _navigateAndClose(String route) {
    _animationController.reverse().then((_) {
      Get.back(); // Close the dialog
      Get.toNamed(route); // Navigate to the new route
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: WillPopScope(
        onWillPop: () async {
          await _animationController.reverse();
          return true;
        },
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft, // Align to top-left
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildMenu(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260.w,
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: colorScheme.outlineVariant,
              blurRadius: 10.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        margin: EdgeInsets.only(left: 16.w, top: 35.h, bottom: 16.h), // Adjusted margin for left
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              _buildPopupHeader(context),
              _buildMenuItem(
                context,
                _MenuItem(
                  imagePath: 'assets/icons/account.png',
                  title: "My Account",
                  onTap: () => _navigateAndClose(AppRoutes.account),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Obx(() => Text(
                  homeController.firstName.value.isNotEmpty
                      ? homeController.firstName.value
                      : '$user',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                )),
              ),
              const Divider(),
              _buildMenuItem(
                context,
                _MenuItem(
                  imagePath: 'assets/icons/shift_req.png',
                  title: "Shift Request",
                  onTap: () => _navigateAndClose(AppRoutes.shiftRequest),
                ),
              ),
              _buildMenuItem(
                context,
                _MenuItem(
                  imagePath: 'assets/icons/forms.png',
                  title: "Forms",
                  onTap: () => _navigateAndClose(AppRoutes.formView),
                ),
              ),
              _buildMenuItem(
                context,
                _MenuItem(
                  imagePath: 'assets/icons/privacy.png',
                  title: "Privacy Policy",
                  onTap: () => _navigateAndClose(AppRoutes.privacy),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 36.w,
                  height: 36.h,
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.logout,
                      size: 16.sp,
                      color: colorScheme.error,
                    ),
                  ),
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  showLogoutDialog(context, colorScheme);
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MosCheckIn',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          GestureDetector(
            onTap: () {
              _animationController.reverse().then((_) => Get.back());
            },
            child: Icon(Icons.close, size: 22.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      leading: Container(
        width: 36.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: colorScheme.onSurface,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            item.imagePath,
            width: 16.w,
            height: 16.h,
            fit: BoxFit.contain,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      onTap: item.onTap,
    );
  }
}

class _MenuItem {
  final String imagePath;
  final String title;
  final VoidCallback onTap;

  _MenuItem({
    required this.imagePath,
    required this.title,
    required this.onTap,
  });
}