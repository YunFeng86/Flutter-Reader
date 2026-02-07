import 'package:flutter/material.dart';

class ThemeRadioItem extends StatelessWidget {
  const ThemeRadioItem({super.key, required this.label, required this.value});

  final String label;
  final ThemeMode value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      title: Text(label),
      value: value,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
