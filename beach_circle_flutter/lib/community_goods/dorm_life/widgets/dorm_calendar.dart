// Made by Giselle for Student Work Review 2
// This is for the Dorm Life Calendar
// Basically how we set up the calendar: expanded and weekly view
// shows the correct days of the month

import 'package:flutter/material.dart';

// needs selected data, prev month, next month, event data
class DormCalendar extends StatefulWidget {
  const DormCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.eventDates,
  });

  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Set<String> eventDates;

  @override
  State<DormCalendar> createState() => _DormCalendarState();
}

// default calendar state --> basically its in a weekly format unless expanded by user
class _DormCalendarState extends State<DormCalendar> {
  bool expanded = false;

  // months: jan - dec
  String monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}'; // adds the year
  }

  // format data with year month day
  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // grabs the current week
  List<DateTime> get currentWeek {
    final selected = widget.selectedDate;
    final weekday = selected.weekday % 7;
    final startOfWeek = selected.subtract(Duration(days: weekday));

    // how the list (calendar) will look like. start of the week is sunday
    return List.generate(
      7,
      (index) => DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      ),
    );
  }

  // how many days are in a month
  List<DateTime?> get monthDays {
    final firstDayOfMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );

    final daysInMonth = DateUtils.getDaysInMonth(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
    // week days
    final leadingEmptyDays = firstDayOfMonth.weekday % 7;

    final List<DateTime?> days = [];

    for (int i = 0; i < leadingEmptyDays; i++) {
      days.add(null);
    }

    for (int day = 1; day <= daysInMonth; day++) {
      days.add(
        DateTime(widget.selectedDate.year, widget.selectedDate.month, day),
      );
    }

    return days;
  }

  /// builds the calendar now
  Widget buildDayBox(DateTime date) {
    final isSelected = DateUtils.isSameDay(
      date,
      widget.selectedDate,
    ); // when user selects a day
    final hasEvent = widget.eventDates.contains(
      dateKey(date),
    ); // adds a dot when a day has an event

    // when user selected a date
    return GestureDetector(
      onTap: () => widget.onDateSelected(date),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black54 : Colors.black12,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            if (hasEvent) // checks if it has an event --> shows a circle icon to indicate it has one
              Container(
                // TO DO: find a way for the circle to correspond with number of events maybe?
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // building weekly view
  @override
  Widget build(BuildContext context) {
    const weekdayLabels = [
      'Sun',
      'Mon',
      'Tues',
      'Wed',
      'Thur',
      'Fri',
      'Sat',
    ]; // starts with sunday, ends with sat

    return Container(
      // calendar weekly view
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: // when user press to view other weeks previous
                    expanded
                        ? widget.onPreviousMonth
                        : () {
                          widget.onDateSelected(
                            widget.selectedDate.subtract(
                              const Duration(days: 7),
                            ),
                          );
                        },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthLabel(widget.selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              IconButton(
                // when user press to view future dates based on week
                onPressed:
                    expanded
                        ? widget.onNextMonth
                        : () {
                          widget.onDateSelected(
                            widget.selectedDate.add(const Duration(days: 7)),
                          );
                        },
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                // when users want to expand the calendar
                onPressed: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround, // adjusts the calendar view
            children:
                weekdayLabels
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 8),

          if (!expanded) // not expanded, this is the default format
            SizedBox(
              height: 60,
              child: Row(
                children:
                    currentWeek.map((date) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: buildDayBox(date),
                        ),
                      );
                    }).toList(),
              ),
            ),

          if (expanded) // when expanded, it'll show as a whole calendar
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: monthDays.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final date = monthDays[index];

                if (date == null) {
                  return const SizedBox.shrink();
                }

                return buildDayBox(date);
              },
            ),
        ],
      ),
    );
  }
}
