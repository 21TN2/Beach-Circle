// This is for Mods Only
// only Rey, Josue, Tiff, Theresa, and I can access + view
// Appears in Dashboard to see requests
// Made by Giselle ---> for student work review 2

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beach_circle_flutter/community_goods/smf/service/forum_service.dart';
import 'package:beach_circle_flutter/community_goods/dorm_life/services/event_service.dart';

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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moderation'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Forum Requests'),
              Tab(text: 'Reports'),
              Tab(text: 'Feedback'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ForumRequestsTab(forumService: forumService),
            _ReportsTab(forumService: forumService),
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
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!;
        if (docs.isEmpty) {
          // if screen is empty --> shows the message that theres no request yet
          return const Center(child: Text('No pending forum requests.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12), // building the list for forum
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i];
            final data = d.data();
            final title = (data['title'] ?? '').toString();
            final desc = (data['description'] ?? '').toString();
            final createdBy = (data['createdBy'] ?? '').toString();
            final imageUrl = (data['imageUrl'] ?? '').toString();

            return Card(
              // building how the card view will look
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
                      title.isEmpty ? '(No title)' : title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
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
                          ? 'Requested by: (unknown)'
                          : 'Requested by: $createdBy',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              try {
                                await forumService.approveForumCategoryRequest(
                                  requestId: d.id,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Approved -> Added to Forums',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Approve failed: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              try {
                                await forumService.rejectForumCategoryRequest(
                                  requestId: d.id,
                                  reason: 'Rejected by moderator',
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Rejected')),
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

// ------------------- Reports Tab -------------------
class _ReportsTab extends StatelessWidget {
  _ReportsTab({required this.forumService});
  final ForumService forumService;
  final EventService _eventService = EventService();

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

  @override
  Widget build(BuildContext context) {
    // opens up the report page to access
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: forumService.streamOpenReports(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!;
        if (docs.isEmpty) {
          return const Center(child: Text('No open reports.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final r = docs[i];
            final data = r.data();

            final targetId = (data['targetId'] ?? '').toString();
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
                      'Report (${targetType.isEmpty ? "unknown" : targetType})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text('Reason: ${reason.isEmpty ? "(none)" : reason}'),
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

                    if (targetType == 'post' && targetId.isNotEmpty) ...[
                      const Divider(height: 18),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: forumService.streamPostById(targetId),
                        builder: (context, ps) {
                          if (!ps.hasData) return const SizedBox.shrink();
                          final postDoc = ps.data!;
                          if (!postDoc.exists) {
                            return const Text(
                              'Post no longer exists.',
                              style: TextStyle(color: Colors.redAccent),
                            );
                          }
                          final p = postDoc.data()!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (p['title'] ?? '(No title)').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (p['body'] ?? '(No body)').toString(),
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          );
                        },
                      ),
                    ],

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
                                        if (targetType == 'post') {
                                          await forumService
                                              .deleteReportedPostAndClose(
                                                reportId: r.id,
                                                postId: targetId,
                                              );
                                        } else if (targetType == 'event') {
                                          await _eventService
                                              .deleteReportedEventAndClose(
                                                reportId: r.id,
                                                eventId: targetId,
                                              );
                                        }

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                targetType == 'event'
                                                    ? 'Dorm Event deleted --> report closed'
                                                    : 'Post deleted --> report closed',
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
                            child: Text(
                              targetType == 'event'
                                  ? 'Delete Dorm Event'
                                  : 'Delete Post',
                            ),
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
                                await forumService.closeReport(reportId: r.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Report closed'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Close failed: $e')),
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

                      final title = (data['title'] ?? '').toString();
                      final category = (data['category'] ?? '').toString();
                      final feature = (data['feature'] ?? '').toString();
                      final userEmail = (data['userEmail'] ?? '').toString();
                      final status = (data['status'] ?? 'Submitted').toString();

                      //If user inputs an invalid response
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(title.isEmpty ? '(No title)' : title),
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
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

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
  final String feedbackId;
  final Map<String, dynamic> feedbackData;

  const _FeedbackDetailsTab({
    required this.feedbackId,
    required this.feedbackData,
  });

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
    final title = (widget.feedbackData['title'] ?? 'Untitled').toString();
    final userEmail = (widget.feedbackData['userEmail'] ?? '--').toString();
    final category = (widget.feedbackData['category'] ?? '--').toString();
    final feature = (widget.feedbackData['feature'] ?? '--').toString();
    final description = (widget.feedbackData['description'] ?? '--').toString();
    final helpfulRating =
        widget.feedbackData['helpfulRating']?.toString() ?? '--';
    final canModeratorDelete = _selectedStatus == 'Completed';

    String ratingText = '--';
    if (helpfulRating == '0') ratingText = 'Helpful 😄';
    if (helpfulRating == '1') ratingText = 'Neutral 🙂';
    if (helpfulRating == '2') ratingText = 'Not Helpful ☹️';

    return Scaffold(
      //Feedback being reviewed
      appBar: AppBar(title: const Text('Review Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _detailRow('Title', title),
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
