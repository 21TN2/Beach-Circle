// Work Review 3
// Made by Giselle
// interested+dorm_service.dart
// Interested Star + Interested Count

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InterestedDormService {
  InterestedDormService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> interestedRef() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('interestedDormEvents');
  }

  static Stream<Set<String>> interestedEventIdsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({});  // ← return empty set, no crash
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('interestedDormEvents')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  static Future<void> toggleInterested({
    required String eventId,
    required bool isInterested,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No signed-in user found.');
    }

    final userInterestedRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('interestedDormEvents')
        .doc(eventId);

    final eventRef = _firestore.collection('dorm_events').doc(eventId);

    await _firestore.runTransaction((transaction) async {
      final eventSnap = await transaction.get(eventRef);

      if (!eventSnap.exists) {
        throw Exception('Event document does not exist.');
      }

      final eventData = eventSnap.data();
      final rawCount = eventData?['interestedCount'];

      final currentCount =
          rawCount is num
              ? rawCount.toInt()
              : int.tryParse(rawCount?.toString() ?? '') ?? 0;

      if (isInterested) {
        transaction.delete(userInterestedRef);
        transaction.set(eventRef, {
          'interestedCount': currentCount > 0 ? currentCount - 1 : 0,
        }, SetOptions(merge: true));
      } else {
        transaction.set(userInterestedRef, {
          'eventId': eventId,
          'interestedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(eventRef, {
          'interestedCount': currentCount + 1,
        }, SetOptions(merge: true));
      }
    });
  }
}
