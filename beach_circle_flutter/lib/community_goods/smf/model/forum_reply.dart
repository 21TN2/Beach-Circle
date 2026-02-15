import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ForumReply.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];

    DateTime created;
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is DateTime) {
      created = ts;
    } else if (ts is String) {
      created = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    return ForumReply(
      id: id,
      postId: (data['postId'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      author: (data['author'] ?? 'Anonymous') as String,
      createdAt: created,
    );
  }

  // Convenience getter
  String get authorName => author;

  Map<String, dynamic> toMap() => {
    'postId': postId,
    'body': body,
    'author': author,
    // Prefer Timestamp in Firestore writes
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
