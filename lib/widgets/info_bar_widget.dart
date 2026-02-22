import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shreelott/screens/helpers/batting_grid_view.dart';
import 'package:shreelott/widgets/show_logout_dialog.dart';

import '../controller/wallet_controller.dart';
import '../screens/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shreelott/widgets/show_logout_dialog.dart';

import '../controller/wallet_controller.dart';
import '../screens/splash_screen.dart';

class YellowInfoBar extends StatefulWidget {
  final String time;
  final String draw;
  final String date;
  final String terminal;
  final String lastAmount;
  final String walletBalance;

  const YellowInfoBar({
    super.key,
    required this.time,
    required this.draw,
    required this.date,
    required this.terminal,
    required this.lastAmount,
    required this.walletBalance,
  });

  @override
  State<YellowInfoBar> createState() => _YellowInfoBarState();
}

class _YellowInfoBarState extends State<YellowInfoBar> {
  final WalletController walletController = Get.find<WalletController>();

  late String currentTime;

  @override
  void initState() {
    super.initState();
    currentTime = widget.time;
  }

  /// 🔥 This ensures widget updates when parent setState changes time
  @override
  void didUpdateWidget(covariant YellowInfoBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.time != widget.time) {
      currentTime = widget.time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.yellow.shade600,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// ✅ TIME TO DRAW (NOW UPDATES PROPERLY)
          InfoBlock(title: "TIME TO DRAW", value: currentTime),

          InfoBlock(title: "DRAW TIME", value: widget.draw),
          InfoBlock(title: "DRAW DATE", value: widget.date),

          const VerticalDivider(color: Colors.grey, thickness: 4, width: 30),

          /// ✅ Wallet still reactive
          Obx(
            () => InfoBlock(
              title: "LIMIT UPDATE",
              value: walletController.walletBalance.value.toStringAsFixed(0),
            ),
          ),

          InfoBlock(title: "TERMINAL ID", value: widget.terminal),

          InfoBlock(title: "LAST TRANSACTION AMOUNT", value: widget.lastAmount),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ModernBtn(
              text: "Logout",
              bgColor: Colors.red,
              width: 100,
              height: 40,
              onTap: () async {
                final confirm = await showLogoutDialog(context);
                if (confirm) {
                  final box = Hive.box('app');
                  final printerBox = Hive.isBoxOpen('printerBox')
                      ? Hive.box('printerBox')
                      : await Hive.openBox('printerBox');

                  await printerBox.clear();
                  await box.clear();

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          //   child: GestureDetector(
          //     onTap: () async {
          //       final confirm = await showLogoutDialog(context);
          //       if (confirm) {
          //         final box = Hive.box('app');
          //         final printerBox = Hive.isBoxOpen('printerBox')
          //             ? Hive.box('printerBox')
          //             : await Hive.openBox('printerBox');
          //
          //         await printerBox.clear();
          //         await box.clear();
          //
          //         Navigator.of(context).pushAndRemoveUntil(
          //           MaterialPageRoute(builder: (_) => const SplashScreen()),
          //           (_) => false,
          //         );
          //       }
          //     },
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 18),
          //       decoration: BoxDecoration(
          //         color: Colors.red,
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //       alignment: Alignment.center,
          //       child: const Text(
          //         "CLOSE",
          //         style: TextStyle(
          //           color: Colors.black,
          //           fontSize: 15,
          //           fontWeight: FontWeight.w700,
          //           letterSpacing: 0.3,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class InfoBlock extends StatelessWidget {
  final String title;
  final String value;

  const InfoBlock({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
