import 'package:flutter/material.dart';

void showToast(String message, BuildContext context, {bool error = true}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  final screenWidth = MediaQuery.of(context).size.width;

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? Colors.red.shade600 : Colors.green.shade600,

      // 👇 THIS IS THE KEY PART
      margin: EdgeInsets.only(
        top: 20,
        right: 20,
        left: screenWidth - 420, // controls min width + right alignment
        bottom: MediaQuery.of(context).size.height - 100,
      ),

      content: SizedBox(
        width: 360, // min width
        child: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
