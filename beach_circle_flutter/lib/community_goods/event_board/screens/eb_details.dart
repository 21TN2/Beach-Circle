// eb_details.dart
// Expanded detail view for a single Event Board event.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:beach_circle_flutter/community_goods/event_board/models/eb_event.dart';
import 'package:beach_circle_flutter/community_goods/event_board/services/interested_eb_service.dart';
import 'package:beach_circle_flutter/community_goods/smf/screens/report_issue_pg.dart';

class EbDetailsPage extends StatelessWidget {
  const EbDetailsPage({
    super.key,
    required this.event,
    required this.isInterested,
    required this.onInterestedTap,
  });

  final EventBoardEvent event;
  final bool isInterested;
  final VoidCallback onInterestedTap;

  static const Color kYellow   = Color(0xFFFFCC00);
  static const Color kGold     = Color(0xFFD1A000);
  static const Color kCardGrey = Color(0xFFE8E8E8);
  static const Color kPurple   = Color(0xFF3B3599);

  String get _dateLabel {
    const months = [
      'Jan.', 'Feb.', 'Mar.', 'Apr.', 'May', 'Jun.',
      'Jul.', 'Aug.', 'Sep.', 'Oct.', 'Nov.', 'Dec.',
    ];
    return '${months[event.date.month - 1]} ${event.date.day}';
  }

  Future<void> _openLink(BuildContext context, String raw) async {
    final trimmed = raw.trim();
    final formatted = (trimmed.startsWith('http://') ||
            trimmed.startsWith('https://') ||
            trimmed.startsWith('mailto:'))
        ? trimmed
        : 'https://$trimmed';
    final uri = Uri.parse(formatted);
    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription = event.description.trim().isNotEmpty;
    final hasLinks       = event.links.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,

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
                        style:
                            TextStyle(color: Color(0xFF555555), fontSize: 15),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: kPurple),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: onInterestedTap,
              child: Icon(
                isInterested ? Icons.star : Icons.star_border,
                color: isInterested ? const Color(0xFFFFD700) : Colors.black,
                size: 26,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            Text(
              event.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.25,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 24),

            if (event.imageUrl != null && event.imageUrl!.isNotEmpty) ...[
              Image.network(
                event.imageUrl!,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
            ],

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: kCardGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCell(
                    icon: Icons.calendar_month_outlined,
                    label: 'Date',
                    value: _dateLabel,
                  ),
                  _Divider(),
                  _InfoCell(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: event.location,
                  ),
                  _Divider(),
                  _InfoCell(
                    icon: Icons.access_time_outlined,
                    label: 'Time',
                    value: event.timeDisplay,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (hasDescription)
              _SectionCard(
                title: 'Description',
                child: Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (hasDescription) const SizedBox(height: 20),

            if (hasLinks)
              _SectionCard(
                title: 'Links',
                child: GestureDetector(
                  onTap: () => _openLink(context, event.links),
                  child: Text(
                    event.links,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

            if (hasLinks) const SizedBox(height: 20),

            if (event.roomNumber.isNotEmpty)
              _SectionCard(
                title: 'Room',
                child: Text(
                  '${event.buildingCode} – Room ${event.roomNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),

            if (event.roomNumber.isNotEmpty) const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportIssuePage(
                        targetId: event.id,
                        reportedUserId: event.id,
                        targetType: 'event',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Color(0xFFD6D6D6), width: 1.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(Icons.flag_outlined, color: Colors.black),
                label: const Text(
                  'Report Event',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFD8D8D8))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.home, color: kPurple, size: 28),
            Icon(Icons.location_on_outlined, color: kPurple, size: 28),
            Icon(Icons.layers_outlined, color: kPurple, size: 28),
            Icon(Icons.settings_outlined, color: kPurple, size: 28),
          ],
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color kGold = Color(0xFFD1A000);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: kGold, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.35)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 70,
      color: const Color(0xFFCCCCCC),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  static const Color kGold     = Color(0xFFD1A000);
  static const Color kCardGrey = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: kGold, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}