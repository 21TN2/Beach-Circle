// REUSABLE STAR ICON WIDGET


import 'package:flutter/material.dart';

class InterestedButton extends StatelessWidget {
  final bool isInterested;
  final VoidCallback onPressed;

  const InterestedButton({
    super.key,
    required this.isInterested,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      // DISPLAY FILLED OR OUTLINED STAR DEPENDING ON STATE
      icon: Icon(
        isInterested ? Icons.star : Icons.star_border,
        color: Colors.amber,
      ),
      // TAP HANDLING
      onPressed: onPressed,
    );
  }
}
