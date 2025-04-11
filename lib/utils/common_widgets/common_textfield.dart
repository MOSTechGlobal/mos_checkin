import 'package:flutter/material.dart';
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
  final bool isObscure;
  final bool? enabled;
  final bool isPassword;
  final double paddingVertical;

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
    this.isObscure = false,
    this.isPassword = false,
    this.enabled = true,
    this.paddingVertical = 0.0,
  });

  @override
  State<CommonTextField> createState() => _CommonTextFieldState();
}

class _CommonTextFieldState extends State<CommonTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isObscure;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.label == null || widget.label == ''
            ? const SizedBox()
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                child: Text(
                  widget.label ?? '',
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
        Container(
          padding: EdgeInsets.symmetric(vertical: widget.paddingVertical.h),
          height: 40.h,
          decoration: BoxDecoration(
            color: widget.textFieldColor ??
                Theme.of(context).colorScheme.onPrimary,
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
              obscureText: _obscure,
              decoration: InputDecoration(
                contentPadding: widget.contentPadding ??
                    EdgeInsets.symmetric(horizontal: 12.w),
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12.sp,
                ),
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
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
