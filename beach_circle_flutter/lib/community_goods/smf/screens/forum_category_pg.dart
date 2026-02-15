import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/forum_category.dart';
import '../model/forum_post.dart';
import '../service/forum_service.dart';
import '../widgets/forum_post_tile.dart';

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

      //  Yellow header with white pill
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
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Student Miscellaneous Forum",
                        style: TextStyle(
                          color: Colors.black54,
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

      // (Dashboard controls the pencil)
      // floatingActionButton: ...
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
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
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
                  //  extra bottom padding so Dashboard FAB doesn't cover replies/input
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
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
                      onReportTap: () {},
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
