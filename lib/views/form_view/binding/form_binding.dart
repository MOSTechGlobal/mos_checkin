import 'package:get/get.dart';
import '../controller/form_controller.dart';

class FormsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FormController());
  }
}
