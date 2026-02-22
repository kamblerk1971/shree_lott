import 'package:get/get.dart';

class IndexController extends GetxController {
  var selectedIndex = 0.obs;   // observable int

  void setIndex(int index) {
    selectedIndex.value = index;
  }

  int get getIndex => selectedIndex.value;
}
