// eb_event_service.dart
// Event Board Event Service for Reporting

import 'package:cloud_firestore/cloud_firestore.dart';

class EBEventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> deleteReportedEventAndClose({
    required String reportId,
    required String eventId,
  }) async {
    await _db.runTransaction((tx) async {
      final eventRef = _db.collection('eb_events').doc(eventId);
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