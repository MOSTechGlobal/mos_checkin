import 'package:get/get.dart';

import '../controller/form_detail_controller.dart';

class FormDetailBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut<FormDetailController>(()=>FormDetailController());
  }

}