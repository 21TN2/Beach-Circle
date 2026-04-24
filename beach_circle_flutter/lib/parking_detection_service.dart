import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType; 
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ParkingState { none, searching, parked }

class ParkingLot {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusInMeters;

  ParkingLot(this.id, this.name, this.latitude, this.longitude, this.radiusInMeters);
}

class ParkingDetectionService {
  static final ParkingDetectionService _instance = ParkingDetectionService._internal();
  factory ParkingDetectionService() => _instance;
  ParkingDetectionService._internal();

  final List<ParkingLot> _campusLots = [
    ParkingLot('lot_g3', 'Lot G3', 33.7838, -118.1141, 150), 
    ParkingLot('pyramid_struct', 'Pyramid Structure', 33.7875, -118.1130, 100),
  ];

  ParkingState _currentState = ParkingState.none;
  ParkingLot? _currentLot;
  StreamSubscription<Activity>? _activitySubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> startMonitoring() async {
    bool locationGranted = await _requestLocationPermission();
    bool activityGranted = await _requestActivityPermission();

    if (!locationGranted || !activityGranted) {
      debugPrint("Missing permissions for Parking Detection.");
      return;
    }

    _activitySubscription = FlutterActivityRecognition.instance.activityStream.listen((Activity activity) {
      _evaluateParkingSituation(activity);
    });
  }

  void stopMonitoring() {
    _activitySubscription?.cancel();
  }

  Future<void> _evaluateParkingSituation(Activity activity) async {
    // FIX: Using UPPERCASE constants for v4.0.0
    if (activity.confidence == ActivityConfidence.LOW) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      ParkingLot? activeLot = _getLotIfInside(position);
      
      if (activeLot == null) {
        if (_currentState != ParkingState.none) {
          _updateFirebaseState(ParkingState.none, _currentLot?.id);
        }
        _currentState = ParkingState.none;
        _currentLot = null;
        return;
      }

      // FIX: Using UPPERCASE IN_VEHICLE
      if (activity.type == ActivityType.IN_VEHICLE) {
        if (_currentState != ParkingState.searching) {
          _currentState = ParkingState.searching;
          _currentLot = activeLot;
          _updateFirebaseState(ParkingState.searching, activeLot.id);
        }
      } 
      // FIX: Using UPPERCASE WALKING and STILL
      else if (_currentState == ParkingState.searching && 
              (activity.type == ActivityType.WALKING || activity.type == ActivityType.STILL)) {
        
        _currentState = ParkingState.parked;
        _updateFirebaseState(ParkingState.parked, activeLot.id);
      }

    } catch (e) {
      debugPrint("Error evaluating parking state: $e");
    }
  }

  ParkingLot? _getLotIfInside(Position position) {
    for (var lot in _campusLots) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lot.latitude,
        lot.longitude,
      );

      if (distance <= lot.radiusInMeters) {
        return lot; 
      }
    }
    return null; 
  }

  Future<void> _updateFirebaseState(ParkingState newState, String? lotId) async {
    if (lotId == null || _auth.currentUser == null) return;
    
    final userId = _auth.currentUser!.uid;
    final lotRef = _firestore.collection('parking_lots').doc(lotId);
    final userRef = _firestore.collection('users').doc(userId);

    WriteBatch batch = _firestore.batch();

    batch.update(userRef, {'parking_status': newState.toString()});

    if (newState == ParkingState.searching) {
      batch.update(lotRef, {'searching_count': FieldValue.increment(1)});
    } else if (newState == ParkingState.parked) {
      batch.update(lotRef, {
        'searching_count': FieldValue.increment(-1),
        'parked_count': FieldValue.increment(1)
      });
    } else if (newState == ParkingState.none) {
      if (_currentState == ParkingState.parked) {
        batch.update(lotRef, {'parked_count': FieldValue.increment(-1)});
      } else if (_currentState == ParkingState.searching) {
        batch.update(lotRef, {'searching_count': FieldValue.increment(-1)});
      }
    }

    await batch.commit();
    debugPrint("Parking Status Updated to: $newState for Lot: $lotId");
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<bool> _requestActivityPermission() async {
    ActivityPermission result = await FlutterActivityRecognition.instance.checkPermission();
    // FIX: Using UPPERCASE DENIED, PERMANENTLY_DENIED, and GRANTED
    if (result == ActivityPermission.DENIED || result == ActivityPermission.PERMANENTLY_DENIED) {
      result = await FlutterActivityRecognition.instance.requestPermission();
    }
    return result == ActivityPermission.GRANTED;
  }
}