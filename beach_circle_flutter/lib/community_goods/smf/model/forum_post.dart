import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPost {
  final String id;
  final String categoryId;
  final String title;
  final String body;
  final String author;
  final DateTime createdAt;

  const ForumPost({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.body,
    required this.author,
    required this.createdAt,
  });

  /// Firestore -> ForumPost
  factory ForumPost.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];

    DateTime createdAt;
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else if (ts is DateTime) {
      createdAt = ts;
    } else if (ts is String) {
      createdAt = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return ForumPost(
      id: id,
      categoryId: (data['categoryId'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      author: (data['author'] ?? 'Anonymous') as String,
      createdAt: createdAt,
    );
  }

  /// ForumPost -> Firestore
  ///
  /// IMPORTANT:
  /// - Do NOT store DateTime as a string.
  /// - Use serverTimestamp() so ordering works correctly.
  Map<String, dynamic> toMap() => {
        'categoryId': categoryId,
        'title': title,
        'body': body,
        'author': author,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Optional helper if you ever want to duplicate a post with modifications.
  ForumPost copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? body,
    String? author,
    DateTime? createdAt,
  }) {
    return ForumPost(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      body: body ?? this.body,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}