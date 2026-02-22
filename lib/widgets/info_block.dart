import 'package:flutter/material.dart';

class InfoBlock extends StatelessWidget {
  final String title;
  final String value;

  const InfoBlock({ required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
