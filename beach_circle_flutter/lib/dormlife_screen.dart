// Creating Dorm Life Home Page
// Made by Giselle --> for student work review 2
// TO DO: Create Home Page Functionality next

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../community_goods/dorm_life/widgets/dorm_calendar.dart';
import '../community_goods/dorm_life/widgets/dorm_events.dart';

class DormlifeScreen extends StatefulWidget {
  const DormlifeScreen({super.key});

  @override
  State<DormlifeScreen> createState() => _DormlifeScreenState();
}

class _DormlifeScreenState extends State<DormlifeScreen> {
  DateTime selectedDate = DateTime.now();
  bool interestedOnly = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> getEvents() {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final endOfDay = startOfDay.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('dorm_events')
        .where('status', isEqualTo: 'approved')
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('startTime')
        .snapshots();
  }

  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Stream<Map<String, List<Color>>> getMonthEventDates() {
    final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
    final nextMonthStart = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      1,
    );

    return FirebaseFirestore.instance
        .collection('dorm_events')
        .where('status', isEqualTo: 'approved')
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
        )
        .where('startTime', isLessThan: Timestamp.fromDate(nextMonthStart))
        .snapshots()
        .map((snapshot) {
          final Map<String, List<Color>> eventMap = {};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final dynamic startRaw = data['startTime'];
            final category = (data['category'] ?? 'Other').toString();

            if (startRaw is Timestamp) {
              final key = dateKey(startRaw.toDate());
              final color = eventColor(category);

              eventMap.putIfAbsent(key, () => []);

              if (!eventMap[key]!.contains(color)) {
                eventMap[key]!.add(color);
              }
            }
          }

          return eventMap;
        });
  }

  CollectionReference<Map<String, dynamic>> interestedRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('interestedDormEvents');
  }

  Stream<Set<String>> interestedEventIdsStream() {
    return interestedRef().snapshots().map(
      (snap) => snap.docs.map((doc) => doc.id).toSet(),
    );
  }

  Future<void> toggleInterested({
    required String eventId,
    required bool isInterested,
  }) async {
    final docRef = interestedRef().doc(eventId);

    if (isInterested) {
      await docRef.delete();
    } else {
      await docRef.set({
        'eventId': eventId,
        'interestedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // TO DO: might need to adjust colors to have a nice color palette
  Color eventColor(String category) {
    // the categories have colors to tell them apart
    switch (category) {
      case 'Social':
        return const Color(0xFFFFCC00); // social events
      case 'Academic':
        return const Color(0xFFF5A623); // academic events
      case 'Meetings':
        return const Color.fromARGB(255, 230, 219, 105); // meetings
      case 'Announcements':
        return const Color(0xFF8DB600); // announcments
      case 'Tips':
        return const Color.fromARGB(255, 116, 152, 224); // tips
      case 'Other':
        return const Color.fromRGBO(233, 141, 133, 1); // others
      default:
        return const Color.fromRGBO(
          245,
          238,
          158,
          1,
        ); // any other thats not determined
    }
  }

  String formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String verticalDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    const days = ['MON', 'TUES', 'WED', 'THURS', 'FRI', 'SAT', 'SUN'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2F2),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF2C200),
        onPressed: () {
          // TODO: open create dorm event page
        },
        child: const Icon(Icons.edit, color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFFFFD500),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                            child: Text(
                              'Dorm Life',
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
                  InkWell(
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
                        color:
                            interestedOnly
                                ? const Color(0xFFFFD700) // yellow when active
                                : const Color(0xFFE6841A), // original orange
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            interestedOnly ? Icons.star : Icons.star_border,
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

            StreamBuilder<Map<String, List<Color>>>(
              stream: getMonthEventDates(),
              builder: (context, snapshot) {
                final eventDates = snapshot.data ?? <String, List<Color>>{};

                return DormCalendar(
                  selectedDate: selectedDate,
                  eventDates: eventDates,
                  onDateSelected: (date) {
                    setState(() {
                      selectedDate = date;
                    });
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

            Expanded(
              child: StreamBuilder<Set<String>>(
                stream: interestedEventIdsStream(),
                builder: (context, interestedSnap) {
                  final interestedIds = interestedSnap.data ?? <String>{};

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: getEvents(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data!.docs;

                      if (interestedOnly) {
                        docs =
                            docs
                                .where((doc) => interestedIds.contains(doc.id))
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          final dynamic startRaw = data['startTime'];
                          final dynamic endRaw =
                              data['endTime'] ?? data['endTime '];

                          if (startRaw == null || endRaw == null) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Missing startTime or endTime'),
                              ),
                            );
                          }

                          if (startRaw is! Timestamp || endRaw is! Timestamp) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'startTime or endTime is not a Timestamp',
                                ),
                              ),
                            );
                          }

                          final start = startRaw.toDate();
                          final end = endRaw.toDate();
                          final isInterested = interestedIds.contains(doc.id);

                          return DormEvents(
                            title:
                                (data['title'] ??
                                        data['title '] ??
                                        '(No title)')
                                    .toString(),
                            location:
                                (data['location'] ?? 'No location').toString(),
                            body: (data['description'] ?? '').toString(),
                            dateLabel: verticalDate(start),
                            timeText:
                                '${formatTime(start)} - ${formatTime(end)}',
                            isInterested: isInterested,
                            onInterestedTap: () {
                              toggleInterested(
                                eventId: doc.id,
                                isInterested: isInterested,
                              );
                            },
                            color: eventColor(
                              (data['category'] ?? 'Other').toString(),
                            ),
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
