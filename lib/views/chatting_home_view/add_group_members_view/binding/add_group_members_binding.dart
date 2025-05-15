import 'package:get/get.dart';

import '../controller/add_group_members_controller.dart';

class AddGroupMembersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AddGroupMembersController());
  }
}
