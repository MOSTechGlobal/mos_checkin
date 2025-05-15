import 'package:get/get.dart';

import '../controllers/chats_list_controller.dart';
import '../controllers/chatting_home_controller.dart';
import '../controllers/groups_list_controller.dart';

class ChattingHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChattingHomeController());
    Get.lazyPut(() => ChatsListController());
    Get.lazyPut(() => GroupsListController());
  }
}
