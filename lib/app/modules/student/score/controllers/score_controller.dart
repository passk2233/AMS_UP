import 'package:get/get.dart';

class ScoreController extends GetxController {
  //TODO: Implement ScoreController
  var selectedTermIndex = 0.obs;

  

  void changeTerm(int index) {
    selectedTermIndex.value = index;
  }

  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
}
