import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudyHallService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> fetchBuildings() async {
    final snapshot = await _db.collection('buildings').get();

    final buildings =
        snapshot.docs.map((doc) {
          final data = doc.data();

          return {
            'id': doc.id,
            'abbrev': (data['abbrev'] ?? '').toString(),
            'name': (data['name'] ?? '').toString(),
            'coords': data['coords'],
          };
        }).toList();

    buildings.sort((a, b) {
      final aLabel = (a['abbrev'] ?? '').toString();
      final bLabel = (b['abbrev'] ?? '').toString();
      return aLabel.compareTo(bLabel);
    });

    return buildings;
  }

  Future<void> addStudyHall({
    required String buildingId,
    required String buildingAbbrev,
    required String roomNumber,
    required String startTime,
    required String endTime,
    required int seatCapacity,
    required List<String> amenities,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User must be signed in.');
    }

    final buildingDoc = await _db.collection('buildings').doc(buildingId).get();

    if (!buildingDoc.exists) {
      throw Exception('Selected building was not found.');
    }

    final buildingData = buildingDoc.data() ?? {};

    await _db.collection('study_halls').add({
      'buildingId': buildingId,
      'buildingAbbrev': buildingAbbrev,
      'buildingName': (buildingData['name'] ?? '').toString(),
      'coords': buildingData['coords'],
      'roomNumber': roomNumber,
      'startTime': startTime,
      'endTime': endTime,
      'seatCapacity': seatCapacity,
      'amenities': amenities,
      'status': 'approved',
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
