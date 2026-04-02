// eb_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/eb_event.dart';

class EBServices {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'eb_events';

  // ── Stream (real-time) ─────────────────────────────────────────────────────

  static Stream<List<EBEvent>> eventsStream() {
    return _db
        .collection(_collection)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs.map(EBEvent.fromFirestore).toList());
  }

  static Stream<List<EBEvent>> eventsForDateStream(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((snap) {
          debugPrint('=== EB snap docs count: ${snap.docs.length}');
          return snap.docs.map(EBEvent.fromFirestore).toList();
        });
  }

  // ── One-time fetch ─────────────────────────────────────────────────────────

  static Future<List<EBEvent>> fetchEventsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _db
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .get();
    return snap.docs.map(EBEvent.fromFirestore).toList();
  }

  // ── Fetch buildings from Firestore ─────────────────────────────────────────

  static Future<List<Map<String, String>>> fetchBuildings() async {
    final snap = await _db
        .collection('buildings')
        .where('feature_type', isEqualTo: 'building')
        .get();
    final list = snap.docs.map((doc) {
      final m = doc.data();
      return {
        'code': (m['abbrev'] ?? '').toString(),
        'name': (m['name'] ?? '').toString(),
      };
    }).toList();

    list.sort((a, b) => a['name']!.compareTo(b['name']!));
    return list;
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  static Future<void> addEvent(EBEvent event) async {
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

  static Future<String> buildingDisplayName(String code) async {
    final buildings = await fetchBuildings();
    final match = buildings.firstWhere(
      (b) => b['code'] == code,
      orElse: () => {'code': code, 'name': code},
    );
    return '${match['code']} - ${match['name']}';
  }

  static Future<List<EBCategory>> categoriesOnDay(DateTime day) async {
    final events = await fetchEventsForDate(day);
    final cats = events.map((e) => e.category).toSet().toList();
    cats.sort((a, b) => a.index.compareTo(b.index));
    return cats;
  }
}