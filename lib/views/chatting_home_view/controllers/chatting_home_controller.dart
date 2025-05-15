import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChattingHomeController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this); // Use 'this' as vsync
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}