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

  // fields needed for firebase
  Future<void> reportPost({
    required String postId,
    required String postAuthorId,
    required String reason,
    required String details,
  }) async {
    final uid = _auth.currentUser!.uid;

    await _db.collection('reports').add({
      'targetType':
          'post', // field collections needed to store + update reports
      'postId': postId,
      'reportedUserId': postAuthorId,
      'reporterUserId': uid,
      'reason': reason,
      'details': details,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
