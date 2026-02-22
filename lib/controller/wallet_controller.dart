import 'package:get/get.dart';

class WalletController extends GetxController {

  // Reactive wallet balance
  final RxDouble walletBalance = 0.0.obs;

  // Set initial balance
  void setBalance(double amount) {
    walletBalance.value = amount;
  }

  // Add money
  void add(double amount) {
    if (amount <= 0) return;
    walletBalance.value += amount;
  }

  // Deduct money
  bool deduct(double amount) {
    if (amount <= 0) return true;

    if (walletBalance.value >= amount) {
      walletBalance.value -= amount;
      return true;
    }
    return false;
  }

  // Check balance
  bool hasEnough(double amount) {
    return walletBalance.value >= amount;
  }

  // Reset wallet
  void reset() {
    walletBalance.value = 0.0;
  }
}
