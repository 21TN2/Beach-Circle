import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beach_circle_flutter/moderation/report_issue_page.dart';

class ExpandedBathroomFinderPage extends StatelessWidget {
  const ExpandedBathroomFinderPage({
    super.key,
    required this.bathroomName,
    required this.buildingAbbrev,
    required this.distance,
    required this.details,
  });

  final String bathroomName;
  final String buildingAbbrev;
  final String distance;
  final String details;
  // header
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bathroom Details'),
        backgroundColor: const Color(0xFFF2D21B),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,

      //  Pull bathroom reviews for this building/restroom
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('bathroom_reviews')
                .where('bathroomName', isGreaterThanOrEqualTo: bathroomName)
                .where(
                  'bathroomName',
                  isLessThanOrEqualTo: '$bathroomName\uf8ff',
                )
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load bathroom reviews: ${snapshot.error}'),
            );
          }

          final reviews = snapshot.data?.docs ?? [];

          // Calculate overall average star rating and number of ratings
          double averageRating = 0;
          int ratingCount = 0;

          // Store each reviewed bathroom with its own rating, amenities, and comments
          final Map<String, Map<String, dynamic>> reviewedBathroomRatings = {};

          for (final doc in reviews) {
            final data = doc.data();

            final fullBathroomName =
                (data['bathroomName'] ?? '').toString().trim();

            final rating = data['rating'];

            //  Track rating, amenities, and comments for each individual bathroom
            if (fullBathroomName.isNotEmpty) {
              reviewedBathroomRatings.putIfAbsent(fullBathroomName, () {
                return {
                  'total': 0.0,
                  'count': 0,
                  'features': <String, int>{},
                  'comments': <String>[],
                  // Needed for bathroom moderation reports
                  'docId': doc.id,
                  'reportedUserId': (data['userId'] ?? '').toString(),
                };
              });
              // rating calculation
              if (rating is int) {
                reviewedBathroomRatings[fullBathroomName]!['total'] =
                    reviewedBathroomRatings[fullBathroomName]!['total'] +
                    rating;
                reviewedBathroomRatings[fullBathroomName]!['count'] =
                    reviewedBathroomRatings[fullBathroomName]!['count'] + 1;
              } else if (rating is double) {
                reviewedBathroomRatings[fullBathroomName]!['total'] =
                    reviewedBathroomRatings[fullBathroomName]!['total'] +
                    rating;
                reviewedBathroomRatings[fullBathroomName]!['count'] =
                    reviewedBathroomRatings[fullBathroomName]!['count'] + 1;
              }

              final features = data['features'];

              if (features is Map) {
                final bathroomFeatureCounts =
                    reviewedBathroomRatings[fullBathroomName]!['features']
                        as Map<String, int>;

                features.forEach((key, value) {
                  if (value == true) {
                    bathroomFeatureCounts[key.toString()] =
                        (bathroomFeatureCounts[key.toString()] ?? 0) + 1;
                  }
                });
              }

              //  Store comments under the specific bathroom review card
              final comment = (data['comments'] ?? '').toString().trim();

              if (comment.isNotEmpty) {
                final bathroomComments =
                    reviewedBathroomRatings[fullBathroomName]!['comments']
                        as List<String>;

                bathroomComments.add(comment);
              }
            }

            //  Overall rating calculation for the whole building
            if (rating is int) {
              averageRating += rating;
              ratingCount++;
            } else if (rating is double) {
              averageRating += rating;
              ratingCount++;
            }
          }

          if (ratingCount > 0) {
            averageRating = averageRating / ratingCount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 3,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F0FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wc,
                            color: Colors.blueAccent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            //  Shows building bathroom title
                            '$bathroomName Bathrooms',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    //  Shows full building name and abbreviation
                    _InfoRow(
                      icon: Icons.location_on,
                      label: 'Building',
                      value:
                          buildingAbbrev.isNotEmpty
                              ? '$bathroomName ($buildingAbbrev)'
                              : bathroomName,
                    ),

                    const SizedBox(height: 12),

                    _InfoRow(
                      icon: Icons.directions_walk,
                      label: 'Distance',
                      value: distance.isNotEmpty ? distance : 'N/A',
                    ),

                    const SizedBox(height: 20),

                    //  Average rating row for whole building
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          ratingCount > 0
                              ? averageRating.toStringAsFixed(1)
                              : 'No rating yet',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ratingCount == 1
                                ? '(1 person rated this)'
                                : '($ratingCount people rated this)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Show full bathroom names with individual average ratings, amenities, and comments
                    const Text(
                      'Reviewed Bathroom Names',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),
                    // no review yet
                    if (reviewedBathroomRatings.isEmpty)
                      Text(
                        'No specific bathroom names have been reviewed yet.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            reviewedBathroomRatings.entries.map((entry) {
                              final name = entry.key;
                              final total = entry.value['total'] as double;
                              final count = entry.value['count'] as int;
                              final average = count > 0 ? total / count : 0.0;

                              //  Needed for reporting this specific bathroom review
                              final docId =
                                  (entry.value['docId'] ?? '').toString();
                              final reportedUserId =
                                  (entry.value['reportedUserId'] ?? '')
                                      .toString();

                              final bathroomFeatures =
                                  entry.value['features'] as Map<String, int>;

                              final sortedBathroomFeatures =
                                  bathroomFeatures.entries.toList()..sort(
                                    (a, b) => b.value.compareTo(a.value),
                                  );

                              // Comments for this specific bathroom only
                              final bathroomComments =
                                  entry.value['comments'] as List<String>;

                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.wc,
                                      size: 22,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                count > 0
                                                    ? '${average.toStringAsFixed(1)} ($count)'
                                                    : 'No rating yet',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 10),

                                          //  Amenities for this specific bathroom only
                                          if (sortedBathroomFeatures.isEmpty)
                                            Text(
                                              'No amenities reported for this bathroom yet.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            )
                                          else
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children:
                                                  sortedBathroomFeatures.map((
                                                    feature,
                                                  ) {
                                                    return Chip(
                                                      label: Text(
                                                        '${feature.key} (${feature.value})',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      backgroundColor:
                                                          const Color(
                                                            0xFFE8F0FE,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              18,
                                                            ),
                                                        side: BorderSide(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade300,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                            ),

                                          const SizedBox(height: 10),

                                          //Comments for this specific bathroom only
                                          if (bathroomComments.isNotEmpty) ...[
                                            const Text(
                                              'Comments',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Column(
                                              children:
                                                  bathroomComments.map((
                                                    comment,
                                                  ) {
                                                    return Container(
                                                      width: double.infinity,
                                                      margin:
                                                          const EdgeInsets.only(
                                                            bottom: 6,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade300,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        comment,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          height: 1.35,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                            ),
                                          ],

                                          const SizedBox(height: 10),

                                          // Report this specific bathroom review
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed:
                                                  docId.isEmpty
                                                      ? null
                                                      : () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => ReportIssuePage(
                                                                  targetId:
                                                                      docId,
                                                                  reportedUserId:
                                                                      reportedUserId,
                                                                  targetType:
                                                                      'bathroom_review',
                                                                ),
                                                          ),
                                                        );
                                                      },
                                              // report wrong info
                                              icon: const Icon(
                                                Icons.flag_outlined,
                                              ),
                                              label: const Text(
                                                'Report Incorrect Info',
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.black87,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                side: const BorderSide(
                                                  color: Colors.black26,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// info: value, label, icon
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black54, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
