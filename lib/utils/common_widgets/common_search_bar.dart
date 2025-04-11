import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonSearchBar extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextEditingController searchController;
  final Function(String)?
  onChanged; // Optional callback for search text changes
  final Function()? onClear; // Optional callback for clear button

  const CommonSearchBar({
    super.key,
    required this.colorScheme,
    required this.searchController,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 18.w),
          Image.asset(
            'assets/icons/search.png',
            width: 14.w,
            height: 14.h,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              color: colorScheme.onPrimary,
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  // Trigger the onChanged callback if provided
                  onChanged?.call(value);
                },
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(
                    color: colorScheme.outline,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                searchController.clear();
                onClear?.call();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.h),
                child: Icon(
                  Icons.clear,
                  size: 16.w,
                  color: colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
