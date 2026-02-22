import 'package:flutter/material.dart';

Widget bigCirclesLoader({
  double size = 18,
  double spacing = 14,
  Color color = Colors.white,
  Duration duration = const Duration(milliseconds: 1200),
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      bool forward = true;

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: duration,
        curve: Curves.easeInOut,
        onEnd: () {
          // restart animation (loop)
          forward = !forward;
          setState(() {});
        },
        builder: (context, value, _) {
          return SizedBox(
            width: (size * 3) + (spacing * 2),
            height: size * 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (i) {
                final phase = (value + (i * 0.25)) % 1.0;
                final scale =
                    0.6 + (phase < 0.5 ? phase : 1 - phase) * 0.8;
                final opacity = 0.4 + scale * 0.6;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: color.withOpacity(opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          );
        },
      );
    },
  );
}
