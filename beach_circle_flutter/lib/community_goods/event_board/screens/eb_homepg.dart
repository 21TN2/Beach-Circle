// eb_homepg.dart
import 'package:flutter/material.dart';

import 'package:beach_circle_flutter/community_goods/event_board/models/eb_event.dart';
import 'package:beach_circle_flutter/community_goods/event_board/services/eb_services.dart';
import 'package:beach_circle_flutter/community_goods/event_board/services/interested_eb_service.dart';
import 'package:beach_circle_flutter/community_goods/event_board/widgets/eb_calendar.dart';
import 'package:beach_circle_flutter/community_goods/event_board/widgets/eb_events.dart';
import 'package:beach_circle_flutter/community_goods/event_board/screens/eb_create.dart';
import 'package:beach_circle_flutter/community_goods/event_board/screens/eb_interested.dart';

class EBHomePage extends StatefulWidget {
  const EBHomePage({super.key});

  @override
  State<EBHomePage> createState() => _EBHomePageState();
}

class _EBHomePageState extends State<EBHomePage> {
  static const Color kYellow    = Color(0xFFFFCC00);
  static const Color kYellowBtn = Color(0xFFD4A800);
  static const Color kPurple    = Color(0xFF3B3599);

  DateTime _selectedDate = DateTime.now();
  DateTime _displayMonth = DateTime.now();

  String _dateLabel(DateTime d) {
    const days = ['MON', 'TUES', 'WED', 'THURS', 'FRI', 'SAT', 'SUN'];
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  void _openCreatePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EBCreatePage()),
    );
  }

  void _openInterestedPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EBInterestedPage()),
    );
  }

  @override
  void initState() {
    super.initState();
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
        title: StreamBuilder<Set<String>>(
          stream: InterestedEBService.interestedEventIdsStream(),
          builder: (context, intSnap) {
            final hasInterested = (intSnap.data ?? {}).isNotEmpty;

            return Row(
              children: [
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
                            style: TextStyle(
                                color: Color(0xFF555555), fontSize: 15),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: kPurple),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _openInterestedPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: kYellowBtn,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasInterested ? Icons.star : Icons.star_border,
                          size: 18,
                          color: hasInterested
                              ? const Color(0xFFFFD700)
                              : Colors.black,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Interested',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),

      body: Stack(
        children: [
          // ── Background image ──────────────────────────────────────────
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/lb_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ── Foreground content ────────────────────────────────────────
          Column(
            children: [
              StreamBuilder<Map<String, List<EBCategory>>>(
                stream: EBServices.categoriesForMonthStream(_displayMonth),
                builder: (context, dotSnap) {
                  final catMap = dotSnap.data ?? {};
                  final eventDates = catMap.map(
                    (key, cats) => MapEntry(key, cats.map((c) => c.color).toList()),
                  );
                  return EBCalendar(
                    selectedDate: _selectedDate,
                    onDateSelected: (d) => setState(() => _selectedDate = d),
                    onPreviousMonth: _goToPreviousMonth,
                    onNextMonth: _goToNextMonth,
                    eventDates: eventDates,
                  );
                },
              ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<List<EBEvent>>(
              stream: EBServices.eventsForDateStream(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return const Center(
                    child: Text(
                      'No events for this day.',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  );
                }

                return StreamBuilder<Set<String>>(
                  stream: InterestedEBService.interestedEventIdsStream(),
                  builder: (context, intSnap) {
                    final interestedIds = intSnap.data ?? {};

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: events.length,
                      itemBuilder: (context, i) {
                        final event = events[i];
                        final isInterested = interestedIds.contains(event.id);

                        return EBEvents(
                          title: event.title,
                          location: event.location,
                          body: event.description,
                          dateLabel: _dateLabel(_selectedDate),
                          timeText: event.timeDisplay,
                          isInterested: isInterested,
                          color: event.category.color,
                          eventId: event.id,
                          eventOwnerId: event.createdBy ?? '',
                          flyerLink: event.links == 'null' ? null : event.links,
                          imageUrl: event.imageUrl,
                          interestedCount: event.interestedCount,
                          roomNumber: event.roomNumber.isEmpty ? null : event.roomNumber,
                          onInterestedTap: () async {
                            try {
                              await InterestedEBService.toggleInterested(
                                eventId: event.id,
                                isInterested: isInterested,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text('Sign in to mark interest.'),
                                  behavior: SnackBarBehavior.floating,
                                ));
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
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePage,
        backgroundColor: kYellow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit, color: Colors.black),
      ),
    );
  }
}