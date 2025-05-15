import 'package:get/get.dart';

import '../controller/group_profile_controller.dart';

class GroupProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GroupProfileController());
  }
}
