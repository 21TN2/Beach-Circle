import 'package:flutter/material.dart';
import '../model/forum_category.dart';
import '../model/forum_post.dart';
import '../service/forum_service.dart';
import 'forum_thread_pg.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(category.title), centerTitle: true),
      body: StreamBuilder<List<ForumPost>>(
        stream: forumService.streamPosts(category.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return const Center(child: Text('No posts yet. Be the first!'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = posts[i];
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(p.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForumThreadPg(
                          category: category,
                          post: p,
                          forumService: forumService,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}