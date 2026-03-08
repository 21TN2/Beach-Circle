// Made by Giselle for student work review 2
// This is to create how the events are organized

import 'package:flutter/material.dart';

// required fields to input into database
class DormEvents extends StatelessWidget {
  const DormEvents({
    super.key,
    required this.title,
    required this.location,
    required this.body,
    required this.dateLabel,
    required this.timeText,
    required this.isStarred,
    required this.color,
  });

  final String
  title; // all fields aside from color & starred are turned into strings
  final String location;
  final String body;
  final String dateLabel;
  final String timeText;
  final bool isStarred;
  final Color color;

  // creating card format
  @override
  Widget build(BuildContext context) {
    final bool isDarkCard =
        color.computeLuminance() < 0.35; // when color of the category is dark
    final Color textColor =
        isDarkCard ? Colors.white : Colors.black87; // title text color
    final Color subTextColor =
        isDarkCard ? Colors.white70 : Colors.black87; // text color
    final Color iconColor =
        isDarkCard ? Colors.white : Colors.black87; // icon color

    // for the card box
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          RotatedBox(
            quarterTurns: 3,
            child: Text(
              dateLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700, // depends on the text user inputs
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
                      Icon(
                        isStarred
                            ? Icons.star
                            : Icons
                                .star_border, // card has star icon for interested
                        color: iconColor,
                        size: 22,
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
                    '$location , $timeText', // display location & time w/ this format
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
                  const SizedBox(
                    height: 14,
                  ), // arrow in the card to take user to view more detials
                  Align(
                    alignment: Alignment.centerRight,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward, // arrow icon
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
