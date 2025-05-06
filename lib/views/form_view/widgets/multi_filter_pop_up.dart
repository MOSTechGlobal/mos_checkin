import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../utils/common_widgets/common_search_bar.dart';
import '../controller/form_controller.dart';

class FormMultiFilter extends StatefulWidget {
  const FormMultiFilter({super.key});

  @override
  State<FormMultiFilter> createState() => _FormMultiFilterState();
}

class _FormMultiFilterState extends State<FormMultiFilter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Filter state management
  bool _isResetEnabled = false;

  // Get the FormController instance
  final FormController controller = Get.find<FormController>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
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

  void _resetFilters() {
    setState(() {
      _isResetEnabled = false;
      controller.selectedStatus.value = 'all';
      controller.clearSearch();
      controller.filterForms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WillPopScope(
      onWillPop: () async {
        await _animationController.reverse();
        return true;
      },
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: GestureDetector(
          onTap: () async {
            await _animationController.reverse();
            Get.back();
          },
          behavior: HitTestBehavior.opaque,
          child: Align(
            alignment: Alignment.topRight,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildMenu(colorScheme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300.w,
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            bottomLeft: Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.3),
              blurRadius: 20.r,
              spreadRadius: 2.r,
              offset: const Offset(-2, 0),
            ),
          ],
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.08),
            width: 1,
          ),
        ),
        margin: EdgeInsets.only(top: 35.h, bottom: 16.h),
        child: Column(
          children: [_header(colorScheme), _filterBody(colorScheme)],
        ),
      ),
    );
  }

  Widget _header(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 16.r),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt_rounded,
                color: colorScheme.primary,
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (_isResetEnabled)
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  child: InkWell(
                    onTap: _resetFilters,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 6.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: colorScheme.errorContainer.withOpacity(0.6),
                        ),
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(width: 8.w),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20.r),
                child: InkWell(
                  onTap: () async {
                    await _animationController.reverse();
                    Get.back();
                  },
                  child: Icon(
                    Icons.cancel_outlined,
                    color: colorScheme.error,
                    size: 24.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterBody(ColorScheme colorScheme) {
    return Flexible(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchFilter(colorScheme),
                SizedBox(height: 16.h),
                _buildStatusFilter(colorScheme),
                SizedBox(height: 16.h),
                _buildDivider(colorScheme),
                SizedBox(height: 24.h),
                _buildApplyButton(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      height: 1.h,
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

  Widget _buildStatusFilter(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_rounded,
              size: 18.sp,
              color: colorScheme.primary,
            ),
            SizedBox(width: 8.w),
            Text(
              'Display By Status',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Obx(() => _buildStatusItem(
          context,
          'All',
              () {
            controller.selectedStatus.value = 'all';
            controller.filterForms();
            setState(() {
              _isResetEnabled = true;
            });
          },
          colorScheme,
          'all',
          Icons.filter_list_rounded,
          colorScheme.primary,
        )),
        Obx(() => _buildStatusItem(
          context,
          'Pending',
              () {
            controller.selectedStatus.value = 'pending';
            controller.filterForms();
            setState(() {
              _isResetEnabled = true;
            });
          },
          colorScheme,
          'pending',
          Icons.pending_rounded,
          Colors.amber,
        )),
        Obx(() => _buildStatusItem(
          context,
          'Completed',
              () {
            controller.selectedStatus.value = 'completed';
            controller.filterForms();
            setState(() {
              _isResetEnabled = true;
            });
          },
          colorScheme,
          'completed',
          Icons.check_circle_rounded,
          Colors.green,
        )),
      ],
    );
  }

  Widget _buildStatusItem(
      BuildContext context,
      String title,
      VoidCallback onTap,
      ColorScheme colorScheme,
      String statusCode,
      IconData icon,
      Color iconColor,
      ) {
    final isSelected = controller.selectedStatus.value == statusCode;

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
                    color: isSelected
                        ? colorScheme.primary
                        : iconColor.withOpacity(0.7),
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

  Widget _searchFilter(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_rounded,
              size: 18.sp,
              color: colorScheme.primary,
            ),
            SizedBox(width: 8.w),
            Text(
              'Search By Name',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        CommonSearchBar(
          colorScheme: colorScheme,
          searchController: controller.searchController,
        ),
      ],
    );
  }

  Widget _buildApplyButton(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 44.h,
      child: Material(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: () async {
            controller.filterForms();
            await _animationController.reverse();
            Get.back();
          },
          borderRadius: BorderRadius.circular(12.r),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16.sp,
                  color: colorScheme.onPrimary,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}