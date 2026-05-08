// Moderation Service
// created by Giselle -- for student review 2

// imports related to firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModerationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> reportContent({
    required String targetId,
    required String reportedUserId,
    required String targetType,
    required String reason,
    required String details,
    String? imageUrl,
  }) async {
    final uid = _auth.currentUser!.uid;

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
