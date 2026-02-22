import 'package:flutter/material.dart';

class HeaderMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const HeaderMenu({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: "refresh", child: Text("Refresh")),
        PopupMenuItem(value: "support", child: Text("Support")),
        PopupMenuItem(value: "report", child: Text("Reports")),

        PopupMenuDivider(),
        PopupMenuItem(value: "logout", child: Text("Logout")),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.settings_outlined, color: Colors.white),
      ),
    );
  }
}
