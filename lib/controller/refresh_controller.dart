import 'package:get/get.dart';

class RefreshController extends GetxController {
  var isRefreshing = false.obs;
  var refreshData = false.obs;

  void refreshScreen() async {
    isRefreshing.value = true;

    await Future.delayed(const Duration(milliseconds: 500));

    isRefreshing.value = false;
  }

  void refreshingData() async {
    print("refresh data: ${refreshData.value}");
    refreshData.value = true;

    await Future.delayed(const Duration(milliseconds: 500));

    refreshData.value = false;
  }
}
