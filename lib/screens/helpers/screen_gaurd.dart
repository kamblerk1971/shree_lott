import 'package:flutter/material.dart';

import '../../main.dart';
import 'screen_warning.dart';

class ScreenSizeGuard extends StatelessWidget {
  final Widget child;

  const ScreenSizeGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1250 || constraints.maxHeight < 630) {
          return const SmallScreenWarning();
        }
        return child;
      },
    );
  }
}
