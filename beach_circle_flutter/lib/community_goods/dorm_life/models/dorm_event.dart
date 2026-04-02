// TIFF
// dorm_event.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final String? imageUrl;   // ← new
  final String? createdBy;
  bool isInterested;
  final int? interestedCount;

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
    this.imageUrl,       
    this.createdBy ='',    // ← new
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
      'imageUrl': imageUrl,  // ← new
      'isInterested': isInterested,
      'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      'status': 'approved',
    };
  }

  factory DormEvent.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;

    // To this (handles cases where field exists but is null/empty):
    final rawLinks = [
      m['links'],
      m['link'],
      m['flyerLink'],
      m['flyer_link'],
    ].firstWhere(
      (v) => v != null && v.toString().trim().isNotEmpty,
      orElse: () => '',
    );
    debugPrint('=== fromFirestore rawLinks: "$rawLinks"');  // ← add this
    debugPrint('=== m[links] value: "${m['links']}"');      // ← add this
    
    return DormEvent(
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
      category: DormCategory.values[m['category'] ?? 0],
      imageUrl: m['imageUrl'],
      createdBy: (m['createdBy'] ?? '').toString(), // ↓ ADD THIS
      interestedCount: m['interestedCount'] as int?,
      isInterested: m['isInterested'] ?? false,
    );
  }
}