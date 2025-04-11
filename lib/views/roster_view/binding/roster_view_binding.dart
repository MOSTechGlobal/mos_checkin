import 'package:get/get.dart';

import '../controller/roster_view_controller.dart';

class RosterViewBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut<RosterViewController>(() => RosterViewController());
  }
}
