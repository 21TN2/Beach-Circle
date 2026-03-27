// This is for Mods Only
// only Rey, Josue, Tiff, Theresa, and I can access + view
// Appears in Dashboard to see requests
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Moderation'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Forum Requests'), Tab(text: 'Reports')],
          ),
        ),
        body: TabBarView(
          children: [
            _ForumRequestsTab(forumService: forumService),
            _ReportsTab(forumService: forumService),
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
  const _ReportsTab({required this.forumService});
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

            final postId = (data['postId'] ?? '').toString();
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
                      'postId: ${postId.isEmpty ? "(missing)" : postId}',
                      style: const TextStyle(color: Colors.black54),
                    ),

                    if (postId.isNotEmpty) ...[
                      const Divider(height: 18),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: forumService.streamPostById(postId),
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
                                (targetType == 'post' && postId.isNotEmpty)
                                    ? () async {
                                      try {
                                        await forumService
                                            .deleteReportedPostAndClose(
                                              reportId: r.id,
                                              postId: postId,
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Post deleted --> report closed',
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
                            child: const Text('Delete Post'),
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
