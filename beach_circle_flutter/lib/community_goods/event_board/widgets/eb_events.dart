// eb_events.dart
import 'package:flutter/material.dart';
import 'package:beach_circle_flutter/community_goods/event_board/screens/expanded_eb_event.dart';

class EbEvents extends StatelessWidget {
  const EbEvents({
    super.key,
    required this.title,
    required this.location,
    required this.body,
    required this.dateLabel,
    required this.timeText,
    required this.isInterested,
    required this.onInterestedTap,
    required this.color,
    required this.eventId,
    required this.eventOwnerId,
    // optional fields
    this.flyerLink,
    this.registrationLink,
    this.imageUrl,
    this.highlights,
    this.interestedCount,
    this.websiteLink,
    this.instagramLink,
    this.contactEmail,
    this.roomNumber,
  });

  final String title;
  final String location;
  final String body;
  final String dateLabel;
  final String timeText;
  final bool isInterested;
  final VoidCallback onInterestedTap;
  final Color color;
  final String eventId;
  final String eventOwnerId;
  final String? flyerLink;
  final String? registrationLink;
  final String? imageUrl;
  final List<String>? highlights;
  final int? interestedCount;
  final String? websiteLink;
  final String? instagramLink;
  final String? contactEmail;
  final String? roomNumber;

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

                  // ── Star button row ──
                  Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: onInterestedTap,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              color: isInterested
                                  ? const Color(0xFFFFD700)
                                  : Colors.transparent,
                              size: 22,
                            ),
                            Icon(
                              Icons.star_border,
                              color: iconColor,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Title ──
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

                  // ── Location + time ──
                  Text(
                    '@ $location , $timeText',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Arrow button ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpandedEbEventPg(
                                title: title,
                                location: location,
                                body: body,
                                dateLabel: dateLabel,
                                timeText: timeText,
                                eventId: eventId,
                                eventOwnerId: eventOwnerId,
                                flyerLink: flyerLink,
                                registrationLink: registrationLink,
                                imageUrl: imageUrl,
                                highlights: highlights,
                                interestedCount: interestedCount,
                                websiteLink: websiteLink,
                                instagramLink: instagramLink,
                                contactEmail: contactEmail,
                                roomNumber: roomNumber,
                                isInterested: isInterested,
                                onInterestedTap: onInterestedTap,
                              ),
                            ),
                          );
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