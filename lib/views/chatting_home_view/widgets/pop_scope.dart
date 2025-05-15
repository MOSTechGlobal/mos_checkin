import 'package:flutter/material.dart';

class PopScope extends StatelessWidget {
  final Widget child;
  final bool canPop;

  const PopScope({Key? key, required this.child, required this.canPop})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => canPop,
      child: child,
    );
  }
}