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
        print(constraints.maxWidth);
        print(constraints.maxHeight);
        if (constraints.maxWidth < 1300 || constraints.maxHeight < 650) {
          return const SmallScreenWarning();
        }
        return child;
      },
    );
  }
}
