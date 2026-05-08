// This is for Mods Only
// only Rey, Josue, Tiff, Theresa, and I can access + view
// Appears in Dashboard to see reports
// Made by Giselle ---> for student work review 2

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beach_circle_flutter/community_goods/smf/service/forum_service.dart';

class ModerationViewScreen extends StatelessWidget {
  const ModerationViewScreen({super.key, required this.forumService});

  final ForumService forumService;

  // mods emails associated with their account
  static const List<String> adminEmails = [
    'teef@gmail.com',
    'reytest@gmail.com',
    'giselle1@gmail.com',
    'nguyentheresa204@gmail.com',
    'josuealfaro8441@gmail.com',
  ];

  /// checks if user is admin or not
  bool get isModerator {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    return email != null &&
        adminEmails.map((e) => e.toLowerCase()).contains(email);
  }

  @override
  Widget build(BuildContext context) {
    if (!isModerator) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moderation')),
        body: const Center(child: Text('You do not have access to this page.')),
      );
    }

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moderation'),
          bottom: const TabBar(tabs: [Tab(text: 'Map Features Reports')]),
        ),
        body: const TabBarView(children: [_ReportsTab()]),
      ),
    );
  }
}

// ------------------- Reports Tab -------------------
class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Could not load image.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _displayTargetType(String targetType) {
    switch (targetType) {
      case 'post':
      case 'forum_post':
        return 'Forum Post';

      case 'event':
      case 'dorm_event':
        return 'Dorm Event';

      case 'outlet':
        return 'Outlet';

      case 'study_hall':
        return 'Study Hall';

      case 'bathroom_review':
        return 'Bathroom Review';

      case 'food_alert':
        return 'Food Alert';

      default:
        return targetType.isEmpty ? 'Unknown' : targetType;
    }
  }

  String? _collectionForTargetType(String targetType) {
    switch (targetType) {
      case 'post':
      case 'forum_post':
        return 'forumPosts';

      case 'event':
      case 'dorm_event':
        return 'dorm_events';

      case 'outlet':
        return 'outlets';

      case 'study_hall':
        return 'study_halls';

      case 'bathroom_review':
        return 'bathroom_reviews';

      case 'food_alert':
        return 'food_alerts';

      default:
        return null;
    }
  }

  String _deleteButtonText(String targetType) {
    switch (targetType) {
      case 'post':
      case 'forum_post':
        return 'Delete Post';

      case 'event':
      case 'dorm_event':
        return 'Delete Dorm Event';

      case 'outlet':
        return 'Delete Outlet';

      case 'study_hall':
        return 'Delete Study Hall';

      case 'bathroom_review':
        return 'Delete Bathroom Review';

      case 'food_alert':
        return 'Delete Food Alert';

      default:
        return 'Close Report';
    }
  }

  String _deleteSuccessText(String targetType) {
    switch (targetType) {
      case 'post':
      case 'forum_post':
        return 'Post deleted --> report closed';

      case 'event':
      case 'dorm_event':
        return 'Dorm Event deleted --> report closed';

      case 'outlet':
        return 'Outlet deleted --> report closed';

      case 'study_hall':
        return 'Study Hall deleted --> report closed';

      case 'bathroom_review':
        return 'Bathroom review deleted --> report closed';

      case 'food_alert':
        return 'Food alert deleted --> report closed';

      default:
        return 'Report closed';
    }
  }

  Future<void> _closeReport({
    required String reportId,
    required String moderatorNote,
  }) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({
          'status': 'closed',
          'closedAt': FieldValue.serverTimestamp(),
          'moderatorNote': moderatorNote,
        });
  }

  Future<void> _deleteReportedContentAndClose({
    required String reportId,
    required String targetId,
    required String targetType,
  }) async {
    final collectionName = _collectionForTargetType(targetType);

    if (collectionName != null) {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(targetId)
          .delete();

      await _closeReport(
        reportId: reportId,
        moderatorNote: '${_displayTargetType(targetType)} deleted by moderator',
      );

      return;
    }

    // fallback if targetType is unknown
    await _closeReport(
      reportId: reportId,
      moderatorNote: 'Closed by moderator',
    );
  }

  // NEW FROM GISELLE REVIEW 4: preview reported content for moderators
  Widget _buildReportedContentPreview({
    required String targetId,
    required String targetType,
  }) {
    if (targetId.isEmpty) {
      return const SizedBox.shrink();
    }

    final collectionName = _collectionForTargetType(targetType);

    if (collectionName == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection(collectionName)
              .doc(targetId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final doc = snapshot.data!;

        if (!doc.exists) {
          return const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Reported content no longer exists.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final data = doc.data()!;

        String title = '(No title)';
        String subtitle = '';
        String extra = '';
        // target post: either post or map feature or forum
        if (targetType == 'post' || targetType == 'forum_post') {
          title = (data['title'] ?? '(No title)').toString();
          subtitle = (data['body'] ?? '(No body)').toString();
        } else if (targetType == 'outlet') {
          final building = (data['buildingAbbrev'] ?? '').toString();
          final room = (data['roomNumber'] ?? '').toString();
          final outletCount =
              (data['outletCount'] ?? 'Not provided').toString();

          title =
              building.isNotEmpty ? '$building Room $room' : 'Outlet Listing';

          subtitle = 'Number of outlets: $outletCount';

          final outletTypes = List<String>.from(data['outletTypes'] ?? []);
          final accessibilityLevels = List<String>.from(
            data['accessibilityLevels'] ?? [],
          );
          // accessibility and types from outlets + study hall fields
          extra =
              'Types: ${outletTypes.isEmpty ? "None listed" : outletTypes.join(", ")}\n'
              'Accessibility: ${accessibilityLevels.isEmpty ? "None listed" : accessibilityLevels.join(", ")}';
        } else if (targetType == 'study_hall') {
          final building = (data['buildingAbbrev'] ?? '').toString();
          final room = (data['roomNumber'] ?? '').toString();
          final startTime = (data['startTime'] ?? '').toString();
          final endTime = (data['endTime'] ?? '').toString();
          final seats = (data['seatCapacity'] ?? 'Not provided').toString();

          title =
              building.isNotEmpty
                  ? '$building Room $room'
                  : 'Study Hall Listing';

          subtitle = 'Time: $startTime - $endTime';
          extra = 'Seats: $seats';
        } else if (targetType == 'bathroom_review') {
          title = (data['bathroomName'] ?? 'Bathroom Review').toString();

          // bathroom reviews save the text under "comments"
          final bathroomComment =
              (data['comments'] ??
                      data['comment'] ??
                      data['details'] ??
                      data['review'] ??
                      '')
                  .toString()
                  .trim();

          subtitle =
              bathroomComment.isNotEmpty
                  ? 'Comment: $bathroomComment'
                  : 'Comment: No comment provided.';

          final rating = data['rating'];
          final features = data['features'];

          if (rating != null) {
            extra = 'Rating: $rating star(s)';
          }

          if (features is Map) {
            final selectedFeatures =
                features.entries
                    .where((entry) => entry.value == true)
                    .map((entry) => entry.key.toString())
                    .toList();

            if (selectedFeatures.isNotEmpty) {
              extra =
                  extra.isEmpty
                      ? 'Features: ${selectedFeatures.join(", ")}'
                      : '$extra\nFeatures: ${selectedFeatures.join(", ")}';
            }
          } // if report is dorm event or food alert
        } else if (targetType == 'event' || targetType == 'dorm_event') {
          title = (data['title'] ?? 'Dorm Event').toString();
          subtitle = (data['body'] ?? data['description'] ?? '').toString();
          extra = (data['location'] ?? '').toString();
        } else if (targetType == 'food_alert') {
          title = (data['title'] ?? 'Food Alert').toString();
          subtitle = (data['description'] ?? '').toString();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reported Content Preview',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
              if (extra.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(extra, style: const TextStyle(color: Colors.black54)),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('reports')
              .where('status', isEqualTo: 'open')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No open reports.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final r = docs[i];
            final data = r.data();

            final targetId =
                (data['targetId'] ?? data['postId'] ?? '').toString();
            final reason = (data['reason'] ?? '').toString();
            final details = (data['details'] ?? '').toString();
            final targetType = (data['targetType'] ?? '').toString();
            final imageUrl = (data['imageUrl'] ?? '').toString();

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report (${_displayTargetType(targetType)})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 6),

                    Text('Reason: ${reason.isEmpty ? "(none)" : reason}'),

                    const SizedBox(height: 4),

                    Text('Details: ${details.isEmpty ? "(none)" : details}'),

                    if (imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _showFullImage(context, imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text(
                                'Could not load image.',
                                style: TextStyle(color: Colors.redAccent),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap image to view full screenshot',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: 6),

                    Text(
                      'targetId: ${targetId.isEmpty ? "(missing)" : targetId}',
                      style: const TextStyle(color: Colors.black54),
                    ),

                    // NEW FROM GISELLE REVIEW 4: shows preview of whatever content was reported
                    _buildReportedContentPreview(
                      targetId: targetId,
                      targetType: targetType,
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed:
                                targetId.isNotEmpty
                                    ? () async {
                                      try {
                                        await _deleteReportedContentAndClose(
                                          reportId: r.id,
                                          targetId: targetId,
                                          targetType: targetType,
                                        );

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                _deleteSuccessText(targetType),
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Delete failed: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                    : null,
                            child: Text(_deleteButtonText(targetType)),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              try {
                                await _closeReport(
                                  reportId: r.id,
                                  moderatorNote: 'Rejected / no action',
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Report rejected'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Reject failed: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
