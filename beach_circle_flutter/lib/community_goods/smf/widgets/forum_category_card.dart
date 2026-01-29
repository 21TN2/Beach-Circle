import 'package:flutter/material.dart';
import 'interested_button.dart';

class ForumCategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isInterested;
  final VoidCallback onTap;
  final VoidCallback onInterestedTap;

  const ForumCategoryCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.isInterested,
    required this.onTap,
    required this.onInterestedTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: 140,
            width: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InterestedButton(
              isInterested: isInterested,
              onPressed: onInterestedTap,
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
