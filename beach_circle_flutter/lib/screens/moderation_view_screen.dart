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
    // Just Needs Josue
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
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!;
        if (docs
            .isEmpty) // if screen is empty --> shows the message that theres no request yet
          return const Center(child: Text('No pending forum requests.'));

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
                      title.isEmpty
                          ? '(No title)'
                          : title, // shows title otherwise no title
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc.isEmpty ? '(No description)' : desc,
                    ), // shows descr otherwise no descr
                    const SizedBox(height: 8),
                    Text(
                      createdBy.isEmpty
                          ? 'Requested by: (unknown)' // shows who it was requested by --> uses user ID
                          : 'Requested by: $createdBy',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),

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
                                await forumService.approveForumCategoryRequest(
                                  // approves the post when pressed
                                  requestId: d.id,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Approved -> Added to Forums', // mods receive a message when appproved
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Approve failed: $e',
                                      ), // error: approval failed shown to mods
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Approve'), // approve text
                          ),
                        ),
                        const SizedBox(width: 10), // reject button
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.red, // red to show that it means no
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              try {
                                await forumService.rejectForumCategoryRequest(
                                  // when pressed, it rejects request
                                  requestId: d.id,
                                  reason:
                                      'Rejected by moderator', // shows the reason
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Rejected'),
                                    ), // shows reject message to mods
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Reject failed: $e',
                                      ), // error: rejection failed
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Reject'), // button text
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

  @override
  Widget build(BuildContext context) {
    // opens up the report page to access
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: forumService.streamOpenReports(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!;
        if (docs.isEmpty)
          return const Center(
            child: Text('No open reports.'),
          ); // if report page is empty w/ no report

        return ListView.builder(
          // defining it
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final r = docs[i];
            final data = r.data();

            final postId =
                (data['postId'] ?? '')
                    .toString(); // report shows these details: post id from the reported post
            final reason =
                (data['reason'] ?? '')
                    .toString(); // reason why its being reported
            final details =
                (data['details'] ?? '').toString(); // detail description
            final targetType =
                (data['targetType'] ?? '').toString(); // the post in question

            return Card(
              // building the card to display details
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
                      'Report (${targetType.isEmpty ? "unknown" : targetType})', // shows whats being reported
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text('Reason: ${reason.isEmpty ? "(none)" : reason}'),

                    /// the basic reason
                    Text(
                      'Details: ${details.isEmpty ? "(none)" : details}',
                    ), // details from the user about it
                    const SizedBox(height: 6),
                    Text(
                      'postId: ${postId.isEmpty ? "(missing)" : postId}', // the id of the post
                      style: const TextStyle(color: Colors.black54),
                    ),

                    if (postId.isNotEmpty) ...[
                      // what happens after its deleted
                      const Divider(height: 18),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: forumService.streamPostById(postId),
                        builder: (context, ps) {
                          if (!ps.hasData) return const SizedBox.shrink();
                          final postDoc = ps.data!;
                          if (!postDoc.exists) {
                            return const Text(
                              'Post no longer exists.', // to show mods posts is not there anymore
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
                      // whats shown to the mods after they make an action
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
                                              // when mods delete + close a report
                                              reportId: r.id,
                                              postId: postId,
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Post deleted --> report closed', // displays confirm message
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
                                                'Delete failed: $e', // error: deletion couldnt happen
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                    : null,
                            child: const Text('Delete Post'), // button text
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.black26),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              try {
                                await forumService.rejectReport(
                                  reportId: r.id,
                                  moderatorNote:
                                      'Invalid / no action', // when mods fail to reject
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Report rejected',
                                      ), // when mods reject a post
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Reject failed: $e',
                                      ), // error: rejection failed
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Reject Report'), // button text
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
