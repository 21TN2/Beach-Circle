import 'package:flutter/material.dart';

class ExpandedOutletScreen extends StatelessWidget {
  const ExpandedOutletScreen({
    super.key,
    required this.title,
    required this.buildingName,
    required this.outletCount,
    required this.outletTypes,
    required this.accessibilityLevels,
  });

  final String title;
  final String buildingName;
  final int? outletCount;
  final List<String> outletTypes;
  final List<String> accessibilityLevels;

  @override
  Widget build(BuildContext context) {
    final normalizedAccessibility =
        accessibilityLevels.map((e) => e.toLowerCase()).toList();

    final bool hasPlentiful =
        (outletCount ?? 0) > 5 &&
        normalizedAccessibility.any((e) => e.contains('easy access')) &&
        outletTypes.length > 1;

    final bool hasLimited =
        normalizedAccessibility.any((e) => e.contains('limited outlets')) ||
        normalizedAccessibility.any((e) => e.contains('hard to reach')) ||
        normalizedAccessibility.any((e) => e.contains('obstruction'));

    final String outletStatus =
        hasPlentiful
            ? 'Plentiful Outlets'
            : hasLimited
            ? 'Limited Access'
            : 'Standard Access';
    Color statusColor;
    if (outletStatus == 'Plentiful Outlets') {
      statusColor = const Color(0xFF43A047);
    } else if (outletStatus == 'Limited Access') {
      statusColor = const Color(0xFFEF6C00);
    } else {
      statusColor = const Color(0xFF5C6BC0);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outlet Details'),
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
                      color: Color(0xFFFFF4B3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.power_outlined,
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

            const SizedBox(height: 18),

            _SectionCard(
              title: 'Outlet Access',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  outletStatus,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            _SectionCard(
              title: 'Number of Outlets',
              child: Text(
                outletCount != null ? outletCount.toString() : 'Not provided',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 14),

            _SectionCard(
              title: 'Outlet Type',
              child:
                  outletTypes.isEmpty
                      ? const Text(
                        'No outlet type listed.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      )
                      : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            outletTypes.map((type) {
                              return Chip(
                                label: Text(type),
                                backgroundColor: const Color(0xFFF3F3F3),
                                side: BorderSide.none,
                              );
                            }).toList(),
                      ),
            ),

            const SizedBox(height: 14),

            _SectionCard(
              title: 'Accessibility Level',
              child:
                  accessibilityLevels.isEmpty
                      ? const Text(
                        'No accessibility details listed.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      )
                      : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            accessibilityLevels.map((level) {
                              return Chip(
                                label: Text(level),
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
