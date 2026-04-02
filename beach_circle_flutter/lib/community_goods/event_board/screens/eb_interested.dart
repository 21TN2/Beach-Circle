// eb_interested.dart
// Shows all Event Board events the current user has starred.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:beach_circle_flutter/community_goods/event_board/models/eb_event.dart';
import 'package:beach_circle_flutter/community_goods/event_board/services/eb_services.dart';
import 'package:beach_circle_flutter/community_goods/event_board/services/interested_eb_service.dart';
import 'package:beach_circle_flutter/community_goods/event_board/widgets/eb_events.dart';

class EBInterestedPage extends StatelessWidget {
  const EBInterestedPage({super.key});

  static const Color kYellow = Color(0xFFFFCC00);
  static const Color kPurple = Color(0xFF3B3599);

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
                        'Event Board',
                        style: TextStyle(color: Color(0xFF555555), fontSize: 15),
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

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          Expanded(
            child: StreamBuilder<Set<String>>(
              stream: InterestedEBService.interestedEventIdsStream(),
              builder: (context, intSnap) {
                if (intSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final interestedIds = intSnap.data ?? {};

                if (interestedIds.isEmpty) {
                  return _buildEmptyState();
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('eb_events')
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

                    if (docs.isEmpty) return _buildEmptyState();

                    final events = docs
                        .map((doc) => EBEvent.fromFirestore(doc))
                        .toList()
                      ..sort((a, b) => a.date.compareTo(b.date));

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: events.length,
                      itemBuilder: (context, i) {
                        final event = events[i];
                        final isInterested = interestedIds.contains(event.id);

                        return EBEvents(
                          title: event.title,
                          location: event.location,
                          body: event.description,
                          dateLabel: _dateLabel(event.date),
                          timeText: event.timeDisplay,
                          isInterested: isInterested,
                          color: event.category.color,
                          eventId: event.id,
                          eventOwnerId: event.createdBy ?? '',
                          flyerLink: event.links,
                          imageUrl: event.imageUrl,
                          interestedCount: event.interestedCount,
                          onInterestedTap: () async {
                            try {
                              await InterestedEBService.toggleInterested(
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

    );
  }

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