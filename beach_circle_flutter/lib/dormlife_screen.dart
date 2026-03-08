// Creating Dorm Life Home Page
// Made by Giselle --> for student work review 2
// TO DO: Create Home Page Functionality next

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../community_goods/dorm_life/widgets/dorm_calendar.dart';
import '../community_goods/dorm_life/widgets/dorm_events.dart';

class DormlifeScreen extends StatefulWidget {
  const DormlifeScreen({super.key});

  @override
  State<DormlifeScreen> createState() => _DormlifeScreenState();
}

// grabbing the current data & interested info (to do: will fix interested func)
class _DormlifeScreenState extends State<DormlifeScreen> {
  DateTime selectedDate = DateTime.now();
  bool interestedOnly = false;

  // grab the events time info : year, month, day
  Stream<QuerySnapshot<Map<String, dynamic>>> getEvents() {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    // calculates the end of day
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // firebase database info fields
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

  // calculating the date and spacing
  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// getting the month of event
  Stream<Set<String>> getMonthEventDates() {
    final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
    final nextMonthStart = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      1,
    );
    // returns the firebase details of the events
    return FirebaseFirestore.instance
        .collection('dorm_events')
        .where(
          'status',
          isEqualTo: 'approved',
        ) // looks to see if event is approved by mods
        .where(
          'startTime', // figures out the current date determined by start time
          isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
        )
        .where('startTime', isLessThan: Timestamp.fromDate(nextMonthStart))
        .snapshots()
        .map((snapshot) {
          final keys = <String>{};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final dynamic startRaw = data['startTime'];

            if (startRaw is Timestamp) {
              keys.add(dateKey(startRaw.toDate()));
            }
          }

          return keys;
        });
  }

  // TO DO: might need to adjust colors to have a nice color palette
  Color eventColor(String category) {
    // the categories have colors to tell them apart
    switch (category) {
      case 'Social':
        return Color.fromRGBO(170, 199, 103, 0.753); // social events
      case 'Academic':
        return const Color.fromRGBO(154, 194, 201, 1); // academic events
      case 'Wellness':
        return const Color.fromRGBO(140, 187, 221, 1); // wellness events
      case 'Meetings':
        return const Color.fromARGB(255, 230, 219, 105); // meetings
      case 'Announcements':
        return const Color.fromARGB(255, 231, 188, 89); // announcments
      case 'Tips':
        return const Color.fromARGB(255, 133, 212, 143); // tips
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

  // fixes the form of time with AM/PM
  String formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  // defining the months to have a proper format
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

  // ----- building the homepage -----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2F2), // background color
      floatingActionButton: FloatingActionButton(
        // pencil icon
        backgroundColor: const Color(0xFFF2C200),
        onPressed: () {
          // TODO: open create dorm event page
        },
        child: const Icon(Icons.edit, color: Colors.black),
      ),
      body: SafeArea(
        // for our header
        child: Column(
          children: [
            Container(
              color: const Color(0xFFFFD500), // header color
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
                              'Dorm Life', // header title
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
                        interestedOnly =
                            !interestedOnly; // our interested button
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6841A), // interested box color
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            interestedOnly
                                ? Icons.star
                                : Icons.star_border, // interested icon
                            color: Colors.black87,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Interested', // interested button text
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // for our dorm calendar formatting
            StreamBuilder<Set<String>>(
              stream: getMonthEventDates(),
              builder: (context, snapshot) {
                final eventDates = snapshot.data ?? <String>{};

                return DormCalendar(
                  // the selected data
                  selectedDate: selectedDate,
                  eventDates: eventDates,
                  onDateSelected: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                  onPreviousMonth: () {
                    // display previous month
                    setState(() {
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month - 1,
                        1,
                      );
                    });
                  },
                  onNextMonth: () {
                    // display next month
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

            // error handling: if firebase isnt working
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: getEvents(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data!.docs;

                  print("Selected date: $selectedDate");
                  print("Docs length: ${docs.length}");
                  for (final doc in docs) {
                    print("Firestore doc: ${doc.data()}");
                  }

                  if (interestedOnly) {
                    docs =
                        docs
                            .where(
                              (doc) =>
                                  (doc.data()['isStarred'] ?? false) == true,
                            )
                            .toList();
                  }
                  // when theres no events posted, show to user
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No events for this day.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    );
                  }
                  // when events are present, show info to  user
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ), // format
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();

                      final dynamic startRaw = data['startTime']; // start time
                      final dynamic endRaw =
                          data['endTime'] ?? data['endTime ']; // end time

                      final start = startRaw.toDate();
                      final end = endRaw.toDate();

                      return DormEvents(
                        title:
                            (data['title'] ??
                                    data['title '] ??
                                    '(No title)') // title
                                .toString(),
                        location:
                            (data['location'] ?? 'No location')
                                .toString(), // location
                        body:
                            (data['description'] ?? '')
                                .toString(), // description
                        dateLabel: verticalDate(start),
                        timeText:
                            '${formatTime(start)} - ${formatTime(end)}', // the proper time
                        isStarred:
                            (data['isStarred'] ?? false) ==
                            true, // if the user starred it
                        color: eventColor(
                          (data['category'] ?? 'Other')
                              .toString(), // category color
                        ),
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
