import 'package:flutter/material.dart';
import 'package:beach_circle_flutter/community_goods/dorm_life/models/dorm_event.dart';
import 'package:beach_circle_flutter/community_goods/dorm_life/services/dorm_services.dart';

/// Colored event card shown in the home feed and interested screen.
/// [onTap] navigates to the detail screen.
/// [onInterestedToggled] lets the parent rebuild via setState.
class DormEventCard extends StatelessWidget {
  final DormEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onInterestedToggled;

  const DormEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onInterestedToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: event.category.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Text ────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Star button top-right of text column
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () async {
                        await DormServices.toggleInterested(
                            event.id, event.isInterested);
                        onInterestedToggled?.call();
                      },
                      child: Icon(
                        event.isInterested
                            ? Icons.star
                            : Icons.star_border,
                        color: event.isInterested
                            ? Colors.white
                            : Colors.black54,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '@ ${event.location} , ${event.timeDisplay}',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Arrow ────────────────────────────────────────────────────
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward,
                    size: 20, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}