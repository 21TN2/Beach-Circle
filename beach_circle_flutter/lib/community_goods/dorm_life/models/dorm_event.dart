import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Category enum ────────────────────────────────────────────────────────────

enum DormCategory {
  athletics,    // 🟡 Yellow  – spirit / sports
  organization, // 🟠 Orange  – club / meetings
  residential,  // 🟢 Olive   – hall / residential
}

extension DormCategoryExtension on DormCategory {
  Color get color {
    switch (this) {
      case DormCategory.athletics:
        return const Color(0xFFFFCC00);
      case DormCategory.organization:
        return const Color(0xFFF5A623);
      case DormCategory.residential:
        return const Color(0xFF8DB600);
    }
  }

  String get label {
    switch (this) {
      case DormCategory.athletics:
        return 'Athletics';
      case DormCategory.organization:
        return 'Organization';
      case DormCategory.residential:
        return 'Residential';
    }
  }
}

// ── DormEvent model ──────────────────────────────────────────────────────────

class DormEvent {
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
  final DormCategory category;
  bool isInterested;

  DormEvent({
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
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime?.hour,
      'endMinute': endTime?.minute,
      'isAllDay': isAllDay,
      'description': description,
      'links': links,
      'category': category.index,
      'isInterested': isInterested,
    };
  }

  factory DormEvent.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return DormEvent(
      id: doc.id,
      title: m['title'] ?? '',
      location: m['location'] ?? '',
      buildingCode: m['buildingCode'] ?? '',
      roomNumber: m['roomNumber'] ?? '',
      date: (m['date'] as Timestamp).toDate(),
      startTime: TimeOfDay(
          hour: m['startHour'] ?? 0, minute: m['startMinute'] ?? 0),
      endTime: m['endHour'] != null
          ? TimeOfDay(hour: m['endHour'], minute: m['endMinute'] ?? 0)
          : null,
      isAllDay: m['isAllDay'] ?? false,
      description: m['description'] ?? '',
      links: m['links'] ?? '',
      category: DormCategory.values[m['category'] ?? 0],
      isInterested: m['isInterested'] ?? false,
    );
  }
}