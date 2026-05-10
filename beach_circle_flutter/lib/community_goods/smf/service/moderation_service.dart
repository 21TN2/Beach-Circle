// Moderation Service
// created by Giselle -- for student review 2

// imports related to firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:profanity_filter/profanity_filter.dart';

class ModerationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Added moderation for inappropriate content
  static final ProfanityFilter _filter = ProfanityFilter();

  static bool containsBlockedContent(String text) {
    return _filter.hasProfanity(text);
  }

  Future<void> reportContent({
    required String targetId,
    required String reportedUserId,
    required String targetType,
    required String reason,
    required String details,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User must be signed in to report content.');
    }

    final uid = user.uid;

    await _db.collection('reports').add({
      'targetType': targetType,
      'targetId': targetId,
      'reportedUserId': reportedUserId,
      'reporterUserId': uid,
      'reason': reason,
      'details': details,
      'imageUrl': imageUrl,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // fields needed for firebase
  Future<void> reportPost({
    required String postId,
    required String postAuthorId,
    required String reason,
    required String details,
    String? imageUrl,
  }) async {
    await reportContent(
      targetId: postId,
      reportedUserId: postAuthorId,
      targetType: 'post',
      reason: reason,
      details: details,
      imageUrl: imageUrl,
    );
  }
}