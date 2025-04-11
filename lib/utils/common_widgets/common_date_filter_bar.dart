import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'common_date_picker_model.dart';

class CommonDateFilterBar extends StatefulWidget {
  final ColorScheme colorScheme;
  final String dateRangeText;
  final DateTime initialFromDate;
  final DateTime initialToDate;
  final Function(DateTime, DateTime) onDateSelected;

  const CommonDateFilterBar({
    super.key,
    required this.colorScheme,
    required this.dateRangeText,
    required this.initialFromDate,
    required this.initialToDate,
    required this.onDateSelected,
  });

  @override
  State<CommonDateFilterBar> createState() => _CommonDateFilterBarState();
}

class _CommonDateFilterBarState extends State<CommonDateFilterBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDatePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommonDatePickerModal(
        initialFromDate: widget.initialFromDate,
        initialToDate: widget.initialToDate,
        colorScheme: widget.colorScheme,
        onDateSelected: (from, to) {
          widget.onDateSelected(from, to);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _animationController.forward();
      },
      onTapUp: (_) {
        _animationController.reverse();
        _showDatePickerModal(context);
      },
      onTapCancel: () {
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          height: 36.h,
          padding: EdgeInsets.symmetric( horizontal: 16.w),
          margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFFDBFFCA).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.colorScheme.outline.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.colorScheme.shadow.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 18.sp,
                color: widget.colorScheme.outline,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  widget.dateRangeText,
                  style: TextStyle(
                    color: widget.colorScheme.outline,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    decorationColor: widget.colorScheme.primary.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}