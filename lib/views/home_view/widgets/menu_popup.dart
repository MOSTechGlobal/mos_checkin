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

class _MenuPopupState extends State<MenuPopup> with SingleTickerProviderStateMixin {
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
      child: GestureDetector(
        onTap: () {
          _animationController.reverse().then((_) => Get.back());
        },
        behavior: HitTestBehavior.opaque,
        child: WillPopScope(
          onWillPop: () async {
            await _animationController.reverse();
            return true;
          },
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
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
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final menuItems = [
      _MenuItem(
        imagePath: 'assets/icons/account.png',
        title: 'My Account',
        onTap: () => _navigateAndClose(AppRoutes.account),
      ),
      _MenuItem(
        imagePath: 'assets/icons/shift_req.png',
        title: 'Shift Request',
        onTap: () => _navigateAndClose(AppRoutes.shiftRequest),
      ),
      _MenuItem(
        imagePath: 'assets/icons/forms.png',
        title: 'Forms',
        onTap: () => _navigateAndClose(AppRoutes.formView),
      ),
      _MenuItem(
        imagePath: 'assets/icons/privacy.png',
        title: 'Privacy Policy',
        onTap: () => _navigateAndClose(AppRoutes.privacy),
      ),
      _MenuItem(
        imagePath: 'assets/icons/chatting.png',
        title: 'Chatting Home',
        onTap: () => _navigateAndClose(AppRoutes.chattingHome),
      ),
    ];

    return GestureDetector(
      onTap: () {},
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280.w,
          decoration: BoxDecoration(
            color: colorScheme.onPrimary,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.outlineVariant.withOpacity(0.3),
                blurRadius: 15.r,
                spreadRadius: 2.r,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          margin: EdgeInsets.only(top: 35.h, bottom: 16.h),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPopupHeader(context),
                const Divider(height: 1, thickness: 1),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Obx(() => Text(
                    homeController.userEmail.value.isNotEmpty
                        ? homeController.userEmail.value
                        : '$user',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )),
                ),
                ...menuItems.map((item) => _buildMenuItem(context, item)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const Divider(),
                ),
                _buildLogoutTile(context),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.h,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.menu,
                  size: 22.sp,
                  color: colorScheme.outline,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'MosCheckIn',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              _animationController.reverse().then((_) => Get.back());
            },
            icon: Icon(Icons.close, size: 22.sp),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceVariant,
              padding: EdgeInsets.all(8.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12.r),
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: Colors.transparent,
            border: Border.all(
              color: colorScheme.surfaceContainerHighest,
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.surface.withOpacity(0.05),
                spreadRadius: 1.r,
                blurRadius: 3.r,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.h,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.all(8.r),
                child: Center(
                  child: Image.asset(
                    item.imagePath,
                    width: 22.w,
                    height: 22.h,
                    fit: BoxFit.contain,
                    color: colorScheme.outline,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24.sp,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showLogoutDialog(context, colorScheme),
        borderRadius: BorderRadius.circular(8.r),
        splashColor: colorScheme.error.withOpacity(0.1),
        highlightColor: colorScheme.error.withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.logout_rounded,
                    size: 18.sp,
                    color: colorScheme.error,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
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