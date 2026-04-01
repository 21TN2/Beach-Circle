// Creating Dorm Life Home Page
// Made by Giselle --> for student work review 2

import 'package:beach_circle_flutter/community_goods/dorm_life/screens/dorm_create.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../community_goods/dorm_life/widgets/dorm_calendar.dart';
import '../community_goods/dorm_life/widgets/dorm_events.dart';
import '../community_goods/dorm_life/services/interested_dorm_service.dart';

// grabbing the current date & interested info
class DormlifeScreen extends StatefulWidget {
  const DormlifeScreen({super.key});

  @override
  State<DormlifeScreen> createState() => _DormlifeScreenState();
}

class _DormlifeScreenState extends State<DormlifeScreen> {
  DateTime selectedDate = DateTime.now();
  bool interestedOnly = false;

  // grab event time info
  Stream<QuerySnapshot<Map<String, dynamic>>> getEvents() {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
        // calculates the end of day
    final endOfDay = startOfDay.add(const Duration(days: 1));
        // firebase info fields
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
  // calculating date & spacing
  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
  // getting months of events
  Stream<Map<String, List<Color>>> getMonthEventDates() {
    final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
    final nextMonthStart = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      1,
    );
        // returns the firebase details of events
    return FirebaseFirestore.instance
        .collection('dorm_events')
        .where('status', isEqualTo: 'approved')
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
        )
        .where('startTime', isLessThan: Timestamp.fromDate(nextMonthStart))
        .snapshots() // calculates day based off start time
        .map((snapshot) {
          final Map<String, List<Color>> eventMap = {};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final dynamic startRaw = data['startTime'];
            final category = (data['category'] ?? 'Other').toString();
            // Student Work Review 3: made by Giselle
            if (startRaw is Timestamp) {
              final key = dateKey(startRaw.toDate());
              final color = eventColor(category);
              // grabs the color of event to put on calendar
              eventMap.putIfAbsent(key, () => []);
              if (!eventMap[key]!.contains(color)) {
                eventMap[key]!.add(color);
              }
            }
          }
          return eventMap;
        });
  }

  // Work Review 3: connected to firebase about users' pref of Interested events
  Stream<Set<String>> interestedEventIdsStream() {
    return InterestedDormService.interestedEventIdsStream();
  }

  Color eventColor(String category) {
        // the categories have colors to tell them apart
    switch (category) {
      case 'Social':
        return const Color.fromARGB(255, 249, 228, 155); // social events
      case 'Academic':
        return const Color(0xFFF5A623); // academic events
      case 'Meetings':
        return const Color.fromARGB(255, 255, 188, 144); // meetings
      case 'Announcements':
        return const Color(0xFF8DB600); // announcments
      case 'Tips':
        return const Color.fromARGB(255, 202, 196, 148); // tips
      case 'Other':
        return const Color.fromRGBO(136, 131, 83, 1); // others
      default:
        return const Color.fromRGBO(231, 148, 88, 1);
    }
  }

  // fixes the form of time with AM/PM
  String formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  // defining the months in the year & days in the week
  String verticalDate(DateTime date) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    const days = ['MON', 'TUES', 'WED', 'THURS', 'FRI', 'SAT', 'SUN'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  // ------ building the homepage ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2F2),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        // pencil icon
        backgroundColor: const Color(0xFFF2C200),
        onPressed: () {
          // MADE BY TIFF
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DormCreatePage()),
          );
        },
        child: const Icon(Icons.edit, color: Colors.black),
      ),
         // CHANGES BY TIFF END HERE
      body: SafeArea(
        child: Column(
          children: [

            // ── Header ────────────────────────────────────────────────────
            Container(
              color: const Color(0xFFFFD500),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Search bar
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

                  // CHANGED BY TIFF
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
                        color: const Color(0xFFE6841A), // always orange
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
            // CHANGEs BY TIFF END HERE
            // ── Calendar ──────────────────────────────────────────────────
            StreamBuilder<Map<String, List<Color>>>(
              stream: getMonthEventDates(),
              builder: (context, snapshot) {
                final eventDates = snapshot.data ?? <String, List<Color>>{};
                return DormCalendar(
                   // the selected date
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
                 // display previous month
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

            // ── Event list ────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<Set<String>>(
                stream: interestedEventIdsStream(),
                builder: (context, interestedSnap) {
                  final interestedIds = interestedSnap.data ?? <String>{};

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: getEvents(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      var docs = snapshot.data!.docs;

                      if (interestedOnly) {
                        docs = docs
                            .where((doc) => interestedIds.contains(doc.id))
                            .toList();
                      }
                      // when there are no events posted, display message
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
                      // fixing format to avoid crashes
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          final dynamic startRaw = data['startTime'];
                          final dynamic endRaw =
                              data['endTime'] ?? data['endTime '];
                          // Work Review 3: Handle format errors
                          if (startRaw == null || endRaw == null) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Missing startTime or endTime'),
                              ),
                            );
                          }

                          if (startRaw is! Timestamp ||
                              endRaw is! Timestamp) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'startTime or endTime is not a Timestamp',
                                ),
                              ),
                            );
                          }
                          // when events are added, display info
                          final start = startRaw.toDate();
                          final end = endRaw.toDate();
                          final isInterested =
                              interestedIds.contains(doc.id);

                          return DormEvents(
                            title: (data['title'] ??
                                    data['title '] ??
                                    '(No title)')
                                .toString(),
                            location: (data['location'] ?? 'No location')
                                .toString(),
                            body: (data['description'] ?? '').toString(),
                            dateLabel: verticalDate(start),
                            timeText:
                                '${formatTime(start)} - ${formatTime(end)}',
                            isInterested: isInterested,
                            onInterestedTap: () async {
                              try {
                                await InterestedDormService.toggleInterested(
                                  eventId: doc.id,
                                  isInterested: isInterested,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Could not update interested: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                            color: eventColor(
                              (data['category'] ?? 'Other').toString(),
                            ),
                            eventId: doc.id,
                            eventOwnerId: (data['createdBy'] ??
                                    data['authorId'] ??
                                    '')
                                .toString(),
                            imageUrl: data['imageUrl']?.toString(),
                            highlights: data['highlights'] != null
                                ? List<String>.from(data['highlights'])
                                : null,
                            flyerLink: data['flyerLink']?.toString(),
                            registrationLink:
                                data['registrationLink']?.toString(),
                            websiteLink: data['websiteLink']?.toString(),
                            instagramLink:
                                data['instagramLink']?.toString(),
                            contactEmail:
                                data['contactEmail']?.toString(),
                            interestedCount:
                                data['interestedCount'] is num
                                    ? (data['interestedCount'] as num)
                                        .toInt()
                                    : int.tryParse(
                                          data['interestedCount']
                                                  ?.toString() ??
                                              '',
                                        ) ??
                                        0,
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