import 'package:flutter/material.dart';

class SmallScreenWarning extends StatelessWidget {
  const SmallScreenWarning({super.key});

  // 🔹 ACTUAL APP CONFIG (KEEP IN SYNC WITH MyApp)
  static const double minWidth = 1300;
  static const double minHeight = 650;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF032B60),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.desktop_windows, size: 80, color: Colors.white),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Window Size Too Small',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'This application requires a larger window.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 24),

            // Current size
            const Text(
              'Current Window Size',
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
            const SizedBox(height: 4),
            Text(
              '${size.width.toInt()} × ${size.height.toInt()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Required size (ACTUAL CONFIG)
            const Text(
              'Minimum Required Size',
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
            const SizedBox(height: 4),
            const Text(
              '1250 × 630',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Please resize the window or switch to full screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
