// eb_event.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum EventBoardCategory {
  athletics,    // 🟡 Yellow  – spirit / sports
  organization, // 🟠 Orange  – club / org
  academic,     // 🟢 Olive   – academic / workshops
}

extension EventBoardCategoryExtension on EventBoardCategory {
  Color get color {
    switch (this) {
      case EventBoardCategory.athletics:
        return const Color(0xFFFFCC00);
      case EventBoardCategory.organization:
        return const Color(0xFFF5A623);
      case EventBoardCategory.academic:
        return const Color(0xFF8DB600);
    }
  }

  String get label {
    switch (this) {
      case EventBoardCategory.athletics:
        return 'Athletics';
      case EventBoardCategory.organization:
        return 'Organization';
      case EventBoardCategory.academic:
        return 'Academic';
    }
  }
}

// ── EventBoardEvent model ────────────────────────────────────────────────────

class EventBoardEvent {
  final String id;
  final String title;
  final String location;
  final String buildingCode;
  final String roomNumber;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay? endTime; // null = all-day
  final bool isAllDay;
  final String description;
  final String links;
  final EventBoardCategory category;
  final String? imageUrl;
  final String? createdBy;
  bool isInterested;
  final int? interestedCount;

  EventBoardEvent({
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

  // ── Firestore serialization ──────────────────────────────────────────────

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
      'endTime': endTime == null
          ? null
          : Timestamp.fromDate(DateTime(
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

  factory EventBoardEvent.fromFirestore(DocumentSnapshot doc) {
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

    return EventBoardEvent(
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
      category: EventBoardCategory.values[m['category'] ?? 0],
      imageUrl: m['imageUrl'],
      createdBy: (m['createdBy'] ?? '').toString(),
      interestedCount: m['interestedCount'] as int?,
      isInterested: m['isInterested'] ?? false,
    );
  }
}