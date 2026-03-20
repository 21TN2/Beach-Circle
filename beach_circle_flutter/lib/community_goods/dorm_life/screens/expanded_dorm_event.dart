// Work Review 3: Made by Giselle
// Purpose: when users want to see more details of event

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpandedDormEventPg extends StatelessWidget {
  const ExpandedDormEventPg({
    super.key,
    required this.title,
    required this.location,
    required this.body,
    required this.dateLabel,
    required this.timeText,
    // optional fields
    this.flyerLink,
    this.registrationLink,
    this.imageUrl,
    this.highlights,
    this.interestedCount,
    this.websiteLink,
    this.instagramLink,
    this.contactEmail,
  });

  final String title;
  final String location;
  final String body;
  final String dateLabel;
  final String timeText;

  final String? flyerLink;
  final String? registrationLink;

  final String? imageUrl;
  final List<String>? highlights;
  final int? interestedCount;

  final String? websiteLink;
  final String? instagramLink;
  final String? contactEmail;

  static const Color _bcYellow = Color(0xFFF2C400);
  static const Color _cardGrey = Color(0xFFE5E5E5);
  static const Color _accentGold = Color(0xFFD1B000);

  Future<void> _openLink(BuildContext context, String url) async {
    final trimmedUrl = url.trim();

    final formattedUrl =
        trimmedUrl.startsWith('http://') ||
                trimmedUrl.startsWith('https://') ||
                trimmedUrl.startsWith('mailto:')
            ? trimmedUrl
            : 'https://$trimmedUrl';

    final uri = Uri.parse(formattedUrl);

    final didLaunch = await launchUrl(uri, mode: LaunchMode.platformDefault);

    if (!didLaunch && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
    }
  }

  String _formatInstagramUrl(String value) {
    final trimmedValue = value.trim();

    if (trimmedValue.startsWith('http://') ||
        trimmedValue.startsWith('https://')) {
      return trimmedValue;
    }

    final handle =
        trimmedValue.startsWith('@') ? trimmedValue.substring(1) : trimmedValue;

    return 'https://instagram.com/$handle';
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.black),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _accentGold,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _accentGold,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _linkRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPlainText = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            label,
            style:
                isPlainText
                    ? const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    )
                    : const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFlyer = flyerLink != null && flyerLink!.trim().isNotEmpty;
    final hasRegistration =
        registrationLink != null && registrationLink!.trim().isNotEmpty;
    final hasLinks = hasFlyer || hasRegistration;

    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasHighlights = highlights != null && highlights!.isNotEmpty;
    final hasInterestedCount = interestedCount != null;
    final hasWebsite = websiteLink != null && websiteLink!.trim().isNotEmpty;
    final hasInstagram =
        instagramLink != null && instagramLink!.trim().isNotEmpty;
    final hasEmail = contactEmail != null && contactEmail!.trim().isNotEmpty;
    final hasStayConnected = hasWebsite || hasInstagram || hasEmail;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _bcYellow,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 78,
        titleSpacing: 12,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Event Board",
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.blue),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 18),

            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: 180,
                        color: _cardGrey,
                        alignment: Alignment.center,
                        child: const Text(
                          "Image failed to load",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 22),
            ],

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              decoration: BoxDecoration(
                color: _cardGrey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoItem(
                    icon: Icons.calendar_month,
                    label: "Date",
                    value: dateLabel,
                  ),
                  const SizedBox(width: 10),
                  _infoItem(
                    icon: Icons.location_on_outlined,
                    label: "Location",
                    value: location,
                  ),
                  const SizedBox(width: 10),
                  _infoItem(
                    icon: Icons.access_time,
                    label: "Time",
                    value: timeText,
                  ),
                ],
              ),
            ),

            if (hasInterestedCount) ...[
              const SizedBox(height: 22),
              _sectionCard(
                title: "Interested",
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 26),
                    const SizedBox(width: 10),
                    Text(
                      "$interestedCount people are interested",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            _sectionCard(
              title: "Description",
              child: Text(
                body.isEmpty ? "No description available." : body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (hasHighlights) ...[
              const SizedBox(height: 22),
              _sectionCard(
                title: "Good to Know",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      highlights!
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "• ",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],

            if (hasLinks) ...[
              const SizedBox(height: 22),
              _sectionCard(
                title: "Links",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasFlyer)
                      _linkRow(
                        icon: Icons.picture_as_pdf_outlined,
                        label: "View Flyer",
                        onTap: () => _openLink(context, flyerLink!),
                      ),
                    if (hasFlyer && hasRegistration) const SizedBox(height: 10),
                    if (hasRegistration)
                      _linkRow(
                        icon: Icons.app_registration,
                        label: "Register Here",
                        onTap: () => _openLink(context, registrationLink!),
                      ),
                  ],
                ),
              ),
            ],

            if (hasStayConnected) ...[
              const SizedBox(height: 22),
              _sectionCard(
                title: "Stay Connected",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasWebsite)
                      _linkRow(
                        icon: Icons.language,
                        label: "Visit Website",
                        onTap: () => _openLink(context, websiteLink!),
                      ),
                    if (hasWebsite && (hasInstagram || hasEmail))
                      const SizedBox(height: 10),
                    if (hasInstagram)
                      _linkRow(
                        icon: Icons.camera_alt_outlined,
                        label: instagramLink!,
                        isPlainText: true,
                        onTap:
                            () => _openLink(
                              context,
                              _formatInstagramUrl(instagramLink!),
                            ),
                      ),
                    if (hasEmail && (hasWebsite || hasInstagram))
                      const SizedBox(height: 10),
                    if (hasEmail)
                      _linkRow(
                        icon: Icons.email_outlined,
                        label: contactEmail!,
                        isPlainText: true,
                        onTap: () => _openLink(context, 'mailto:$contactEmail'),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Event reporting coming soon."),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD6D6D6), width: 1.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(Icons.flag_outlined, color: Colors.black),
                label: const Text(
                  "Report Event",
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
    );
  }
}
