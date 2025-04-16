import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/shift_request_view_controller.dart';

class FilterPopupMenu extends StatefulWidget {
  const FilterPopupMenu({super.key});

  @override
  State<FilterPopupMenu> createState() => _FilterPopupMenuState();
}

class _FilterPopupMenuState extends State<FilterPopupMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final ShiftRequestViewController controller =
  Get.find<ShiftRequestViewController>();
  final screenWidth = MediaQuery.of(Get.context!).size.width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: WillPopScope(
        onWillPop: () async {
          await _animationController.reverse();
          return true;
        },
        child: GestureDetector(
          onTap: () async {
            await _animationController.reverse();
            Get.back();
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned(
                top: 110.h,
                right: 16.w,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildMenu(context, colorScheme),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: screenWidth * 0.55,
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.98),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.08),
            width: 1,
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme),
            SizedBox(height: 8.h),
            _buildDivider(colorScheme),
            SizedBox(height: 8.h),
            _buildMenuItem(
              context,
              'All',
                  () {
                Get.back();
                controller.selectedStatus.value = 'all';
                controller.filterShifts();
              },
              colorScheme,
              'all',
              Icons.filter_list_rounded,
              colorScheme.primary,
            ),
            _buildMenuItem(
              context,
              'Approved',
                  () {
                Get.back();
                controller.selectedStatus.value = 'A';
                controller.filterShifts();
              },
              colorScheme,
              'A',
              Icons.check_circle_rounded,
              Colors.green,
            ),
            _buildMenuItem(
              context,
              'Pending',
                  () {
                Get.back();
                controller.selectedStatus.value = 'P';
                controller.filterShifts();
              },
              colorScheme,
              'P',
              Icons.pending_rounded,
              Colors.amber,
            ),
            _buildMenuItem(
              context,
              'Rejected',
                  () {
                Get.back();
                controller.selectedStatus.value = 'R';
                controller.filterShifts();
              },
              colorScheme,
              'R',
              Icons.cancel_rounded,
              Colors.red,
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filter By Status',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          InkWell(
            onTap: () async {
              await _animationController.reverse();
              Get.back();
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: Icon(
                Icons.close_rounded,
                size: 20.sp,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      height: 1.h,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primary.withOpacity(0.3),
            colorScheme.primary.withOpacity(0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context,
      String title,
      VoidCallback onTap,
      ColorScheme colorScheme,
      String statusCode,
      IconData icon,
      Color iconColor,
      ) {
    final isSelected = controller.selectedStatus.value.toLowerCase() ==
        statusCode.toLowerCase();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          splashColor: colorScheme.primary.withOpacity(0.1),
          highlightColor: colorScheme.primary.withOpacity(0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20.sp,
                    color: isSelected ? colorScheme.primary : iconColor.withOpacity(0.7),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    Icon(
                      Icons.check_rounded,
                      size: 20.sp,
                      color: colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}