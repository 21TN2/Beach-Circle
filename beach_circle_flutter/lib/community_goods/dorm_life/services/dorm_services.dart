import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';  // ← add this line
import '../models/dorm_event.dart';

// dorm_services.dart
// ── DormServices ─────────────────────────────────────────────────────────────
// All Firestore reads/writes for dorm events live here.
// Screens call these methods and use setState() to rebuild.

class DormServices {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'dorm_events';

  // ── Stream (real-time) ─────────────────────────────────────────────────────

  /// Live stream of ALL dorm events, ordered by date.
  static Stream<List<DormEvent>> eventsStream() {
    return _db
        .collection(_collection)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs.map(DormEvent.fromFirestore).toList());
  }

  /// Live stream filtered to a specific [date].
  static Stream<List<DormEvent>> eventsForDateStream(DateTime date) {
  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));
  return _db
      .collection(_collection)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThan: Timestamp.fromDate(end))
      .orderBy('date')
      .snapshots()
      .map((snap) {
        debugPrint('=== snap docs count: ${snap.docs.length}');
        for (final doc in snap.docs) {
          final m = doc.data();
          debugPrint('=== doc links field: "${m['links']}"');
        }
        return snap.docs.map(DormEvent.fromFirestore).toList();
      });
}

  // ── One-time fetch ─────────────────────────────────────────────────────────

  static Future<List<DormEvent>> fetchEventsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _db
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .get();
    return snap.docs.map(DormEvent.fromFirestore).toList();
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  static Future<void> addEvent(DormEvent event) async {
    await _db.collection(_collection).add(event.toMap());
  }

  // ── Update interested ──────────────────────────────────────────────────────

  static Future<void> toggleInterested(String eventId, bool current) async {
    await _db
        .collection(_collection)
        .doc(eventId)
        .update({'isInterested': !current});
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  static Future<void> deleteEvent(String eventId) async {
    await _db.collection(_collection).doc(eventId).delete();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Building options for the create-form dropdown.
  static const List<Map<String, String>> buildings = [
    {'code': 'SSSC', 'name': 'SHAKARIAN STUDENT SUCCESS'},
    {'code': 'SSPA', 'name': 'SOCIAL SCIENCE/PUBLIC AFFAIRS'},
    {'code': 'HC',   'name': 'STEVE & NINI HORN CENTER'},
    {'code': 'SHS',  'name': 'STUDENT HEALTH SERVICES'},
    {'code': 'SRWC', 'name': 'STUDENT REC. & WELL. CENTER'},
    {'code': 'TA',   'name': 'THEATER ARTS'},
  ];

  static String buildingDisplayName(String code) {
    final match = buildings.firstWhere(
      (b) => b['code'] == code,
      orElse: () => {'code': code, 'name': code},
    );
    return '${match['code']} - ${match['name']}';
  }

  /// Returns which categories have events on [day] (for date-strip dots).
  static Future<List<DormCategory>> categoriesOnDay(DateTime day) async {
    final events = await fetchEventsForDate(day);
    final cats = events.map((e) => e.category).toSet().toList();
    cats.sort((a, b) => a.index.compareTo(b.index));
    return cats;
  }
}