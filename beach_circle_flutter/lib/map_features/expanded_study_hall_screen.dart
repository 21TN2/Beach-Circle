import 'package:flutter/material.dart';

class ExpandedStudyHallScreen extends StatelessWidget {
  const ExpandedStudyHallScreen({
    super.key,
    required this.title,
    required this.buildingName,
    required this.startTime,
    required this.endTime,
    required this.seats,
    required this.amenities,
  });

  final String title;
  final String buildingName;
  final String startTime;
  final String endTime;
  final int? seats;
  final List<String> amenities;

  TimeOfDay? _parseTime(String value) {
    try {
      final parts = value.trim().split(' ');
      if (parts.length != 2) return null;

      final timePart = parts[0];
      final periodPart = parts[1].toUpperCase();

      final timePieces = timePart.split(':');
      if (timePieces.length != 2) return null;

      int hour = int.parse(timePieces[0]);
      final minute = int.parse(timePieces[1]);

      if (periodPart == 'PM' && hour != 12) {
        hour += 12;
      } else if (periodPart == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  bool _isAvailableNow() {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    if (start == null || end == null) return false;

    final now = TimeOfDay.now();

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final availabilityText =
        startTime.isNotEmpty && endTime.isNotEmpty
            ? '$startTime - $endTime'
            : 'Not provided';

    final isAvailable = _isAvailableNow();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Hall Details'),
        backgroundColor: const Color(0xFFF2D21B),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F7F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F0FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (buildingName.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            buildingName,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                isAvailable ? 'Available Now' : 'Unavailable Now',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 18),

            _SectionCard(
              title: 'Availability Hours',
              child: Text(
                availabilityText,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 14),

            _SectionCard(
              title: 'Seat Capacity',
              child: Text(
                seats != null ? seats.toString() : 'Not provided',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 14),

            _SectionCard(
              title: 'Amenities',
              child:
                  amenities.isEmpty
                      ? const Text(
                        'No amenities listed.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      )
                      : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            amenities.map((amenity) {
                              return Chip(
                                label: Text(amenity),
                                backgroundColor: const Color(0xFFF3F3F3),
                                side: BorderSide.none,
                              );
                            }).toList(),
                      ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report feature coming soon.'),
                    ),
                  );
                },
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report Incorrect Info'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.black26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
