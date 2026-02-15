import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/forum_category.dart';
import '../model/forum_post.dart';
import '../model/forum_reply.dart';

class ForumService {
  ForumService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Categories
  Stream<List<ForumCategory>> streamCategories() {
    return _db
        .collection('forumCategories')
        .orderBy('title')
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => ForumCategory.fromMap(d.id, d.data()))
                  .toList(),
        );
  }

  // Posts in a category
  Stream<List<ForumPost>> streamPosts(String categoryId) {
    return _db
        .collection('forumPosts')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ForumPost.fromMap(d.id, d.data())).toList(),
        );
  }

  // creating a post
  Future<String> createPost({
    required String categoryId,
    required String title,
    required String body,
    required String authorId,
    required String authorName,
    String? mediaUrl,
    String? mediaType, // e.g. "image"
  }) async {
    final doc = await _db.collection('forumPosts').add({
      'categoryId': categoryId,
      'title': title,
      'body': body,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaType != null) 'mediaType': mediaType,
    });
    return doc.id;
  }

  // Replies in a post
  Stream<List<ForumReply>> streamReplies(String postId) {
    return _db
        .collection('forumPosts')
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ForumReply.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addReply({
    required String postId,
    required String body,
    required String authorId,
    required String authorName,
  }) async {
    await _db.collection('forumPosts').doc(postId).collection('replies').add({
      'postId': postId,
      'body': body,
      'authorId': authorId,

      // includes username in reply
      'author': authorName,

      // timestamp when reply was sent
      'createdAt': FieldValue.serverTimestamp(),
      'postId': postId,
    });
  }

  Future<void> attachMediaToPost({
    required String postId,
    required String mediaUrl,
    required String mediaType,
  }) async {
    await _db.collection('forumPosts').doc(postId).update({
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    });
  }
}
