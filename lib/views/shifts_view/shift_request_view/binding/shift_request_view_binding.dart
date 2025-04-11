import 'package:get/get.dart';

import '../controller/shift_request_view_controller.dart';

class ShiftRequestViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShiftRequestViewController>(() => ShiftRequestViewController());
  }
}
