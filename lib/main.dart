import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';

import 'controller/wallet_controller.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('app');

  Get.put(WalletController());

  final box = Hive.box('app');

  final bool isLoggedIn = box.get('isLoggedIn', defaultValue: false);
  final String savedUser = box.get('username', defaultValue: '');
  final String savedPass = box.get('password', defaultValue: '');

  runApp(
    MyApp(
      isLoggedIn: isLoggedIn,
      savedUsername: savedUser,
      savedPassword: savedPass,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String savedUsername;
  final String savedPassword;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.savedUsername,
    required this.savedPassword,
  });

  static const String appName = 'Shree Lott';

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,

      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      theme: ThemeData(),
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

      home: LoginView(
        isLoggedIn: isLoggedIn,
        savedUsername: savedUsername,
        savedPassword: savedPassword,
      ),
    );
  }
}