// REUSABLE REPORT BUTTON WIDGET


import 'package:flutter/material.dart';

class ReportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReportButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      // FLAG ICON --> REPORT
      icon: const Icon(Icons.flag),
      color: Colors.black,
      onPressed: onPressed,
    );
  }
}
