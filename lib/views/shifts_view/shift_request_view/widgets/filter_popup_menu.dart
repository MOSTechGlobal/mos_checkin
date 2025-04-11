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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Short fade duration
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward(); // Start the fade-in animation
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
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: WillPopScope(
        onWillPop: () async {
          await _animationController.reverse(); // Fade out before closing
          return true;
        },
        child: Stack(
          children: [
            Positioned(
              top: 110.h, // Adjusted for alignment with filter icon
              right: 10.w,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildMenu(context, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: screenWidth * 0.5, // Responsive width
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme),
            // In FilterPopupMenu class
            _buildMenuItem(
              context,
              'Approved',
              () {
                Get.back();
                controller.selectedStatus.value = 'A';
                controller
                    .filterShifts(); // Call filterShifts, not filteredShifts
              },
              colorScheme,
            ),
            _buildMenuItem(
              context,
              'Pending',
              () {
                Get.back();
                controller.selectedStatus.value =
                    'P'; // Use 'P' instead of 'pending'
                controller.filterShifts();
              },
              colorScheme,
            ),
            _buildMenuItem(
              context,
              'Rejected',
              () {
                Get.back();
                controller.selectedStatus.value =
                    'R'; // Use 'R' instead of 'rejected'
                controller.filterShifts();
              },
              colorScheme,
            ),
            _buildMenuItem(
              context,
              'All',
              () {
                Get.back();
                controller.selectedStatus.value = 'all';
                controller
                    .filterShifts(); // Update to assign filteredShiftRequests directly
              },
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        'Filter By Status',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    // Map the title to its corresponding status code
    String statusCode;
    switch (title.toLowerCase()) {
      case 'approved':
        statusCode = 'A';
        break;
      case 'pending':
        statusCode = 'P';
        break;
      case 'rejected':
        statusCode = 'R';
        break;
      case 'cancelled':
        statusCode = 'C';
        break;
      case 'all':
        statusCode = 'all';
        break;
      default:
        statusCode = ''; // Fallback, though this shouldn't happen
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: controller.selectedStatus.value.toLowerCase() ==
                    statusCode.toLowerCase()
                ? colorScheme.primary
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
