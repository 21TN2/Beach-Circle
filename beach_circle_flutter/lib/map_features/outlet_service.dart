import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OutletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, String>>> fetchBuildings() async {
    final snapshot =
        await _db
            .collection('buildings')
            .where('feature_type', isEqualTo: 'building')
            .get();

    final buildings =
        snapshot.docs
            .map((doc) {
              final data = doc.data();

              return {
                'id': doc.id,
                'code': (data['abbrev'] ?? '').toString().trim(),
                'name': (data['name'] ?? '').toString().trim(),
              };
            })
            .where((building) {
              final code = (building['code'] ?? '').toLowerCase().trim();
              final name = (building['name'] ?? '').toLowerCase().trim();

              final isExcludedCode = code == 'g12' || code == 'g14';

              final isExcludedName =
                  name == 'g12' ||
                  name == 'g14' ||
                  name.contains('sand courts') ||
                  name.contains('softball complex') ||
                  name.contains('tennis center') ||
                  name.contains('soccer and softball clubhouse') ||
                  name.contains('parking') ||
                  name.contains('structure') ||
                  name.contains('lot') ||
                  name.contains('field') ||
                  name.contains('fields') ||
                  name.contains('stadium') ||
                  name.contains('track') ||
                  name.contains('diamond');

              return !isExcludedCode && !isExcludedName;
            })
            .toList();

    buildings.sort((a, b) {
      final aName = (a['name'] ?? '').toLowerCase();
      final bName = (b['name'] ?? '').toLowerCase();
      return aName.compareTo(bName);
    });

    return buildings;
  }

  Future<void> addOutlet({
    required String buildingId,
    required String buildingCode,
    required String buildingName,
    required String roomNumber,
    required int outletCount,
    required List<String> outletTypes,
    required List<String> accessibilityLevels,
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

    await _db.collection('outlets').add({
      'buildingId': buildingId,
      'buildingAbbrev': buildingCode,
      'buildingName': buildingName,
      'coords': buildingData['coords'],
      'roomNumber': roomNumber,
      'outletCount': outletCount,
      'outletTypes': outletTypes,
      'accessibilityLevels': accessibilityLevels,
      'status': 'approved',
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
