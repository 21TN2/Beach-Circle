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
      icon: Icon(
        isInterested ? Icons.star : Icons.star_border,
        color: Colors.amber,
      ),
      onPressed: onPressed,
    );
  }
}
