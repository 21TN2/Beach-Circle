import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as maps_toolkit;
import 'package:cloud_firestore/cloud_firestore.dart';

enum ParkingState { none, searching, parked }

class ParkingZone {
  final String name;
  final List<maps_toolkit.LatLng> polygon;
  final String zoneGroup;

  ParkingZone(this.name, this.polygon, this.zoneGroup);
}

class ParkingDetectionService {
  static final ParkingDetectionService _instance = ParkingDetectionService._internal();
  factory ParkingDetectionService() => _instance;
  ParkingDetectionService._internal();

  final List<ParkingZone> _campusLots = [];
  
  ParkingState _currentState = ParkingState.none;
  ParkingZone? _currentLot;
  
  StreamSubscription<Activity>? _activitySubscription;
  StreamSubscription<Position>? _positionSubscription;
  Position? _latestPosition;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  // 1. Initialize and load the GeoJSON
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadGeoJsonData();
    _isInitialized = true;
  }

  Future<void> _loadGeoJsonData() async {
    try {
      final String geoJsonString = await rootBundle.loadString('assets/csulb.geojson');
      final Map<String, dynamic> geoJson = json.decode(geoJsonString);
      final List features = geoJson['features'] ?? [];

      for (var feature in features) {
        final properties = feature['properties'] ?? {};
        final geometry = feature['geometry'] ?? {};
        
        final featureType = (properties['feature_type'] ?? '').toString();
        final lotName = (properties['name'] ?? '').toString().trim();
        
        // Find parking features
        if (featureType == 'parking' || lotName.toUpperCase().contains('LOT ') || lotName.toUpperCase().contains('STRUCTURE')) {
          final type = geometry['type'];
          final coords = geometry['coordinates'];
          
          List<maps_toolkit.LatLng> polygonPoints = [];

          try {
             if (type == 'Polygon') {
               for (var point in coords[0]) {
                 // maps_toolkit uses LatLng (Latitude first, Longitude second)
                 polygonPoints.add(maps_toolkit.LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble()));
               }
             } else if (type == 'MultiPolygon') {
               for (var point in coords[0][0]) {
                 polygonPoints.add(maps_toolkit.LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble()));
               }
             }
          } catch (e) {
             continue;
          }

          if (polygonPoints.isNotEmpty && lotName.isNotEmpty) {
            String zoneGroup = _determineZoneGroup(lotName);
            _campusLots.add(ParkingZone(lotName, polygonPoints, zoneGroup));
          }
        }
      }
      debugPrint("Loaded ${_campusLots.length} parking zones from GeoJSON.");
    } catch (e) {
      debugPrint("Error loading GeoJSON for detection: $e");
    }
  }

  String _determineZoneGroup(String lotName) {
    final name = lotName.toUpperCase();
    if (name.contains(' G') || name.startsWith('G')) return 'G Lots';
    if (name.contains(' E') || name.startsWith('E')) return 'E Lots';
    if (name.contains('PYRAMID')) return 'Pyramid';
    if (name.contains('PALO VERDE') || name.contains('PV')) return 'Palo Verde';
    return 'Other';
  }

  // 2. Start the tracking streams
  Future<void> startMonitoring() async {
    await initialize();

    bool locationGranted = await _requestLocationPermission();
    bool activityGranted = await _requestActivityPermission();

    if (!locationGranted || !activityGranted) {
      debugPrint("Missing permissions for Parking Detection.");
      return;
    }

    // Listen to GPS
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      _latestPosition = position;
      _evaluateParkingSituation();
    });

    // Listen to Activity (Driving, Walking, etc)
    _activitySubscription = FlutterActivityRecognition.instance.activityStream.listen((Activity activity) {
      // Only care about high confidence activity changes to avoid false positives
      if (activity.confidence != ActivityConfidence.LOW) {
        _evaluateParkingSituation(latestActivity: activity);
      }
    });
  }

  void stopMonitoring() {
    _activitySubscription?.cancel();
    _positionSubscription?.cancel();
  }

  // 3. The Core Logic Engine
  Future<void> _evaluateParkingSituation({Activity? latestActivity}) async {
    if (_latestPosition == null) return;

    // Check if the user is inside any known parking polygon
    ParkingZone? activeLot = _getLotIfInside(_latestPosition!);
    
    // If they are not in a lot, reset everything.
    if (activeLot == null) {
      if (_currentState != ParkingState.none) {
        _updateFirebaseState(ParkingState.none, _currentLot?.name);
      }
      _currentState = ParkingState.none;
      _currentLot = null;
      return;
    }

    // If we don't have a new activity, we can't make a decision yet.
    if (latestActivity == null) return;

    // LOGIC: Inside a parking lot AND in a vehicle = Searching for parking
    if (latestActivity.type == ActivityType.IN_VEHICLE) {
      if (_currentState != ParkingState.searching) {
        _currentState = ParkingState.searching;
        _currentLot = activeLot;
        _updateFirebaseState(ParkingState.searching, activeLot.name);
      }
    }
    // LOGIC: Inside a parking lot AND was searching AND is now walking/still = Parked!
    else if (_currentState == ParkingState.searching &&
            (latestActivity.type == ActivityType.WALKING || latestActivity.type == ActivityType.STILL)) {
      _currentState = ParkingState.parked;
      _updateFirebaseState(ParkingState.parked, activeLot.name);
    }
  }

  // 4. Point-in-Polygon Math
  ParkingZone? _getLotIfInside(Position position) {
    final userPoint = maps_toolkit.LatLng(position.latitude, position.longitude);
    
    for (var lot in _campusLots) {
      // Use maps_toolkit to check if the GPS point is inside the GeoJSON shape!
      bool isInside = maps_toolkit.PolygonUtil.containsLocation(userPoint, lot.polygon, false);
      if (isInside) {
        return lot;
      }
    }
    return null;
  }

  // 5. Update the live counts
  Future<void> _updateFirebaseState(ParkingState newState, String? lotName) async {
    if (lotName == null) return;
    
    try {
      final query = await _firestore.collection('parking_lots').where('name', isEqualTo: lotName).get();
      DocumentReference lotRef;

      if (query.docs.isNotEmpty) {
        lotRef = query.docs.first.reference;
      } else {
        // If the lot isn't in Firebase yet, create it.
        lotRef = await _firestore.collection('parking_lots').add({
          'name': lotName,
          'zone': _determineZoneGroup(lotName),
          'searching_count': 0,
          'parked_count': 0,
        });
      }

      if (newState == ParkingState.searching) {
        lotRef.update({'searching_count': FieldValue.increment(1)});
        debugPrint("User started searching in $lotName");
      } 
      else if (newState == ParkingState.parked) {
        lotRef.update({
          'searching_count': FieldValue.increment(-1),
          'parked_count': FieldValue.increment(1)
        });
        debugPrint("User successfully parked in $lotName!");
      } 
      else if (newState == ParkingState.none) {
        if (_currentState == ParkingState.parked) {
          lotRef.update({'parked_count': FieldValue.increment(-1)});
        } else if (_currentState == ParkingState.searching) {
          lotRef.update({'searching_count': FieldValue.increment(-1)});
        }
        debugPrint("User left $lotName");
      }
    } catch (e) {
      debugPrint("Error updating Firebase parking state: $e");
    }
  }

  // --- Permission Helpers ---
  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<bool> _requestActivityPermission() async {
    ActivityPermission result = await FlutterActivityRecognition.instance.checkPermission();
    if (result == ActivityPermission.DENIED || result == ActivityPermission.PERMANENTLY_DENIED) {
      result = await FlutterActivityRecognition.instance.requestPermission();
    }
    return result == ActivityPermission.GRANTED;
  }
}