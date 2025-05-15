import 'package:get/get.dart';

import '../controller/group_user_add_controller.dart';

class GroupUserAddBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GroupUserAddController());
  }
}
