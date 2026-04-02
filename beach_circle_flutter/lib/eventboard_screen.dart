// eventboard_screen.dart
// Top-level entry point for the Event Board use case.
// Lives in lib/ alongside dormlife_screen.dart.
// Mirrors the structure of dormlife_screen.dart exactly.

import 'package:beach_circle_flutter/community_goods/event_board/screens/eb_create.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../community_goods/event_board/widgets/eb_calendar.dart';
import '../community_goods/event_board/widgets/eb_events.dart';
import '../community_goods/event_board/services/interested_eb_service.dart';

class EventBoardScreen extends StatefulWidget {
  const EventBoardScreen({super.key});

  @override
  State<EventBoardScreen> createState() => _EventBoardScreenState();
}

class _EventBoardScreenState extends State<EventBoardScreen> {
  DateTime selectedDate = DateTime.now();
  bool interestedOnly = false;

  // ── getEvents: returns events for the selected day ──────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> getEvents() {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return FirebaseFirestore.instance
        .collection('board_events')
        .where('status', isEqualTo: 'approved')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots();
  }

  // ── dateKey helper ───────────────────────────────────────────────────────────
  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // ── getMonthEventDates: returns dot colors for the calendar ─────────────────
  Stream<Map<String, List<Color>>> getMonthEventDates() {
    final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
    final nextMonthStart = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      1,
    );
    return FirebaseFirestore.instance
        .collection('board_events')
        .where('status', isEqualTo: 'approved')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('date', isLessThan: Timestamp.fromDate(nextMonthStart))
        .snapshots()
        .map((snapshot) {
          final Map<String, List<Color>> eventMap = {};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final dynamic startRaw = data['date'];
            final int categoryIndex = (data['category'] ?? 0) as int;
            if (startRaw is Timestamp) {
              final key = dateKey(startRaw.toDate());
              final color = eventColor(categoryIndex);
              eventMap.putIfAbsent(key, () => []);
              if (!eventMap[key]!.contains(color)) {
                eventMap[key]!.add(color);
              }
            }
          }
          return eventMap;
        });
  }

  Stream<Set<String>> interestedEventIdsStream() {
    return InterestedEbService.interestedEventIdsStream();
  }

  // ── Category index → color (matches EventBoardCategory enum order) ──────────
  Color eventColor(int categoryIndex) {
    switch (categoryIndex) {
      case 0: // athletics
        return const Color(0xFFFFCC00);
      case 1: // organization
        return const Color(0xFFF5A623);
      case 2: // academic
        return const Color(0xFF8DB600);
      default:
        return const Color(0xFFF5A623);
    }
  }

  // ── Time formatter ───────────────────────────────────────────────────────────
  String formatTime(DateTime dt) {
    final hour =
        dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  // ── Vertical date label ──────────────────────────────────────────────────────
  String verticalDate(DateTime date) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    const days = ['MON', 'TUES', 'WED', 'THURS', 'FRI', 'SAT', 'SUN'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2F2),

      // ── FAB ──────────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF2C200),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EbCreatePage()),
          );
        },
        child: const Icon(Icons.edit, color: Colors.black),
      ),

      body: SafeArea(
        child: Column(
          children: [

            // ── Header ──────────────────────────────────────────────────────────
            Container(
              color: const Color(0xFFFFD500),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                            child: Text(
                              'Event Board',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        interestedOnly = !interestedOnly;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6841A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            interestedOnly
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Interested',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Calendar ─────────────────────────────────────────────────────────
            StreamBuilder<Map<String, List<Color>>>(
              stream: getMonthEventDates(),
              builder: (context, snapshot) {
                final eventDates =
                    snapshot.data ?? <String, List<Color>>{};
                return EbCalendar(
                  selectedDate: selectedDate,
                  eventDates: eventDates,
                  onDateSelected: (date) {
                    setState(() => selectedDate = date);
                  },
                  onPreviousMonth: () {
                    setState(() {
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month - 1,
                        1,
                      );
                    });
                  },
                  onNextMonth: () {
                    setState(() {
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month + 1,
                        1,
                      );
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            // ── Event list ───────────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<Set<String>>(
                stream: interestedEventIdsStream(),
                builder: (context, interestedSnap) {
                  final interestedIds =
                      interestedSnap.data ?? <String>{};

                  return StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: getEvents(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data!.docs;

                      if (interestedOnly) {
                        docs = docs
                            .where((doc) =>
                                interestedIds.contains(doc.id))
                            .toList();
                      }

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No events for this day.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          final dynamic dateRaw = data['date'];
                          final int startHour = data['startHour'] ?? 0;
                          final int startMinute =
                              data['startMinute'] ?? 0;
                          final int? endHour = data['endHour'];
                          final int? endMinute = data['endMinute'];

                          if (dateRaw is! Timestamp) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                    'Missing or invalid date field'),
                              ),
                            );
                          }

                          final baseDate = dateRaw.toDate();
                          final start = DateTime(
                            baseDate.year,
                            baseDate.month,
                            baseDate.day,
                            startHour,
                            startMinute,
                          );
                          final timeText = endHour != null
                              ? '${formatTime(start)} - ${formatTime(DateTime(baseDate.year, baseDate.month, baseDate.day, endHour, endMinute ?? 0))}'
                              : formatTime(start);

                          final isInterested =
                              interestedIds.contains(doc.id);
                          final int categoryIndex =
                              (data['category'] ?? 0) as int;

                          return EbEvents(
                            title: (data['title'] ?? '(No title)')
                                .toString(),
                            location:
                                (data['location'] ?? 'No location')
                                    .toString(),
                            body: (data['description'] ?? '')
                                .toString(),
                            dateLabel: verticalDate(start),
                            timeText: timeText,
                            isInterested: isInterested,
                            onInterestedTap: () async {
                              try {
                                await InterestedEbService
                                    .toggleInterested(
                                  eventId: doc.id,
                                  isInterested: isInterested,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Could not update interested: $e')),
                                );
                              }
                            },
                            color: eventColor(categoryIndex),
                            eventId: doc.id,
                            eventOwnerId: (data['createdBy'] ??
                                    data['authorId'] ??
                                    '')
                                .toString(),
                            imageUrl:
                                data['imageUrl']?.toString(),
                            highlights: data['highlights'] != null
                                ? List<String>.from(
                                    data['highlights'])
                                : null,
                            flyerLink:
                                data['links']?.toString(),
                            registrationLink: data['registrationLink']
                                ?.toString(),
                            websiteLink:
                                data['websiteLink']?.toString(),
                            instagramLink:
                                data['instagramLink']?.toString(),
                            contactEmail:
                                data['contactEmail']?.toString(),
                            interestedCount:
                                data['interestedCount'] is num
                                    ? (data['interestedCount'] as num)
                                        .toInt()
                                    : int.tryParse(data[
                                                'interestedCount']
                                            ?.toString() ??
                                        '') ??
                                        0,
                            roomNumber:
                                data['roomNumber']?.toString(),
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
      ),
    );
  }
}