import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF032B60),
            Color(0xFF05408A),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 44, // ⬅ bigger spinner for desktop
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3.2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            ),
            SizedBox(height: 22),
            Text(
              "Loading data",
              style: TextStyle(
                fontSize: 20, // ⬅ desktop headline size
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Please wait a moment",
              style: TextStyle(
                fontSize: 15, // ⬅ desktop subtext
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
