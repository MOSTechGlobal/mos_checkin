import 'package:get/get.dart';

import '../controller/make_shift_request_controller.dart';

class MakeShiftRequestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MakeShiftRequestController>(() => MakeShiftRequestController());
  }
}
