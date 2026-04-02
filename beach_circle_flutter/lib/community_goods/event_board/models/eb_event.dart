// eb_event.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum EBCategory {
  sports,    // 🔘 Grey    – sports / athletics
  clubs,     // 🟤 Beige   – club events
  asi,       // 🟦 Pine Blue – ASI events
}

extension EBCategoryExtension on EBCategory {
  Color get color {
    switch (this) {
      case EBCategory.sports:
        return const Color(0xFF757780);
      case EBCategory.clubs:
        return const Color(0xFFD2CCA1);
      case EBCategory.asi:
        return const Color(0xFF387780);
    }
  }

  String get label {
    switch (this) {
      case EBCategory.sports:
        return 'Sports';
      case EBCategory.clubs:
        return 'Clubs';
      case EBCategory.asi:
        return 'ASI Events';
    }
  }
}

// ── EBEvent model ─────────────────────────────────────────────────────────────

class EBEvent {
  final String id;
  final String title;
  final String location;
  final String buildingCode;
  final String roomNumber;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final String description;
  final String links;
  final EBCategory category;
  final String? imageUrl;
  final String? createdBy;
  bool isInterested;
  final int? interestedCount;

  EBEvent({
    required this.id,
    required this.title,
    required this.location,
    this.buildingCode = '',
    this.roomNumber = '',
    required this.date,
    required this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.description = '',
    this.links = '',
    required this.category,
    this.imageUrl,
    this.createdBy = '',
    this.interestedCount,
    this.isInterested = false,
  });

  /// "6:00 PM - 7:30 PM" or "All-Day"
  String get timeDisplay {
    if (isAllDay) return 'All-Day';
    String fmt(TimeOfDay t) {
      final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final min = t.minute.toString().padLeft(2, '0');
      final period = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$min $period';
    }
    return endTime == null
        ? fmt(startTime)
        : '${fmt(startTime)} - ${fmt(endTime!)}';
  }

  // ── Firestore serialization ────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'buildingCode': buildingCode,
      'roomNumber': roomNumber,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(DateTime(
        date.year, date.month, date.day,
        startTime.hour, startTime.minute,
      )),
      'endTime': endTime == null ? null : Timestamp.fromDate(DateTime(
        date.year, date.month, date.day,
        endTime!.hour, endTime!.minute,
      )),
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime?.hour,
      'endMinute': endTime?.minute,
      'isAllDay': isAllDay,
      'description': description,
      'links': links.trim().isEmpty ? '' : links,
      'category': category.index,
      'imageUrl': imageUrl,
      'isInterested': isInterested,
      'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      'status': 'approved',
    };
  }

  factory EBEvent.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;

    final rawLinks = [
      m['links'],
      m['link'],
      m['flyerLink'],
      m['flyer_link'],
    ].firstWhere(
      (v) => v != null && v.toString().trim().isNotEmpty,
      orElse: () => '',
    );

    return EBEvent(
      id: doc.id,
      title: (m['title'] ?? '').toString(),
      location: (m['location'] ?? '').toString(),
      buildingCode: (m['buildingCode'] ?? '').toString(),
      roomNumber: (m['roomNumber'] ?? '').toString(),
      date: (m['date'] as Timestamp).toDate(),
      startTime: TimeOfDay(
        hour: m['startHour'] ?? 0,
        minute: m['startMinute'] ?? 0,
      ),
      endTime: m['endHour'] != null
          ? TimeOfDay(hour: m['endHour'], minute: m['endMinute'] ?? 0)
          : null,
      isAllDay: m['isAllDay'] ?? false,
      description: (m['description'] ?? '').toString(),
      links: (rawLinks == null || rawLinks.toString().trim() == 'null')
          ? ''
          : rawLinks.toString().trim(),
      category: EBCategory.values[m['category'] ?? 0],
      imageUrl: m['imageUrl'],
      createdBy: (m['createdBy'] ?? '').toString(),
      interestedCount: m['interestedCount'] as int?,
      isInterested: m['isInterested'] ?? false,
    );
  }
}