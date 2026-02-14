// REPLY TO FORUM POST

class ForumReply {
  final String id;
  final String postId;
  final String body;
  final String author;
  final DateTime createdAt;

  const ForumReply({
    required this.id,
    required this.postId,
    required this.body,
    required this.author,
    required this.createdAt,
  });


// CREATES FORUMREPLY FROM MAP
  factory ForumReply.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    DateTime created =
        ts is DateTime ? ts : DateTime.tryParse((ts ?? '').toString()) ?? DateTime.now();

    return ForumReply(
      id: id,
      postId: (data['postId'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      author: (data['author'] ?? 'Anonymous') as String,
      createdAt: created,
    );
  }


// CONVERST FORUMREPLY INTO MAP
  Map<String, dynamic> toMap() => {
        'postId': postId,
        'body': body,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
      };
}