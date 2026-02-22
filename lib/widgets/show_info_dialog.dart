import 'package:flutter/material.dart';
import 'package:shreelott/screens/helpers/batting_grid_view.dart';

void showInfoDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 380,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEAB676).withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEAB676).withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 Gold Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD4A054),
                    Color(0xFFEAB676),
                    Color(0xFFD4A054),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 6),
                  Text(
                    "GAME INFORMATION",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  // // 🔹 Title
                  // Text(
                  //   title,
                  //   textAlign: TextAlign.center,
                  //   style: const TextStyle(
                  //     color: Color(0xFFEAB676),
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.w800,
                  //   ),
                  // ),
                  // const SizedBox(height: 10),

                  // 🔹 Subtitle
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔹 Close Button
                  ModernBtn(
                    text: "Okay",
                    bgColor: const Color(0xFFEAB676),
                    width: 400,
                    height: 40,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: () => Navigator.pop(context),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: const Color(0xFFEAB676),
                  //       foregroundColor: Colors.white,
                  //       padding: const EdgeInsets.symmetric(vertical: 14),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //       elevation: 0,
                  //     ),
                  //     child: const Text(
                  //       "OK",
                  //       style: TextStyle(
                  //         fontSize: 13,
                  //         fontWeight: FontWeight.w700,
                  //         letterSpacing: 1.5,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
