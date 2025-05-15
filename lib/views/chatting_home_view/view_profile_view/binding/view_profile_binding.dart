import 'package:get/get.dart';

import '../controller/view_profile_controller.dart';

class ViewProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ViewProfileController());
  }
}
