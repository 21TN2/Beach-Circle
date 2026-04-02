// TIFF

// dorm_interested.dart
// Shows all dorm events the current user has starred/interested.
// Uses InterestedDormService to stream the user's interested event IDs,
// then fetches each full DormEvent from Firestore via DormServices.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:beach_circle_flutter/community_goods/dorm_life/models/dorm_event.dart';
import 'package:beach_circle_flutter/community_goods/dorm_life/services/dorm_services.dart';
import 'package:beach_circle_flutter/community_goods/dorm_life/services/interested_dorm_service.dart';
import 'package:beach_circle_flutter/community_goods/dorm_life/widgets/dorm_events.dart';

class DormInterestedPage extends StatelessWidget {
  const DormInterestedPage({super.key});

  static const Color kYellow    = Color(0xFFFFCC00);
  static const Color kYellowBtn = Color(0xFFD4A800);
  static const Color kPurple    = Color(0xFF3B3599);

  String _dateLabel(DateTime d) {
    const days = ['MON','TUES','WED','THURS','FRI','SAT','SUN'];
    const months = [
      'JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),

      // ── Yellow app bar ──────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: kYellow,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        titleSpacing: 12,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9D6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dorm Life',
                        style: TextStyle(
                            color: Color(0xFF555555), fontSize: 15),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: kPurple),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Body ────────────────────────────────────────────────────────────
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
            child: Row(
              children: const [
                Icon(Icons.star, color: Color(0xFFFFD700), size: 26),
                SizedBox(width: 10),
                Text(
                  'Interested Events',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Color(0xFFD8D8D8)),
          ),

          // ── Event list ─────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<Set<String>>(
              stream: InterestedDormService.interestedEventIdsStream(),
              builder: (context, intSnap) {
                if (intSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final interestedIds = intSnap.data ?? {};

                if (interestedIds.isEmpty) {
                  return _buildEmptyState();
                }

                // Fetch the full event documents for each interested ID
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('dorm_events')
                      .where(FieldPath.documentId, whereIn: interestedIds.toList())
                      .snapshots(),
                  builder: (context, eventSnap) {
                    if (eventSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (eventSnap.hasError) {
                      return Center(
                        child: Text(
                          'Something went wrong.\n${eventSnap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final docs = eventSnap.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Parse and sort by date (soonest first)
                    final events = docs
                        .map((doc) => DormEvent.fromFirestore(doc))
                        .toList()
                      ..sort((a, b) => a.date.compareTo(b.date));

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: events.length,
                      itemBuilder: (context, i) {
                        final event = events[i];
                        final isInterested = interestedIds.contains(event.id);

                        return DormEvents(
                          title: event.title,
                          location: event.location,
                          body: event.description,
                          dateLabel: _dateLabel(event.date),
                          timeText: event.timeDisplay,
                          isInterested: isInterested,
                          color: event.category.color,
                          eventId: event.id,
                          eventOwnerId: event.id, // swap with ownerId field if added
                          flyerLink: event.links,
                          imageUrl: event.imageUrl,
                          interestedCount: event.interestedCount,
                          onInterestedTap: () async {
                            try {
                              await InterestedDormService.toggleInterested(
                                eventId: event.id,
                                isInterested: isInterested,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not update interest.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ── Bottom nav ───────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFD8D8D8))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.home, color: kPurple, size: 28),
            Icon(Icons.location_on_outlined, color: kPurple, size: 28),
            Icon(Icons.chat_bubble_outline, color: kPurple, size: 28),
            Icon(Icons.layers_outlined, color: kPurple, size: 28),
            Icon(Icons.settings_outlined, color: kPurple, size: 28),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star_border, size: 64, color: Color(0xFFD8D8D8)),
          SizedBox(height: 16),
          Text(
            'No interested events yet.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the ★ on any event to save it here.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}