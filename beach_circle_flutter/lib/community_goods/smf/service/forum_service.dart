import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/forum_category.dart';
import '../model/forum_post.dart';
import '../model/forum_reply.dart';

class ForumService {
  final FirebaseFirestore _db;

  // ✅ Public constructor so ForumService() is valid
  ForumService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // -------- Categories --------
  Stream<List<ForumCategory>> streamCategories() {
    return _db
        .collection('forumCategories')
        .orderBy('title')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ForumCategory.fromMap(d.id, d.data()))
            .toList());
  }

  // -------- Posts --------
  Stream<List<ForumPost>> streamPosts(String categoryId) {
    return _db
        .collection('forumPosts')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ForumPost.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String> createPost({
    required String categoryId,
    required String title,
    required String body,
    required String author,
  }) async {
    final doc = await _db.collection('forumPosts').add({
      'categoryId': categoryId,
      'title': title,
      'body': body,
      'author': author,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // -------- Replies --------
  Stream<List<ForumReply>> streamReplies(String postId) {
    return _db
        .collection('forumPosts')
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ForumReply.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> addReply({
    required String postId,
    required String body,
    required String author,
  }) async {
    await _db.collection('forumPosts').doc(postId).collection('replies').add({
      'postId': postId,
      'body': body,
      'author': author,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}