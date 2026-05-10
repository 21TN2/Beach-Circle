import 'package:flutter/material.dart';
import '../model/forum_reply.dart';
import '../service/forum_service.dart';
import 'interested_button.dart';
import 'report_button.dart';
import '../screens/report_issue_pg.dart';
import '../service/moderation_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPostTile extends StatefulWidget {
  final String postId;
  final String title;
  final String description;

  final bool isInterested;
  final VoidCallback onInterestedTap;
  final VoidCallback onReportTap;

  final ForumService forumService;

  final String currentUserId;
  final String currentUserName;

  //  original post author info
  final String postAuthorName;
  final String postAuthorId;
  final DateTime? postCreatedAt;

  final String? mediaUrl;
  final String? mediaType;

  const ForumPostTile({
    super.key,
    required this.postId,
    required this.title,
    required this.description,
    required this.isInterested,
    required this.onInterestedTap,
    required this.onReportTap,
    required this.forumService,
    required this.currentUserId,
    required this.currentUserName,
    required this.postAuthorName,
    required this.postAuthorId,
    this.postCreatedAt,
    required this.mediaUrl,
    required this.mediaType,
  });

  @override
  State<ForumPostTile> createState() => _ForumPostTileState();
}

class _ForumPostTileState extends State<ForumPostTile> {
  bool isExpanded = false;
  final TextEditingController replyCtrl = TextEditingController();

  @override
  void dispose() {
    replyCtrl.dispose();
    super.dispose();
  }

  /// Converts DateTime to "2h ago"
  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";

    return "${date.month}/${date.day}/${date.year}";
  }

  /// Gets first letter
  String initial(String name) {
    if (name.trim().isEmpty) return "A";
    return name.trim()[0].toUpperCase();
  }

  // Profile pic shown
  Widget _profilePicture({
    required String userId,
    required String fallbackName,
    double radius = 16,
  }) {
    if (userId.trim().isEmpty || userId == "anon" || userId == "TODO-user-id") {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: Text(
          initial(fallbackName),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final photoUrl = (data?['photo_url'] ?? '').toString().trim();

        if (photoUrl.isEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            child: Text(
              initial(fallbackName),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        }

        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(photoUrl),
          onBackgroundImageError: (_, __) {},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            children: [
              /// Expand button
              IconButton(
                icon: Icon(isExpanded ? Icons.remove : Icons.add),
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
              ),

              /// TITLE
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE0A800),
                    fontSize: 16,
                  ),
                ),
              ),

              InterestedButton(
                isInterested: widget.isInterested,
                onPressed: widget.onInterestedTap,
              ),

              ReportButton(onPressed: widget.onReportTap),
            ],
          ),

          /// POST AUTHOR HEADER
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 6),
              child: Row(
                children: [
                  _profilePicture(
                    userId: widget.postAuthorId,
                    fallbackName: widget.postAuthorName,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      widget.postAuthorName.isEmpty
                          ? "Anonymous"
                          : widget.postAuthorName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),

                  if (widget.postCreatedAt != null)
                    Text(
                      timeAgo(widget.postCreatedAt!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),

          /// DESCRIPTION
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 6, bottom: 8),
              child: Text(widget.description),
            ),

          /// MEDIA IMAGE
          if (isExpanded &&
              widget.mediaType == 'image' &&
              widget.mediaUrl != null)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8, bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.mediaUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder:
                      (_, __, ___) => Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.black12,
                        child: const Center(
                          child: Text("Failed to load image"),
                        ),
                      ),
                ),
              ),
            ),

          /// REPLIES STREAM
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: StreamBuilder<List<ForumReply>>(
                stream: widget.forumService.streamReplies(widget.postId),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final replies = snapshot.data!;

                  if (replies.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text("No replies yet."),
                    );
                  }

                  return Column(
                    children:
                        replies.map((reply) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(8),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),

                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// REPLY PROFILE ICON
                                _profilePicture(
                                  userId: reply.authorId,
                                  fallbackName: reply.author,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              reply.author.isEmpty
                                                  ? "Anonymous"
                                                  : reply.author,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),

                                          Text(
                                            timeAgo(reply.createdAt),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 2),

                                      Text(reply.body),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ),

          /// REPLY INPUT
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyCtrl,
                      decoration: const InputDecoration(
                        hintText: "Reply...",
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.send),

                    onPressed: () async {
                      final text = replyCtrl.text.trim();

                      if (text.isEmpty) return;

                      //auto moderation
                      if (ModerationHelper.containsProfanity(text)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please keep the community friendly. Remove inappropriate language before replying.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return; // Stops the reply from going through!
                      }

                      await widget.forumService.addReply(
                        postId: widget.postId,
                        body: text,
                        authorId: widget.currentUserId,
                        authorName: widget.currentUserName,
                      );

                      replyCtrl.clear();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
