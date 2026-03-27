// Work Review 3
// Made by Giselle
// to choose image
import 'dart:io';
import 'package:flutter/material.dart';

class ReportImageSection extends StatelessWidget {
  const ReportImageSection({
    super.key,
    required this.selectedImage,
    required this.onPickImage,
  });

  final File? selectedImage;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: onPickImage,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            side: const BorderSide(color: Color(0xFFD0D0D0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            selectedImage == null ? '+ Add a Photo' : 'Change Photo',
            style: const TextStyle(color: Colors.black87),
          ),
        ),

        if (selectedImage != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              selectedImage!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],

        const SizedBox(height: 8),
        const Text(
          'Optional',
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
      ],
    );
  }
}
