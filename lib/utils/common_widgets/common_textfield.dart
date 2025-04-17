import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonTextField extends StatefulWidget {
  final TextEditingController? controller;
  final Color? textFieldColor;
  final String hintText;
  final String? label;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final EdgeInsets? contentPadding;
  final Function(String)? onChanged;
  final bool? readOnly;
  final bool? enabled;
  final bool isPassword;
  final double paddingVertical;
  final List<TextInputFormatter>? inputFormatters; // <-- new

  const CommonTextField({
    super.key,
    this.controller,
    this.textFieldColor,
    required this.hintText,
    this.label,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.contentPadding,
    this.onChanged,
    this.readOnly,
    this.enabled = true,
    this.isPassword = false,
    this.paddingVertical = 0.0,
    this.inputFormatters, // <-- new
  });

  @override
  State<CommonTextField> createState() => _CommonTextFieldState();
}

class _CommonTextFieldState extends State<CommonTextField> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    final shouldObscure = widget.isPassword && !showPassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(vertical: widget.paddingVertical.h),
          height: 40.h,
          decoration: BoxDecoration(
            color: widget.textFieldColor ?? Theme.of(context).colorScheme.onPrimary,
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
            child: TextFormField(
              enabled: widget.enabled,
              controller: widget.controller,
              onChanged: widget.onChanged,
              readOnly: widget.readOnly ?? false,
              textAlignVertical: TextAlignVertical.center,
              textAlign: TextAlign.left,
              obscureText: shouldObscure,
              inputFormatters: widget.inputFormatters, // <-- added here
              decoration: InputDecoration(
                contentPadding: widget.contentPadding ?? EdgeInsets.symmetric(horizontal: 12.w),
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12.sp,
                ),
                suffixIcon: widget.isPassword
                    ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                )
                    : null,
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              keyboardType: widget.keyboardType,
              validator: widget.validator,
            ),
          ),
        ),
      ],
    );
  }
}
