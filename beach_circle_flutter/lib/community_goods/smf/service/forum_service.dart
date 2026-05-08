import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final safeAuthorName =
        authorName.trim().isNotEmpty ? authorName.trim() : "Anonymous";

    final doc = await _db.collection('forumPosts').add({
      'categoryId': categoryId,
      'title': title,
      'body': body,
      'authorId': authorId,
      'authorName': safeAuthorName,
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
    final safeAuthorName =
        authorName.trim().isNotEmpty ? authorName.trim() : "Anonymous";

    await _db.collection('forumPosts').doc(postId).collection('replies').add({
      'postId': postId,
      'body': body,
      'authorId': authorId,
      'author': safeAuthorName,
      'createdAt': FieldValue.serverTimestamp(),
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

  // ---------------------------------
  // For Student Work Review 2: Post Pinning - Giselle
  // ---------------------------------

  CollectionReference<Map<String, dynamic>> _userPinsRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('pinnedPosts');
  }

  // only returns pinned posts for THIS category
  Stream<Set<String>> pinnedPostIdsStreamForCategory(String categoryId) {
    return _userPinsRef()
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Future<void> pinPost({
    required String postId,
    required String categoryId,
  }) async {
    await _userPinsRef().doc(postId).set({
      'postId': postId,
      'categoryId': categoryId,
      'pinnedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unpinPost(String postId) async {
    await _userPinsRef().doc(postId).delete();
  }

  // ----------------------------
  // Forum Category Requests Queue
  // When Users request a forum and this is how mods view it
  // for student work review 2
  // ----------------------------

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamForumCategoryRequests({String status = 'pending'}) {
    // details being collected for the forum request
    return _db
        .collection('forum_requests')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  // when forums get approved --> moved to approved forum request (forumcategories)
  Future<void> approveForumCategoryRequest({required String requestId}) async {
    final reqRef = _db.collection('forum_requests').doc(requestId);
    final catRef = _db.collection('forumCategories').doc(); // new category id

    await _db.runTransaction((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists)
        throw Exception(
          'Request not found',
        ); // error handling: if request is no longer there

      final data = reqSnap.data() as Map<String, dynamic>;

      final title =
          (data['title'] ?? '')
              .toString()
              .trim(); // grab title of forum request
      final description =
          (data['description'] ?? '').toString().trim(); // grab description

      if (title.isEmpty)
        throw Exception('Request is missing title'); // requires title

      // Creates the approved category the app displays
      tx.set(catRef, {
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        // gathers who it was created by
        'createdFromRequestId': requestId,
        if (data['createdBy'] != null) 'createdBy': data['createdBy'],
        if (data['imageUrl'] != null &&
            data['imageUrl'].toString().trim().isNotEmpty)
          'imageUrl': data['imageUrl'],
      });

      // Mark request as approved + processed
      tx.update(reqRef, {
        'status': 'approved',
        'processed': true,
        'processedAt': FieldValue.serverTimestamp(),
        'createdCategoryId': catRef.id,
      });
    });
  }

  // when forum requests get rejected
  Future<void> rejectForumCategoryRequest({
    required String requestId,
    String? reason,
  }) async {
    await _db.collection('forum_requests').doc(requestId).update({
      'status': 'rejected', // gathers fields of request
      'processed': true,
      'processedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.trim().isNotEmpty)
        'reviewNote': reason.trim(),
    });
  }
  // ----------------------------
  // Reports Moderation (for posts inside forums)
  // for student work review 2 - Giselle
  // ----------------------------

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamOpenReports() {
    return _db // field details
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  //shows the actual post content in the moderation screen
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamPostById(String postId) {
    return _db.collection('forumPosts').doc(postId).snapshots();
  }

  // when we close a report, it updates the status & fields
  Future<void> closeReport({
    required String reportId,
    String? moderatorNote,
  }) async {
    await _db.collection('reports').doc(reportId).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      if (moderatorNote != null && moderatorNote.trim().isNotEmpty)
        'moderatorNote': moderatorNote.trim(),
    });
  }

  // reject a report : updates it status and fields
  Future<void> rejectReport({
    required String reportId,
    String? moderatorNote,
  }) async {
    await _db.collection('reports').doc(reportId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      if (moderatorNote != null && moderatorNote.trim().isNotEmpty)
        'moderatorNote': moderatorNote.trim(),
    });
  }

  // Deletes the reported then closes the report
  Future<void> deleteReportedPostAndClose({
    required String reportId,
    required String postId,
  }) async {
    final reportRef = _db.collection('reports').doc(reportId);
    final postRef = _db.collection('forumPosts').doc(postId);

    await _db.runTransaction((tx) async {
      tx.delete(postRef);
      tx.update(reportRef, {
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'actionTaken': 'deleted_post',
      });
    });
  }
}
