// eb_date_strip.dart
import 'package:flutter/material.dart';
import 'package:beach_circle_flutter/community_goods/event_board/models/eb_event.dart';
import 'package:beach_circle_flutter/community_goods/event_board/services/eb_services.dart';
import 'eb_category_dot.dart';

class EbDateStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime startDate;
  final int dayRange;

  EbDateStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    DateTime? startDate,
    this.dayRange = 30,
  }) : startDate = startDate ?? selectedDate.subtract(const Duration(days: 3));

  @override
  State<EbDateStrip> createState() => _EbDateStripState();
}

class _EbDateStripState extends State<EbDateStrip> {
  late ScrollController _scroll;
  late List<DateTime> _days;

  final Map<String, List<EventBoardCategory>> _dotCache = {};

  static const double _itemWidth = 64.0;

  static const _dayNames = ['MON', 'TUES', 'WED', 'THURS', 'FRI', 'SAT', 'SUN'];

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _days = List.generate(
      widget.dayRange,
      (i) => widget.startDate.add(Duration(days: i)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
      _loadDots();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadDots() async {
    for (final day in _days) {
      final key = '${day.year}-${day.month}-${day.day}';
      if (_dotCache.containsKey(key)) continue;
      final cats = await EbServices.categoriesOnDay(day);
      if (mounted) setState(() => _dotCache[key] = cats);
    }
  }

  void _scrollToSelected() {
    final idx = _days.indexWhere((d) =>
        d.year == widget.selectedDate.year &&
        d.month == widget.selectedDate.month &&
        d.day == widget.selectedDate.day);
    if (idx < 0 || !_scroll.hasClients) return;
    final screenW = MediaQuery.of(context).size.width;
    final offset = (idx * _itemWidth) - (screenW / 2) + (_itemWidth / 2);
    _scroll.animateTo(
      offset.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _days.length,
        itemBuilder: (context, i) {
          final day = _days[i];
          final isSelected = day.year == widget.selectedDate.year &&
              day.month == widget.selectedDate.month &&
              day.day == widget.selectedDate.day;
          final key = '${day.year}-${day.month}-${day.day}';
          final cats = _dotCache[key] ?? [];

          return GestureDetector(
            onTap: () {
              widget.onDateSelected(day);
              _scrollToSelected();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _itemWidth,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.black87, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayNames[day.weekday - 1],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  EbCategoryDotRow(categories: cats, dotSize: 9),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}