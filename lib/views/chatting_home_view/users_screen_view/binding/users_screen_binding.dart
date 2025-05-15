import 'package:get/get.dart';

import '../controller/users_screen_controller.dart';

class UsersScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UsersScreenController());
  }
}
