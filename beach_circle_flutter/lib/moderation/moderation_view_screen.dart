// This is for Mods Only
// only Rey, Josue, Tiff, Theresa, and I can access + view
// Appears in Dashboard to see requests
// Appears in Dashboard to see requests + reports
// Made by Giselle ---> for student work review 2
// Updated to show forum requests, community goods reports, and map feature reports
// Merged to show forum requests, community goods reports, map feature reports, and feedback

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

  @override // for those users who somehow got ahold of mods button
  Widget build(BuildContext context) {
    if (!isModerator) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moderation')),
        body: const Center(child: Text('You do not have access to this page.')),
      );
    }

    return DefaultTabController(
      // creates the header title --> tabs: forum request & reports
      // shows forum requests, community goods reports, and map feature reports
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moderation'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Forum Requests'),
              Tab(text: 'Community Goods Report'),
              Tab(text: 'Map Features Report'),
              Tab(text: 'Feedback'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ForumRequestsTab(forumService: forumService),

            // Student Misc Forum, Dorm Life, and general event reports
            const _ReportsTab(
              allowedTargetTypes: {
                'post',
                'forum_post',
                'event',
                'general_event',
                'eb_event',
                'dorm_event',
              },
              emptyMessage: 'No open community goods reports.',
            ),

            // Map feature reports only
            const _ReportsTab(
              allowedTargetTypes: {'outlet', 'study_hall', 'bathroom_review'},
              emptyMessage: 'No open map feature reports.',
            ),

            const _FeedbackTab(),
          ],
        ),
      ),
    );
  }
}

// ------------------- Forum Requests Tab -------------------
class _ForumRequestsTab extends StatelessWidget {
  const _ForumRequestsTab({required this.forumService});

  final ForumService forumService;

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

  @override // each forum starts off as pending
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: forumService.streamForumCategoryRequests(status: 'pending'),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!;

        // if screen is empty --> shows the message that theres no request yet
        if (docs.isEmpty) {
          return const Center(child: Text('No pending forum requests.'));
        }

        // building the list for forum
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i];
            final data = d.data();

            final title = (data['title'] ?? '').toString();
            final desc = (data['description'] ?? '').toString();
            final createdBy = (data['createdBy'] ?? '').toString();
            final imageUrl = (data['imageUrl'] ?? '').toString();

            // building how the card view will look
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
                    const Text(
                      'Forum Category Request',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // shows title otherwise no title
                      title.isEmpty ? '(No title)' : title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // shows descr otherwise no descr
                    Text(desc.isEmpty ? '(No description)' : desc),
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
                    const SizedBox(height: 8),
                    Text(
                      createdBy.isEmpty
                          // shows who it was requested by --> uses user ID
                          ? 'Requested by: (unknown)'
                          : 'Requested by: $createdBy',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // button icon for approved
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              try {
                                // approves the post when pressed
                                await forumService.approveForumCategoryRequest(
                                  requestId: d.id,
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        // mods receive a message when appproved
                                        'Approved -> Added to Forums',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      // error: approval failed shown to mods
                                      content: Text('Approve failed: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            // approve text
                            child: const Text('Approve'),
                          ),
                        ),
                        // reject button
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // red to show that it means no
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              try {
                                // when pressed, it rejects request
                                await forumService.rejectForumCategoryRequest(
                                  requestId: d.id,
                                  // shows the reason
                                  reason: 'Rejected by moderator',
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    // shows reject message to mods
                                    const SnackBar(content: Text('Rejected')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      // error: rejection failed
                                      content: Text('Reject failed: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            // button text
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

// ------------------- Reports Tab -------------------
class _ReportsTab extends StatelessWidget {
  const _ReportsTab({
    required this.allowedTargetTypes,
    required this.emptyMessage,
  });

  final Set<String> allowedTargetTypes;
  final String emptyMessage;

  // TO FORMAT STRING TIME STAMP
  String _formatDateValue(dynamic value) {
    if (value == null) return '';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }

    if (value is DateTime) {
      return '${value.month}/${value.day}/${value.year}';
    }

    return value.toString();
  }

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
      case 'general_event':
      case 'eb_event':
        return 'Campus Event';
      case 'dorm_event':
        return 'Dorm Event';
      case 'outlet':
        return 'Outlet';
      case 'study_hall':
        return 'Study Hall';
      case 'bathroom_review':
        return 'Bathroom Review';
      default:
        return targetType.isEmpty ? 'Unknown' : targetType;
    }
  }

  // collection target types aka firebase collection
  String? _collectionForTargetType(String targetType) {
    switch (targetType) {
      case 'post':
      case 'forum_post':
        return 'forumPosts';
      case 'event':
      case 'general_event':
      case 'eb_event':
        return 'eb_events';
      case 'dorm_event':
        return 'dorm_events';
      case 'outlet':
        return 'outlets';
      case 'study_hall':
        return 'study_halls';
      case 'bathroom_review':
        return 'bathroom_reviews';
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
      case 'general_event':
      case 'eb_event':
        return 'Delete Campus Event';
      case 'dorm_event':
        return 'Delete Dorm Event';
      case 'outlet':
        return 'Delete Outlet';
      case 'study_hall':
        return 'Delete Study Hall';
      case 'bathroom_review':
        return 'Delete Bathroom Review';
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
      case 'general_event':
      case 'eb_event':
        return 'Campus Event deleted --> report closed';
      case 'dorm_event':
        return 'Dorm Event deleted --> report closed';
      case 'outlet':
        return 'Outlet deleted --> report closed';
      case 'study_hall':
        return 'Study Hall deleted --> report closed';
      case 'bathroom_review':
        return 'Bathroom review deleted --> report closed';
      default:
        return 'Report closed';
    }
  }

  Future<void> _closeReport({
    required String reportId,
    required String moderatorNote,
  }) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
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

    await _closeReport(
      reportId: reportId,
      moderatorNote: 'Closed by moderator',
    );
  }

  // preview reported content for moderators
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
              // to show mods posts is not there anymore
              'Reported content no longer exists.',
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final data = doc.data()!;

        String title = '(No title)';
        String subtitle = '';
        String extra = '';

        if (targetType == 'post' || targetType == 'forum_post') {
          title = (data['title'] ?? '(No title)').toString();
          subtitle = (data['body'] ?? '(No body)').toString();
        } else if (targetType == 'event' ||
            targetType == 'general_event' ||
            targetType == 'eb_event') {
          title = (data['title'] ?? 'Campus Event').toString();
          subtitle = (data['body'] ?? data['description'] ?? '').toString();

          final location = (data['location'] ?? '').toString();
          final date = _formatDateValue(data['date'] ?? data['dateLabel']);
          final time = (data['time'] ?? data['timeText'] ?? '').toString();

          extra = [
            if (location.isNotEmpty) 'Location: $location',
            if (date.isNotEmpty) 'Date: $date',
            if (time.isNotEmpty) 'Time: $time',
          ].join('\n');
        } else if (targetType == 'dorm_event') {
          title = (data['title'] ?? 'Dorm Event').toString();
          subtitle = (data['body'] ?? data['description'] ?? '').toString();

          final location = (data['location'] ?? '').toString();
          final date = _formatDateValue(data['date'] ?? data['dateLabel']);
          final time = (data['time'] ?? data['timeText'] ?? '').toString();

          extra = [
            if (location.isNotEmpty) 'Location: $location',
            if (date.isNotEmpty) 'Date: $date',
            if (time.isNotEmpty) 'Time: $time',
          ].join('\n');
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
          }
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
    // opens up the report page to access
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // shows open reports, then filters them into the correct tab
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

        final docs =
            snap.data!.docs.where((doc) {
              final data = doc.data();
              final targetType = (data['targetType'] ?? '').toString();
              return allowedTargetTypes.contains(targetType);
            }).toList();

        // if report page is empty w/ no report
        if (docs.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        // defining it
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final r = docs[i];
            final data = r.data();

            // report shows these details: post id from the reported post
            final targetId =
                (data['targetId'] ?? data['postId'] ?? '').toString();

            // reason why its being reported
            final reason = (data['reason'] ?? '').toString();

            // detail description
            final details = (data['details'] ?? '').toString();

            // the post in question
            final targetType = (data['targetType'] ?? '').toString();

            final imageUrl = (data['imageUrl'] ?? '').toString();

            // building the card to display details
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
                      // shows whats being reported
                      'Report (${_displayTargetType(targetType)})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),

                    /// the basic reason
                    Text('Reason: ${reason.isEmpty ? "(none)" : reason}'),
                    const SizedBox(height: 4),

                    // details from the user about it
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
                      // the id of the post
                      'targetId: ${targetId.isEmpty ? "(missing)" : targetId}',
                      style: const TextStyle(color: Colors.black54),
                    ),

                    // what happens after its deleted
                    _buildReportedContentPreview(
                      targetId: targetId,
                      targetType: targetType,
                    ),

                    const SizedBox(height: 12),

                    // whats shown to the mods after they make an action
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
                                        // when mods delete + close a report
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
                                              // displays confirm message
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
                                              // error: deletion couldnt happen
                                              content: Text(
                                                'Delete failed: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                    : null,
                            // button text
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
                                // when mods fail to reject
                                await _closeReport(
                                  reportId: r.id,
                                  moderatorNote: 'Rejected / no action',
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      // when mods reject a post
                                      content: Text('Report rejected'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      // error: rejection failed
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

// ------------------- Feedback Tab -------------------
class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab();

  //Months so analytics data can be organized by months
  static const List<String> _monthNames = [
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

  //If month is unknown
  String _monthLabel(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Month';
    final date = timestamp.toDate();
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  //Data being organized
  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _groupByMonth(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    grouped = {};

    for (final doc in docs) {
      final data = doc.data();
      final createdAt = data['createdAt'] as Timestamp?;
      final label = _monthLabel(createdAt);
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(doc);
    }

    return grouped;
  }

  Widget _buildStatusSection({
    required BuildContext context,
    required String title,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String emptyMessage,
  }) {
    if (docs.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(emptyMessage),
        ),
      );
    }

    final grouped = _groupByMonth(docs);

    //Tab Card created
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          '$title (${docs.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children:
            grouped.entries.map((entry) {
              final month = entry.key;
              final monthDocs = entry.value;

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        month,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    //Firebase Database foundations
                    ...monthDocs.map((d) {
                      final data = d.data();

                      final feedbackTitle = (data['title'] ?? '').toString();
                      final category = (data['category'] ?? '').toString();
                      final feature = (data['feature'] ?? '').toString();
                      final userEmail = (data['userEmail'] ?? '').toString();
                      final status =
                          (data['status'] ?? 'Submitted').toString();

                      //If user inputs an invalid response
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            feedbackTitle.isEmpty
                                ? '(No title)'
                                : feedbackTitle,
                          ),
                          subtitle: Text(
                            '${userEmail.isEmpty ? "(unknown user)" : userEmail}\n'
                            '${category.isEmpty ? "(no category)" : category} • '
                            '${feature.isEmpty ? "(no feature)" : feature}\n'
                            'Status: $status',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => _FeedbackDetailsTab(
                                      feedbackId: d.id,
                                      feedbackData: data,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  //Feedback tab build
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('feedback')
              .where('moderatorDeleted', isEqualTo: false)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        //If no feedback has been submitted
        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No feedback submissions yet.'));
        }

        //Shows what submissions have been submitted
        final submitted =
            docs
                .where(
                  (d) =>
                      (d.data()['status'] ?? 'Submitted').toString() ==
                      'Submitted',
                )
                .toList();

        //Shows what feedback form is being under reviewed
        final underReview =
            docs
                .where(
                  (d) =>
                      (d.data()['status'] ?? '').toString() == 'Under Review',
                )
                .toList();

        //Shows what forms are completely reviewed
        final completed =
            docs
                .where(
                  (d) => (d.data()['status'] ?? '').toString() == 'Completed',
                )
                .toList();

        //If there are no feedback forms in any sections
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildStatusSection(
              context: context,
              title: 'Submitted / Not Looked At',
              docs: submitted,
              emptyMessage: 'No submitted feedback waiting to be reviewed.',
            ),
            _buildStatusSection(
              context: context,
              title: 'Under Review',
              docs: underReview,
              emptyMessage: 'No feedback is currently under review.',
            ),
            _buildStatusSection(
              context: context,
              title: 'Completed',
              docs: completed,
              emptyMessage: 'No completed feedback yet.',
            ),
          ],
        );
      },
    );
  }
}

//Feedback Tab Details
class _FeedbackDetailsTab extends StatefulWidget {
  const _FeedbackDetailsTab({
    required this.feedbackId,
    required this.feedbackData,
  });

  final String feedbackId;
  final Map<String, dynamic> feedbackData;

  @override
  State<_FeedbackDetailsTab> createState() => _FeedbackDetailsTabState();
}

class _FeedbackDetailsTabState extends State<_FeedbackDetailsTab> {
  late TextEditingController _responseController;
  late String _selectedStatus;
  bool _isSaving = false;

  //Allows responses from moderators
  @override
  void initState() {
    super.initState();

    _responseController = TextEditingController(
      text: (widget.feedbackData['moderatorResponse'] ?? '').toString(),
    );

    _selectedStatus = (widget.feedbackData['status'] ?? 'Submitted').toString();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  //Allows feedback information to be saved
  Future<void> _saveFeedbackUpdate() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final moderator = FirebaseAuth.instance.currentUser;

      //Firebase foundations
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(widget.feedbackId)
          .update({
            'status': _selectedStatus,
            'moderatorResponse': _responseController.text.trim(),
            'reviewedBy': moderator?.email ?? '',
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      //When Feedback has been updated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback updated successfully.')),
      );

      Navigator.pop(context);
    } catch (e) {
      //If error occurs while updating
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  //If feedback is deleted from the moderator view
  Future<void> _deleteFeedback() async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(widget.feedbackId)
          .update({
            'moderatorDeleted': true,
            'deletedByModeratorAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback hidden from moderator view.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      //If form deletion fails
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  //Feedback Tab Build
  @override
  Widget build(BuildContext context) {
    //All sections imported from Firebase
    final feedbackTitle =
        (widget.feedbackData['title'] ?? 'Untitled').toString();
    final userEmail = (widget.feedbackData['userEmail'] ?? '--').toString();
    final category = (widget.feedbackData['category'] ?? '--').toString();
    final feature = (widget.feedbackData['feature'] ?? '--').toString();
    final description =
        (widget.feedbackData['description'] ?? '--').toString();
    final helpfulRating =
        widget.feedbackData['helpfulRating']?.toString() ?? '--';

    final canModeratorDelete = _selectedStatus == 'Completed';

    String ratingText = '--';

    if (helpfulRating == '0') {
      ratingText = 'Helpful 😄';
    }

    if (helpfulRating == '1') {
      ratingText = 'Neutral 🙂';
    }

    if (helpfulRating == '2') {
      ratingText = 'Not Helpful ☹️';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _detailRow('Title', feedbackTitle),
            _detailRow('User Email', userEmail),
            _detailRow('Category', category),
            _detailRow('Feature', feature),
            _detailRow('Description', description),
            _detailRow('Helpful Rating', ratingText),
            const SizedBox(height: 20),
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStatus,

              //Status
              items: const [
                DropdownMenuItem(value: 'Submitted', child: Text('Submitted')),
                DropdownMenuItem(
                  value: 'Under Review',
                  child: Text('Under Review'),
                ),
                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedStatus = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            //If moderators want to create a response
            const Text(
              'Moderator Response',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _responseController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Write response',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            //Saves feedback and response from moderators
            ElevatedButton(
              onPressed: _isSaving ? null : _saveFeedbackUpdate,
              child:
                  _isSaving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save'),
            ),
            const SizedBox(height: 12),

            //If feedback form is deleted from the moderator view
            if (canModeratorDelete)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete Feedback'),
                        content: const Text(
                          'Are you sure you want to hide this completed feedback from moderator view?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await _deleteFeedback();
                  }
                },
                child: const Text('Delete Feedback'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}