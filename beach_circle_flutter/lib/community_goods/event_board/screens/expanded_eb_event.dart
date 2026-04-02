// expanded_eb_event.dart
// Expanded view shown when user taps the arrow on an event card.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:beach_circle_flutter/community_goods/smf/screens/report_issue_pg.dart';

class ExpandedEBEventPg extends StatelessWidget {
  const ExpandedEBEventPg({
    super.key,
    required this.title,
    required this.location,
    required this.body,
    required this.dateLabel,
    required this.timeText,
    required this.eventId,
    required this.eventOwnerId,
    required this.isInterested,
    required this.onInterestedTap,
    this.flyerLink,
    this.registrationLink,
    this.imageUrl,
    this.highlights,
    this.interestedCount,
    this.websiteLink,
    this.instagramLink,
    this.contactEmail,
    this.roomNumber,
  });

  final String title;
  final String location;
  final String body;
  final String dateLabel;
  final String timeText;
  final String eventId;
  final String eventOwnerId;
  final bool isInterested;
  final VoidCallback onInterestedTap;
  final String? flyerLink;
  final String? registrationLink;
  final String? imageUrl;
  final List<String>? highlights;
  final int? interestedCount;
  final String? websiteLink;
  final String? instagramLink;
  final String? contactEmail;
  final String? roomNumber;

  static const Color kYellow   = Color(0xFFFFCC00);
  static const Color kGold     = Color(0xFFD1A000);
  static const Color kCardGrey = Color(0xFFE8E8E8);
  static const Color kPurple   = Color(0xFF3B3599);

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
    final hasBody         = body.trim().isNotEmpty;
    final hasFlyerLink    = flyerLink != null && flyerLink!.trim().isNotEmpty && flyerLink != 'null';
    final hasRegLink      = registrationLink != null && registrationLink!.trim().isNotEmpty;
    final hasWebsite      = websiteLink != null && websiteLink!.trim().isNotEmpty;
    final hasInstagram    = instagramLink != null && instagramLink!.trim().isNotEmpty;
    final hasEmail        = contactEmail != null && contactEmail!.trim().isNotEmpty;
    final hasAnyLink      = hasFlyerLink || hasRegLink || hasWebsite || hasInstagram || hasEmail;
    final hasHighlights   = highlights != null && highlights!.isNotEmpty;
    final hasRoom         = roomNumber != null && roomNumber!.isNotEmpty;

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
                        style: TextStyle(color: Color(0xFF555555), fontSize: 15),
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

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.25,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 24),

            // Image
            if (imageUrl != null && imageUrl!.isNotEmpty) ...[
              Image.network(imageUrl!, width: double.infinity, fit: BoxFit.contain),
              const SizedBox(height: 24),
            ],

            // Date / Location / Time
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: kCardGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCell(icon: Icons.calendar_month_outlined, label: 'Date', value: dateLabel),
                  _Divider(),
                  _InfoCell(icon: Icons.location_on_outlined, label: 'Location', value: location),
                  _Divider(),
                  _InfoCell(icon: Icons.access_time_outlined, label: 'Time', value: timeText),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Description
            if (hasBody)
              _SectionCard(
                title: 'Description',
                child: Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14, height: 1.65,
                    color: Colors.black87, fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (hasBody) const SizedBox(height: 20),

            // Highlights
            if (hasHighlights)
              _SectionCard(
                title: 'Highlights',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: highlights!.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.w700)),
                        Expanded(child: Text(h,
                            style: const TextStyle(fontSize: 14, height: 1.5))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            if (hasHighlights) const SizedBox(height: 20),

            // Links
            if (hasAnyLink)
              _SectionCard(
                title: 'Links',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasFlyerLink)
                      _LinkRow(label: 'Flyer', url: flyerLink!, onTap: () => _openLink(context, flyerLink!)),
                    if (hasRegLink)
                      _LinkRow(label: 'Register', url: registrationLink!, onTap: () => _openLink(context, registrationLink!)),
                    if (hasWebsite)
                      _LinkRow(label: 'Website', url: websiteLink!, onTap: () => _openLink(context, websiteLink!)),
                    if (hasInstagram)
                      _LinkRow(label: 'Instagram', url: instagramLink!, onTap: () => _openLink(context, instagramLink!)),
                    if (hasEmail)
                      _LinkRow(label: 'Contact', url: contactEmail!, onTap: () => _openLink(context, 'mailto:$contactEmail')),
                  ],
                ),
              ),
            if (hasAnyLink) const SizedBox(height: 20),

            // Room
            if (hasRoom)
              _SectionCard(
                title: 'Room',
                child: Text(
                  'Room $roomNumber',
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87,
                  ),
                ),
              ),
            if (hasRoom) const SizedBox(height: 20),

            // Interested count
            if (interestedCount != null && interestedCount! > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$interestedCount interested',
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

            // Report button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportIssuePage(
                        targetId: eventId,
                        reportedUserId: eventOwnerId,
                        targetType: 'event',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD6D6D6), width: 1.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(Icons.flag_outlined, color: Colors.black),
                label: const Text(
                  'Report Event',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCell({required this.icon, required this.label, required this.value});
  static const Color kGold = Color(0xFFD1A000);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: kGold, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.35)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 70,
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
      decoration: BoxDecoration(color: kCardGrey, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kGold, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String url;
  final VoidCallback onTap;
  const _LinkRow({required this.label, required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Expanded(
              child: Text(url,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}