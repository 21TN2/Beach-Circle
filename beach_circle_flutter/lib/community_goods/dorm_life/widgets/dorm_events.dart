// Made by Giselle for student work review 2
// This is to create how the events are organized

import 'package:flutter/material.dart';

class DormEvents extends StatelessWidget {
  const DormEvents({
    super.key,
    required this.title,
    required this.location,
    required this.body,
    required this.dateLabel,
    required this.timeText,
    required this.isInterested,
    required this.onInterestedTap,
    required this.color,
  });

  final String title;
  final String location;
  final String body;
  final String dateLabel;
  final String timeText;
  final bool isInterested;
  final VoidCallback onInterestedTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool isDarkCard = color.computeLuminance() < 0.35;
    final Color textColor = isDarkCard ? Colors.white : Colors.black87;
    final Color subTextColor = isDarkCard ? Colors.white70 : Colors.black87;
    final Color iconColor = isDarkCard ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          RotatedBox(
            quarterTurns: 3,
            child: Text(
              dateLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: onInterestedTap,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isInterested)
                              const Icon(
                                Icons.star_border,
                                color: Colors.black,
                                size: 24,
                              ),
                            Icon(
                              isInterested ? Icons.star : Icons.star_border,
                              color:
                                  isInterested
                                      ? const Color(0xFFFFD700)
                                      : iconColor,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$location , $timeText',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subTextColor),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          // TODO: open event details page
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
