// Dorm Event Service for Reporting
// created by Giselle -- for work review 3

import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> deleteReportedEventAndClose({
    required String reportId,
    required String eventId,
  }) async {
    await _db.runTransaction((tx) async {
      final eventRef = _db.collection('dorm_events').doc(eventId);
      final reportRef = _db.collection('reports').doc(reportId);

      tx.delete(eventRef);

      tx.update(reportRef, {
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'actionTaken': 'deleted_event',
      });
    });
  }
}
