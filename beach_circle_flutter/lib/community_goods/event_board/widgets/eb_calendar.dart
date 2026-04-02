// eb_calendar.dart
import 'package:flutter/material.dart';

class EbCalendar extends StatefulWidget {
  const EbCalendar({
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
  final Map<String, List<Color>> eventDates;

  @override
  State<EbCalendar> createState() => _EbCalendarState();
}

class _EbCalendarState extends State<EbCalendar> {
  bool expanded = false;

  String monthLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<DateTime> get currentWeek {
    final selected = widget.selectedDate;
    final weekday = selected.weekday % 7; // Sunday = 0
    final startOfWeek = selected.subtract(Duration(days: weekday));
    return List.generate(
      7,
      (index) => DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      ),
    );
  }

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

  Widget buildDayBox(DateTime date) {
    final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
    final dots = widget.eventDates[dateKey(date)] ?? [];

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
            if (dots.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dots.take(3).map((color) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['Sun', 'Mon', 'Tues', 'Wed', 'Thur', 'Fri', 'Sat'];

    return Container(
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
                onPressed: expanded
                    ? widget.onPreviousMonth
                    : () {
                        widget.onDateSelected(
                          widget.selectedDate.subtract(const Duration(days: 7)),
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
                onPressed: expanded
                    ? widget.onNextMonth
                    : () {
                        widget.onDateSelected(
                          widget.selectedDate.add(const Duration(days: 7)),
                        );
                      },
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                onPressed: () => setState(() => expanded = !expanded),
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayLabels
                .map((day) => Expanded(
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
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          if (!expanded)
            SizedBox(
              height: 60,
              child: Row(
                children: currentWeek.map((date) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: buildDayBox(date),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (expanded)
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
                if (date == null) return const SizedBox.shrink();
                return buildDayBox(date);
              },
            ),
        ],
      ),
    );
  }
}