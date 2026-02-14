// FULL FORUM THREAD

import 'package:flutter/material.dart';
import '../model/forum_category.dart';
import '../model/forum_post.dart';
import '../model/forum_reply.dart';
import '../service/forum_service.dart';

class ForumThreadPg extends StatefulWidget {
  final ForumCategory category;
  final ForumPost post;
  final ForumService forumService;

  ForumThreadPg({
    super.key,
    required this.category,
    required this.post,
    ForumService? forumService,
  }) : forumService = forumService ?? ForumService();

  @override
  State<ForumThreadPg> createState() => _ForumThreadPgState();
}

class _ForumThreadPgState extends State<ForumThreadPg> {
  final _controller = TextEditingController();
  bool _sending = false;

  // PLACEHOLDERS, TROUBLESHOOT ONLY
  final String _authorId = 'TODO-user-id';
  final String _authorName = 'Anonymous';

  Future<void> _sendReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await widget.forumService.addReply(
        postId: widget.post.id,
        body: text,
        authorId: _authorId,
        authorName: _authorName,
      );
      // CLEAR AFTER SENDING
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.title), centerTitle: true),
      body: Column(
        children: [
          // ORIGINAL POST
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE7E7E7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(widget.post.body),
                const SizedBox(height: 10),
                Text(
                  'Posted by ${widget.post.author}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),

          // REPLIES
          Expanded(
            child: StreamBuilder<List<ForumReply>>(
              stream: widget.forumService.streamReplies(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Could not load replies.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final replies = snapshot.data!;
                if (replies.isEmpty) {
                  return const Center(child: Text('No replies yet. Say something!'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: replies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = replies[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.author, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(r.body),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // REPLY INPUT
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Reply',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendReply(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    onPressed: _sending ? null : _sendReply,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}