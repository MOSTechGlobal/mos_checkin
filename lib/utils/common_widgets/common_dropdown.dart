import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hintText;
  final String? label;
  final double paddingVertical;
  final double paddingHorizontal;
  final int? iconWidth;
  final Function(String?)? onChanged; // Made nullable to match usage
  final String? Function(String?)? validator;
  final bool enabled;

  const CommonDropdown({
    super.key,
    required this.value,
    required this.items,
    this.label,
    this.paddingVertical = 0,
    this.paddingHorizontal = 10,
    this.iconWidth,
    required this.hintText,
    this.onChanged,
    this.validator,
    this.enabled = true, // Default value set to true
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Ensure unique items to avoid DropdownButton assertion error
    final uniqueItems = items.toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null && label!.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(
            vertical: paddingVertical.h,
            horizontal: paddingHorizontal.w,
          ),
          height: 40.h,
          decoration: BoxDecoration(
            color: colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow,
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Center(
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: colorScheme.onPrimary,
                highlightColor: colorScheme.primary.withOpacity(0.1),
                splashColor: colorScheme.primary.withOpacity(0.2),
              ),
              child: DropdownButtonFormField<String>(
                value: value?.isEmpty == true ? null : value,
                items:
                    uniqueItems.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: value == 'Select an option'
                            ? colorScheme.onSurface.withOpacity(0.6)
                            : colorScheme.onSurface,
                        fontSize: 14.sp,
                        fontWeight: value == 'Select an option'
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  border: InputBorder.none, // Removes default border
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                ),
                hint: Text(
                  hintText,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 12.sp,
                  ),
                ),
                icon: Container(
                  width: 16.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
                dropdownColor: colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(12.r),
                menuMaxHeight: 200.h,
                validator: validator,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
