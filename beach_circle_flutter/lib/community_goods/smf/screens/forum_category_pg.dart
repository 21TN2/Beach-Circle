// forum_category_pg.dart
import 'package:beach_circle_flutter/community_goods/smf/screens/report_issue_pg.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/forum_category.dart';
import '../model/forum_post.dart';
import '../service/forum_service.dart';
import '../widgets/forum_post_tile.dart';
import 'create_forum_post_pg.dart';
import '../screens/report_issue_pg.dart';

class ForumCategoryPg extends StatelessWidget {
  final ForumCategory category;
  final ForumService forumService;

  ForumCategoryPg({
    super.key,
    required this.category,
    ForumService? forumService,
  }) : forumService = forumService ?? ForumService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? "anon";
    final currentUserName =
        user?.displayName ?? user?.email?.split('@').first ?? "Anonymous";

    return Scaffold(
      backgroundColor: Colors.white,

      //  main header
      // main header
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2D21B),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
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

                // header
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // centered text
                    const Center(
                      child: Text(
                        "Student Miscellaneous Forum",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // chevron stays on right
                    const Positioned(
                      right: 0,
                      child: Icon(Icons.chevron_right, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // pencil goes to add post
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF2C200),
        child: const Icon(Icons.edit, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => CreateForumPostPg(
                    category: category,
                    forumService: forumService,
                  ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Text(
              category.title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<ForumPost>>(
              stream: forumService.streamPosts(category.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!;
                if (posts.isEmpty) {
                  return const Center(
                    child: Text('No posts yet. Be the first!'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = posts[i];
                    return ForumPostTile(
                      postId: p.id,
                      title: p.title,
                      description: p.body,
                      forumService: forumService,
                      currentUserId: currentUserId,
                      currentUserName: currentUserName,
                      postAuthorName: p.authorName ?? "Anonymous",
                      postCreatedAt: p.createdAt,
                      mediaUrl: p.mediaUrl,
                      mediaType: p.mediaType,
                      isInterested: false,
                      onInterestedTap: () {},
                      onReportTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ReportIssuePage(
                                  postId: p.id,
                                  postAuthorId: p.authorId,
                                ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
