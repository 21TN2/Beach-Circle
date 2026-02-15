import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPost {
  final String id;
  final String categoryId;
  final String title;
  final String body;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  final String? mediaUrl;
  final String? mediaType;

  const ForumPost({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.mediaUrl,
    required this.mediaType,
  });

  factory ForumPost.fromMap(String id, Map<String, dynamic> data) {
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

    return ForumPost(
      id: id,
      categoryId: (data['categoryId'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      authorId: (data['authorId'] ?? '') as String,
      // KEY LINE
      authorName: (data['authorName'] ?? 'Anonymous') as String,
      createdAt: created,
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String?,
    );
  }
}
