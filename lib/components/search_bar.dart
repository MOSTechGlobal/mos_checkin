import 'package:flutter/material.dart';

class MSearchBar extends StatefulWidget {
  final ColorScheme colorScheme;
  final TextEditingController controller;
  final String? hintText;
  final Function(String) onChanged;
  final Function() onClearPressed;
  const MSearchBar(
      {super.key,
      required this.colorScheme,
      required this.onChanged,
      required this.onClearPressed,
      required this.controller,
      this.hintText});

  @override
  State<MSearchBar> createState() => _MSearchBarState();
}

class _MSearchBarState extends State<MSearchBar> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      style: TextStyle(color: widget.colorScheme.onSecondaryContainer),
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Search',
        suffixIcon: IconButton(
          icon: Icon(Icons.clear,
              color: widget.colorScheme.primary.withOpacity(0.5)),
          onPressed: widget.onClearPressed,
        ),
        prefixIcon: Icon(Icons.search, color: widget.colorScheme.secondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
              color: widget.colorScheme.primaryContainer, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
              color: widget.colorScheme.primaryContainer, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
              color: widget.colorScheme.primaryContainer, width: 2.0),
        ),
        filled: true,
        fillColor: widget.colorScheme.primaryContainer,
      ),
    );
  }
}
