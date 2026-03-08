// Moderation Service
// created by Giselle -- for student review 2

// imports related to firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModerationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      'postId': postId, // unique post id to identify post
      'reportedUserId': postAuthorId, // whos being reported
      'reporterUserId': uid, // who reported it
      'reason': reason, // reason
      'details': details, // details of the incident
      'status': 'open', // report is opened until close by mods
      'createdAt': FieldValue.serverTimestamp(), // gets timestamps
    });
  }
}
