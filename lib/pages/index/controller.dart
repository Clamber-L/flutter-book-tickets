import 'package:get/get.dart';

class IndexController extends GetxController {
  var num = 0.obs;

  IndexController();

  _initData() {
    update(["index"]);
  }

  void onTap() {}

  void inc() {
    num.value++;
  }

  // @override
  // void onInit() {
  //   super.onInit();
  // }

  @override
  void onReady() {
    super.onReady();
    _initData();
  }

  // @override
  // void onClose() {
  //   super.onClose();
  // }
}
