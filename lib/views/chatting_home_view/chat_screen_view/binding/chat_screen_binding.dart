import 'package:get/get.dart';

import '../controller/chat_screen_controller.dart';

class ChatScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChatScreenController());
  }
}
