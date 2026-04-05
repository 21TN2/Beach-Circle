import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bathroom_finder.dart';

import '../map_features/add_study_hall_screen.dart';
import '../map_features/add_outlet_screen.dart';
import '../map_features/expanded_study_hall_screen.dart';
import '../map_features/food_alert.dart';
import '../map_features/expanded_outlet_screen.dart';


// add active pins (or phase out?)

enum _FoodAlertStep { none, placingPin, fillingForm }

class FilterOption {
  final String key;
  final IconData icon;
  final String label;
  final bool hasBottomSheet;
  final Widget? sheetContent;

  const FilterOption({
    required this.key,
    required this.icon,
    required this.label,
    required this.hasBottomSheet,
    this.sheetContent,
  });
}

class MapScreen extends StatefulWidget {
  final String? initialFilter;
  const MapScreen({super.key, this.initialFilter});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  PointAnnotationManager? _devPinManager;
  PointAnnotation? _devPin;
  CircleAnnotationManager? _devCircleManager;
  CircleAnnotation? _devCircle;
  bool _isDevMode = false;
  Position? _simulatedPosition;

  // NEW FROM GISELLE: to select filter building from study hall + outlet
  String? _activeFilter;
  String _selectedStudyBuildingFilter = 'All';
  String? _selectedExactStudyBuilding;

  String _selectedOutletBuildingFilter = 'All';
  String? _selectedExactOutletBuilding;

  // study hall
  PointAnnotationManager? _studyHallPinManager;
  final Map<String, Map<String, dynamic>> _studyHallPinData = {};

  // outlet
  PointAnnotationManager? _outletPinManager;
  final Map<String, Map<String, dynamic>> _outletPinData = {};

  // NEW FROM GISELLE: STUDY HALL BUILDING FILTERS
  String _mapBuildingToStudyFilter(String building) {
    final code = building.toUpperCase().trim();

    if (code.startsWith('LA')) return 'LA';
    if (code.startsWith('EN') || code.startsWith('ENGR')) return 'ENGR';
    if (code.startsWith('FA')) return 'FA';
    if (code.startsWith('HHS')) return 'HHS';
    if (code == 'COB') return 'COB';
    if (code == 'KIN') return 'KIN';
    if (code == 'HHS') return 'HHS';
    if (code == 'PSY') return 'PSY';
    if (code == 'HSCI' || code.contains('SCI')) return 'HSCI';

    return 'All';
  }

  // FILTERS TO BUILDING
  void _handleStudyHallPinTap(Map<String, dynamic> data) {
    final building = (data['buildingAbbrev'] ?? '').toString().trim();
    final mappedFilter = _mapBuildingToStudyFilter(building);

    setState(() {
      _activeFilter = 'study';

      if (mappedFilter == 'All') {
        _selectedStudyBuildingFilter = 'All';
        _selectedExactStudyBuilding = building;
      } else {
        _selectedStudyBuildingFilter = mappedFilter;
        _selectedExactStudyBuilding = null;
      }
    });
  }

  String _mapBuildingToOutletFilter(String building) {
    final code = building.toUpperCase().trim();

    if (code.startsWith('LA')) return 'LA';
    if (code.startsWith('EN') || code.startsWith('ENGR')) return 'ENGR';
    if (code.startsWith('FA')) return 'FA';
    if (code.startsWith('HHS')) return 'HHS';
    if (code == 'COB') return 'COB';
    if (code == 'KIN') return 'KIN';
    if (code == 'PSY' || code.startsWith('PSY')) return 'PSY';
    if (code == 'HSCI' || code.contains('SCI')) return 'HSCI';

    return 'All';
  }

  // NEW FROM GISELLE: OUTLET BUILDING FILTER
  void _handleOutletPinTap(Map<String, dynamic> data) {
    final building = (data['buildingAbbrev'] ?? '').toString().trim();
    final mappedFilter = _mapBuildingToOutletFilter(building);

    setState(() {
      _activeFilter = 'charging';

      if (mappedFilter == 'All') {
        _selectedOutletBuildingFilter = 'All';
        _selectedExactOutletBuilding = building;
      } else {
        _selectedOutletBuildingFilter = mappedFilter;
        _selectedExactOutletBuilding = null;
      }
    });
  }

  // --------

  //food alert form creation stuff
  _FoodAlertStep _foodAlertStep = _FoodAlertStep.none;
  Position? _foodAlertPinPosition;
  PointAnnotationManager? _foodAlertPinManager;
  PointAnnotation? _foodAlertPin;
  Uint8List? _foodAlertMarkerBytes;

  
  // Manager and data map for live food-alert map pins (food filter)
  PointAnnotationManager? _foodAlertMapPinManager;
  final Map<String, Map<String, dynamic>> _foodAlertPinData = {};

  

  static const double _centerLat = 33.7820;
  static const double _centerLng = -118.1126;

  static final campusBounds = CoordinateBounds(
    southwest: Point(coordinates: Position(-118.1225, 33.77387)),
    northeast: Point(coordinates: Position(-118.1070, 33.78988)),
    infiniteBounds: false,
  );

  static final List<FilterOption> _filters = [
    FilterOption(
      key: 'parking',
      icon: Icons.directions_car,
      label: 'Parking',
      hasBottomSheet: true,
      sheetContent: _ParkingSheetContent(),
    ),
    FilterOption(
      key: 'food',
      icon: Icons.local_pizza,
      label: 'Food',
      hasBottomSheet: true,
      // sheetContent: FoodAlertSheetContent(),
    ),
    FilterOption(
      key: 'study',
      icon: Icons.menu_book,
      label: 'Study',
      hasBottomSheet: true,
    ),
    FilterOption(
      key: 'charging',
      icon: Icons.electric_bolt,
      label: 'Charging',
      hasBottomSheet: true,
    ),
    FilterOption(
      key: 'restroom',
      icon: Icons.wc,
      label: 'Restrooms',
      hasBottomSheet: true,
    ),
  ];

  List<PointAnnotationOptions> _bathroomPinOptions = [];

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
  }

  Future<Uint8List> _createWcMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint backgroundPaint = Paint()..color = const Color(0xFFE8F0FE);
    canvas.drawCircle(const Offset(24.0, 24.0), 24.0, backgroundPaint);
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.wc.codePoint),
      style: TextStyle(
        fontSize: 28.0,
        fontFamily: Icons.wc.fontFamily,
        package: Icons.wc.fontPackage,
        color: Colors.blueAccent,
      ),
    );
    textPainter.layout();
    final double xCenter = (48.0 - textPainter.width) / 2.0;
    final double yCenter = (48.0 - textPainter.height) / 2.0;
    textPainter.paint(canvas, Offset(xCenter, yCenter));
    final ui.Image image = await pictureRecorder.endRecording().toImage(48, 48);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createFoodAlertMarker() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Red circle background
    final Paint bg = Paint()..color = Colors.red;
    canvas.drawCircle(const Offset(24.0, 24.0), 24.0, bg);

    // White pin_drop icon on top
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: String.fromCharCode(Icons.pin_drop.codePoint),
      style: TextStyle(
        fontSize: 28.0,
        fontFamily: Icons.pin_drop.fontFamily,
        package: Icons.pin_drop.fontPackage,
        color: Colors.white,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset((48 - tp.width) / 2, (48 - tp.height) / 2));

    final ui.Image img = await recorder.endRecording().toImage(48, 48);
    final ByteData? bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  // NEW FROM GISELLE: calculate the time to grab what's available / unavailable
  TimeOfDay? _parseTimeOfDay(String value) {
    try {
      final parts = value.trim().split(' ');
      if (parts.length != 2) return null;

      final timePart = parts[0];
      final periodPart = parts[1].toUpperCase();

      final timePieces = timePart.split(':');
      if (timePieces.length != 2) return null;

      int hour = int.parse(timePieces[0]);
      final minute = int.parse(timePieces[1]);

      if (periodPart == 'PM' && hour != 12) {
        hour += 12;
      } else if (periodPart == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  bool _isCurrentlyAvailable(String startTime, String endTime) {
    final start = _parseTimeOfDay(startTime);
    final end = _parseTimeOfDay(endTime);

    if (start == null || end == null) return false;

    final now = TimeOfDay.now();

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    // normal same-day range
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    }

    // overnight range like 11:00 PM - 2:00 AM
    return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
  }

  Future<Uint8List> _createCountMarker({
    required IconData icon,
    required Color circleColor,
    required String badgeText,
    required Color badgeColor,
  }) async {
    const double width = 108;
    const double height = 128;
    const double circleRadius = 38;
    const Offset circleCenter = Offset(54, 60);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Paint shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.18)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    canvas.drawCircle(
      Offset(circleCenter.dx, circleCenter.dy + 3),
      circleRadius,
      shadowPaint,
    );

    final Paint circlePaint = Paint()..color = circleColor;
    canvas.drawCircle(circleCenter, circleRadius, circlePaint);

    final TextPainter iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 38,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.black87,
        ),
      ),
    );

    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        circleCenter.dx - iconPainter.width / 2,
        circleCenter.dy - iconPainter.height / 2,
      ),
    );

    final Rect badgeRect = Rect.fromLTWH(16, 6, 52, 28);
    final RRect badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      const Radius.circular(14),
    );

    final Paint badgePaint = Paint()..color = badgeColor;
    canvas.drawRRect(badgeRRect, badgePaint);

    final TextPainter badgePainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    badgePainter.layout();
    badgePainter.paint(
      canvas,
      Offset(
        badgeRect.left + (badgeRect.width - badgePainter.width) / 2,
        badgeRect.top + (badgeRect.height - badgePainter.height) / 2,
      ),
    );

    final ui.Image image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  // -------

  /// ALSO NEW FROM GISELLE: LOAD STUDY HALL PINS
  Future<void> _loadStudyHallPins() async {
    try {
      if (_studyHallPinManager == null) return;

      await _studyHallPinManager!.deleteAll();
      _studyHallPinData.clear();

      final snapshot =
          await FirebaseFirestore.instance
              .collection('study_halls')
              .where('status', isEqualTo: 'approved')
              .get();

      final Map<String, Map<String, dynamic>> buildingsMap = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final buildingAbbrev = (data['buildingAbbrev'] ?? '').toString().trim();
        final buildingName = (data['buildingName'] ?? '').toString().trim();
        final coords = data['coords'];
        final startTime = (data['startTime'] ?? '').toString();
        final endTime = (data['endTime'] ?? '').toString();

        if (buildingAbbrev.isEmpty) continue;

        if (!buildingsMap.containsKey(buildingAbbrev)) {
          if (coords is List && coords.isNotEmpty) {
            final firstPoint = coords.first;

            if (firstPoint is Map<String, dynamic> &&
                firstPoint['lat'] != null &&
                firstPoint['lng'] != null) {
              buildingsMap[buildingAbbrev] = {
                'buildingAbbrev': buildingAbbrev,
                'buildingName': buildingName,
                'lat': (firstPoint['lat'] as num).toDouble(),
                'lng': (firstPoint['lng'] as num).toDouble(),
                'totalCount': 0,
                'availableNowCount': 0,
              };
            }
          }
        }

        if (buildingsMap.containsKey(buildingAbbrev)) {
          buildingsMap[buildingAbbrev]!['totalCount'] =
              (buildingsMap[buildingAbbrev]!['totalCount'] as int) + 1;

          if (_isCurrentlyAvailable(startTime, endTime)) {
            buildingsMap[buildingAbbrev]!['availableNowCount'] =
                (buildingsMap[buildingAbbrev]!['availableNowCount'] as int) + 1;
          }
        }
      }

      for (final entry in buildingsMap.entries) {
        final buildingData = entry.value;
        final badgeText =
            '${buildingData['availableNowCount']}/${buildingData['totalCount']}';

        final markerBytes = await _createCountMarker(
          icon: Icons.menu_book,
          circleColor: const Color(0xFFE8F0FE),
          badgeText: badgeText,
          badgeColor: const Color(0xFF5F6B8C),
        );

        final annotation = await _studyHallPinManager!.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                buildingData['lng'] as double,
                buildingData['lat'] as double,
              ),
            ),
            image: markerBytes,
            iconSize: 1.0,
          ),
        );

        _studyHallPinData[annotation.id] = {
          'buildingAbbrev': buildingData['buildingAbbrev'],
          'buildingName': buildingData['buildingName'],
        };
      }
    } catch (e) {
      debugPrint('Error loading study hall pins: $e');
    }
  }

  // NEW FROM GISELLE: LOADS OUTLET MAP PINS
  Future<void> _loadOutletPins() async {
    try {
      if (_outletPinManager == null) return;

      await _outletPinManager!.deleteAll();
      _outletPinData.clear();

      final snapshot =
          await FirebaseFirestore.instance
              .collection('outlets')
              .where('status', isEqualTo: 'approved')
              .get();

      final Map<String, Map<String, dynamic>> buildingsMap = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final buildingAbbrev = (data['buildingAbbrev'] ?? '').toString().trim();
        final buildingName = (data['buildingName'] ?? '').toString().trim();
        final coords = data['coords'];

        if (buildingAbbrev.isEmpty) continue;

        if (!buildingsMap.containsKey(buildingAbbrev)) {
          if (coords is List && coords.isNotEmpty) {
            final firstPoint = coords.first;

            if (firstPoint is Map<String, dynamic> &&
                firstPoint['lat'] != null &&
                firstPoint['lng'] != null) {
              buildingsMap[buildingAbbrev] = {
                'buildingAbbrev': buildingAbbrev,
                'buildingName': buildingName,
                'lat': (firstPoint['lat'] as num).toDouble(),
                'lng': (firstPoint['lng'] as num).toDouble(),
                'totalCount': 0,
              };
            }
          }
        }

        if (buildingsMap.containsKey(buildingAbbrev)) {
          buildingsMap[buildingAbbrev]!['totalCount'] =
              (buildingsMap[buildingAbbrev]!['totalCount'] as int) + 1;
        }
      }

      for (final entry in buildingsMap.entries) {
        final buildingData = entry.value;
        final badgeText = '${buildingData['totalCount']}';

        final markerBytes = await _createCountMarker(
          icon: Icons.electric_bolt,
          circleColor: const Color(0xFFFFF4B3),
          badgeText: badgeText,
          badgeColor: const Color(0xFF5F6B8C),
        );

        final annotation = await _outletPinManager!.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                buildingData['lng'] as double,
                buildingData['lat'] as double,
              ),
            ),
            image: markerBytes,
            iconSize: 1.0,
          ),
        );

        _outletPinData[annotation.id] = {
          'buildingAbbrev': buildingData['buildingAbbrev'],
          'buildingName': buildingData['buildingName'],
        };
      }
    } catch (e) {
      debugPrint('Error loading outlet pins: $e');
    }
  }
  // ---------

  Future<void> _loadBuildingBathrooms() async {
    try {
      final String geoJsonString = await rootBundle.loadString(
        'assets/csulb.geojson',
      );
      final Map<String, dynamic> geoJson = json.decode(geoJsonString);
      final List features = geoJson['features'] ?? [];
      final Uint8List customIconBytes = await _createWcMarker();
      _bathroomPinOptions.clear();
      for (var feature in features) {
        final properties = feature['properties'] ?? {};
        final geometry = feature['geometry'] ?? {};
        if (properties['feature_type'] == 'building') {
          final type = geometry['type'];
          final coords = geometry['coordinates'];
          double lat = 0.0, lng = 0.0;
          try {
            if (type == 'Point') {
              lng = (coords[0] as num).toDouble();
              lat = (coords[1] as num).toDouble();
            } else if (type == 'Polygon') {
              lng = (coords[0][0][0] as num).toDouble();
              lat = (coords[0][0][1] as num).toDouble();
            } else if (type == 'MultiPolygon') {
              lng = (coords[0][0][0][0] as num).toDouble();
              lat = (coords[0][0][0][1] as num).toDouble();
            }
          } catch (e) {
            continue;
          }

          if (lat != 0.0) {
            _bathroomPinOptions.add(
              PointAnnotationOptions(
                geometry: Point(coordinates: Position(lng, lat)),
                image: customIconBytes,
                iconSize: 1.0,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading buildings");
    }
  }

  void _onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    await mapboxMap!.gestures.updateSettings(
      GesturesSettings(rotateEnabled: false, pitchEnabled: false),
    );
    await mapboxMap!.setCamera(
      CameraOptions(
        bearing: 0,
        center: Point(coordinates: Position(_centerLng, _centerLat)),
        zoom: 15.0,
      ),
    );
    await mapboxMap!.setBounds(
      CameraBoundsOptions(bounds: campusBounds, minZoom: 13.0, maxZoom: 20.0),
    );
    await mapboxMap!.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    pointAnnotationManager =
        await mapboxMap!.annotations.createPointAnnotationManager();
    pointAnnotationManager?.addOnPointAnnotationClickListener(
      _BathroomClickListener(context),
    );

    _devPinManager =
        await mapboxMap!.annotations.createPointAnnotationManager();
    _devCircleManager =
        await mapboxMap!.annotations.createCircleAnnotationManager();
    _foodAlertPinManager =
        await mapboxMap!.annotations.createPointAnnotationManager();

    _foodAlertMapPinManager =
        await mapboxMap!.annotations.createPointAnnotationManager();
    _foodAlertMapPinManager?.addOnPointAnnotationClickListener(
      _FoodAlertMapPinClickListener(_handleFoodAlertPinTap, _foodAlertPinData),
    );



    _studyHallPinManager =
        await mapboxMap!.annotations.createPointAnnotationManager();
    _studyHallPinManager?.addOnPointAnnotationClickListener(
      _StudyHallClickListener(_handleStudyHallPinTap, _studyHallPinData),
    );

    _outletPinManager =
        await mapboxMap!.annotations.createPointAnnotationManager();
    _outletPinManager?.addOnPointAnnotationClickListener(
      _OutletClickListener(_handleOutletPinTap, _outletPinData),
    );
    _foodAlertMarkerBytes = await _createFoodAlertMarker();
  

    await _loadBuildingBathrooms();
    await _loadStudyHallPins();
    await _loadOutletPins();
    await _updateMapPins();
  }

  void _onMapTapped(MapContentGestureContext context) async {
    if (_foodAlertStep == _FoodAlertStep.placingPin) {
      await _placeFoodAlertPin(context.point);
      return;
    }
    if (!_isDevMode) return;
    _simulatedPosition = context.point.coordinates;
    if (_devPin != null) await _devPinManager?.delete(_devPin!);
    if (_devCircle != null) await _devCircleManager?.delete(_devCircle!);
    _devCircle = await _devCircleManager?.create(
      CircleAnnotationOptions(
        geometry: context.point,
        circleRadius: 9.0,
        circleColor: const Color(0xFF4285F4).value,
        circleStrokeWidth: 3.0,
        circleStrokeColor: Colors.white.value,
      ),
    );
    _devPin = await _devPinManager?.create(
      PointAnnotationOptions(
        geometry: context.point,
        textField: "You (Simulated)",
        textColor: Colors.black.value,
        textHaloColor: Colors.white.value,
        textHaloWidth: 2.0,
        textOffset: [0.0, 1.2],
      ),
    );
    setState(() {});
  }

  //actually saving the position and coords for food alert. in future consider incporating buildings if matching (if useful)
  Future<void> _placeFoodAlertPin(Point point) async {
    // debugPrint('_foodAlertPinManager is null: ${_foodAlertPinManager == null}');
    // debugPrint('_foodAlertMarkerBytes is null: ${_foodAlertMarkerBytes == null}');
    if (_foodAlertPin != null)
      {await _foodAlertPinManager?.delete(_foodAlertPin!);}
    if (_foodAlertMarkerBytes == null) return;

    _foodAlertPin = await _foodAlertPinManager?.create(
      PointAnnotationOptions(
        geometry: point,
        iconSize: 1.5,
        image: _foodAlertMarkerBytes!,
      ),
    );
    setState(() {
      _foodAlertPinPosition = point.coordinates;
    });
  }

  //initate placing pin for food alert
  void _startFoodAlertFlow() {
    setState(() {
      _activeFilter = null;
      _foodAlertStep = _FoodAlertStep.placingPin;
      _foodAlertPinPosition = null;
    });
  }

  //confirm food alert pin placement and intiate filling out the form
  void _confirmFoodAlertPin() {
    if (_foodAlertPinPosition == null) return;
    setState(() {
      _foodAlertStep = _FoodAlertStep.fillingForm;
    });
  }

  //cancel food alert placement and reset variables
  Future<void> _cancelFoodAlertFlow() async {
    if (_foodAlertPin != null)
      await _foodAlertPinManager?.delete(_foodAlertPin!);
    setState(() {
      _foodAlertStep = _FoodAlertStep.none;
      _foodAlertPin = null;
      _foodAlertPinPosition = null;
    });
  }

    // Fly the map camera to a food alert's coordinates
  void _flyToFoodAlert(double lat, double lng) {
    mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 17.5,
      ),
      MapAnimationOptions(duration: 600),
    );
  }

  // Called when a food-alert map pin is tapped – opens the detail page
  void _handleFoodAlertPinTap(Map<String, dynamic> data) {
    final title = (data['title'] ?? 'Untitled').toString();
    final description = (data['description'] ?? '').toString();
    final docId = (data['docId'] ?? '').toString();
    final alertUserId = (data['userId'] ?? '').toString();
    final currentUserId = data['currentUserId'] as String?;
    final timeStr = (data['timeStr'] ?? '').toString();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodAlertDetailPage(
          docId: docId,
          title: title,
          description: description,
          isActive: true,
          timeStr: timeStr,
          currentUserId: currentUserId,
          alertUserId: alertUserId,
        ),
      ),
    );
  }

  // Load all active food alert pins onto the map
  Future<void> _loadFoodAlertMapPins() async {
    if (_foodAlertMapPinManager == null) return;

    await _foodAlertMapPinManager!.deleteAll();
    _foodAlertPinData.clear();

    final markerBytes = _foodAlertMarkerBytes ?? await _createFoodAlertMarker();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('food_alerts')
          .where('active', isEqualTo: true)
          .get();

      final now = DateTime.now();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['createdAt'] as Timestamp?;

        // Skip pins that have already passed the 5-hour active window
        if (ts != null) {
          final age = now.difference(ts.toDate());
          if (age >= const Duration(hours: 5)) continue;
        }

        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        // Build relative time string for detail page
        String timeStr = '';
        if (ts != null) {
          final diff = now.difference(ts.toDate());
          if (diff.inMinutes < 60) {
            timeStr = '${diff.inMinutes}m ago';
          } else if (diff.inHours < 24) {
            timeStr = '${diff.inHours}h ago';
          } else {
            timeStr = '${diff.inDays}d ago';
          }
        }

        final annotation = await _foodAlertMapPinManager!.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(lng, lat)),
            image: markerBytes,
            iconSize: 1.2,
          ),
        );

        _foodAlertPinData[annotation.id] = {
          'docId': doc.id,
          'title': data['title'] ?? 'Untitled',
          'description': data['description'] ?? '',
          'userId': data['userId'] ?? '',
          'currentUserId': currentUserId,
          'timeStr': timeStr,
          'lat': lat,
          'lng': lng,
        };
      }
    } catch (e) {
      debugPrint('Error loading food alert map pins: $e');
    }
  }



  void _locateUser() {
    if (_isDevMode && _simulatedPosition != null) {
      mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: _simulatedPosition!),
          zoom: 17.0,
        ),
        MapAnimationOptions(duration: 500),
      );
    } else {
      mapboxMap?.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );
    }
  }

  void _zoomIn() async {
    final cameraState = await mapboxMap?.getCameraState();
    mapboxMap?.flyTo(
      CameraOptions(zoom: (cameraState?.zoom ?? 12.0) + 1),
      MapAnimationOptions(duration: 500),
    );
  }

  void _zoomOut() async {
    final cameraState = await mapboxMap?.getCameraState();
    mapboxMap?.flyTo(
      CameraOptions(zoom: (cameraState?.zoom ?? 12.0) - 1),
      MapAnimationOptions(duration: 500),
    );
  }

  void _resetView() {
    mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(_centerLng, _centerLat)),
        zoom: 15.0,
        pitch: 0.0,
        bearing: 0.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  void _onFilterTapped(FilterOption filter) {
    setState(() {
      final wasSameFilter = _activeFilter == filter.key;
      _activeFilter = wasSameFilter ? null : filter.key;

      if (!wasSameFilter && filter.key == 'study') {
        _selectedStudyBuildingFilter = 'All';
        _selectedExactStudyBuilding = null;
      }

      if (!wasSameFilter && filter.key == 'charging') {
        _selectedOutletBuildingFilter = 'All';
        _selectedExactOutletBuilding = null;
      }
    });
    _updateMapPins();
  }

  /// NEW FROM GISELLE: FOR STUDY HALL + OUTLETS
  void _onAddTapped() async {
    if (_activeFilter == 'study') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddStudyHallScreen()),
      );

      if (result == true) {
        await _loadStudyHallPins();
        await _updateMapPins();
        setState(() {});
      }
    } else if (_activeFilter == 'charging') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddOutletScreen()),
      );

      if (result == true) {
        setState(() {});
      }
    }
  }

  // --------
  Future<void> _updateMapPins() async {
    if (pointAnnotationManager == null) return;

    await pointAnnotationManager!.deleteAll();

    if (_activeFilter == 'restroom' && _bathroomPinOptions.isNotEmpty) {
      await pointAnnotationManager!.createMulti(_bathroomPinOptions);
    }

    if (_studyHallPinManager != null) {
      if (_activeFilter == 'study') {
        await _loadStudyHallPins();
      } else {
        await _studyHallPinManager!.deleteAll();
        _studyHallPinData.clear();
      }
    }

    if (_outletPinManager != null) {
      if (_activeFilter == 'charging') {
        await _loadOutletPins();
      } else {
        await _outletPinManager!.deleteAll();
        _outletPinData.clear();
      }
    }

    
    if (_foodAlertMapPinManager != null) {
      if (_activeFilter == 'food') {
        await _loadFoodAlertMapPins();
      } else {
        await _foodAlertMapPinManager!.deleteAll();
        _foodAlertPinData.clear();
      }
    }

  }

  // -----
  Widget? get _activeSheetContent {
    if (_foodAlertStep == _FoodAlertStep.fillingForm) {
      return CreateFoodAlertSheet(
        pinPosition: _foodAlertPinPosition!,
        onClose: _cancelFoodAlertFlow,
        onSubmitted: () {
          _cancelFoodAlertFlow();
          // Refresh food-alert pins on the map
          if (_activeFilter == 'food') {
            _loadFoodAlertMapPins();
          }
        },
      );
    }

    if (_activeFilter == null) return null;

    final Position locationToUse =
        (_isDevMode && _simulatedPosition != null)
            ? _simulatedPosition!
            : Position(_centerLng, _centerLat);

    if (_activeFilter == 'restroom') {
      return _RestroomSheetContent(
        key: ValueKey("restroom-${locationToUse.lng}-${locationToUse.lat}"),
        currentPosition: locationToUse,
      );
    }

    if (_activeFilter == 'study') {
      return _StudySheetContent(
        selectedBuildingFilter: _selectedStudyBuildingFilter,
        selectedExactBuilding: _selectedExactStudyBuilding,
        onBuildingFilterChanged: (value) {
          setState(() {
            _selectedStudyBuildingFilter = value;
            _selectedExactStudyBuilding = null;
          });
        },
        onStudyHallAdded: () async {
          await _loadStudyHallPins();
          await _updateMapPins();
          setState(() {});
        },
      );
    }

    if (_activeFilter == 'charging') {
      return _ChargingSheetContent(
        selectedBuildingFilter: _selectedOutletBuildingFilter,
        selectedExactBuilding: _selectedExactOutletBuilding,
        onBuildingFilterChanged: (value) {
          setState(() {
            _selectedOutletBuildingFilter = value;
            _selectedExactOutletBuilding = null;
          });
        },
        onOutletAdded: () async {
          await _loadOutletPins();
          await _updateMapPins();
          setState(() {});
        },
      );
    }

    final filter = _filters.firstWhere(
      (f) => f.key == _activeFilter,
      orElse: () => _filters.first,
    );

    
    if (_activeFilter == 'food') {
      return FoodAlertSheetContent(
        onAlertSelected: (lat, lng) => _flyToFoodAlert(lat, lng),
      );
    }



    return filter.hasBottomSheet ? filter.sheetContent : null;
  }

  @override
  Widget build(BuildContext context) {
    final sheetContent = _activeSheetContent;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const ui.Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFFF2D21B),
          elevation: 0,
          titleSpacing: 16,
          toolbarHeight: 300,
          title: Container(
            padding: const EdgeInsets.all(5),
            color: const ui.Color.fromARGB(255, 239, 236, 227),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Campus Map',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "DEV",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isDevMode ? Colors.red : Colors.grey,
                      ),
                    ),
                    Switch(
                      value: _isDevMode,
                      activeColor: Colors.red,
                      onChanged: (val) {
                        setState(() {
                          _isDevMode = val;
                        });
                        if (!val) {
                          if (_devPin != null) _devPinManager?.delete(_devPin!);
                          if (_devCircle != null)
                            _devCircleManager?.delete(_devCircle!);
                          _simulatedPosition = null;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          automaticallyImplyLeading: false,
        ),
      ),

      bottomSheet:
          sheetContent != null
              ? _FilterBottomSheet(
                child: sheetContent,
                onClose: () {
                  if (_foodAlertStep == _FoodAlertStep.fillingForm) {
                    _cancelFoodAlertFlow();
                  } else {
                    setState(() => _activeFilter = null);
                    _updateMapPins();
                  }
                },
              )
              : null,
      // -------
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            styleUri: "mapbox://styles/theresa2/cmlbykdmm000s01su4z139emu",
            textureView: true,
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTapped,
          ),

          //Pin placement instructions
          if (_foodAlertStep == _FoodAlertStep.placingPin)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Tap the map to place your food alert pin",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _cancelFoodAlertFlow,
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Filter buttons (hidden during food alert flow)
          if (_foodAlertStep == _FoodAlertStep.none)
            Positioned(
              top: 20,
              bottom: 370,
              right: 12,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children:
                        _filters
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: RawMaterialButton(
                                  onPressed: () => _onFilterTapped(f),
                                  fillColor:
                                      _activeFilter == f.key
                                          ? const Color(0xFFFFCC00)
                                          : const ui.Color.fromARGB(
                                            255,
                                            243,
                                            250,
                                            255,
                                          ),
                                  shape: const CircleBorder(),
                                  constraints: const BoxConstraints.tightFor(
                                    width: 55,
                                    height: 55,
                                  ),
                                  elevation: 4,
                                  child: Icon(
                                    f.icon,
                                    color: Colors.black87,
                                    size: 30,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),

          // Zoom / locate controls (hidden during food alert flow)
          if (_foodAlertStep == _FoodAlertStep.none)
            Positioned(
              bottom: 40,
              left: 15,
              child: Column(
                children: [
                  RawMaterialButton(
                    onPressed: _zoomIn,
                    fillColor: Colors.grey.shade300,
                    shape: const CircleBorder(),
                    constraints: const BoxConstraints.tightFor(
                      width: 46,
                      height: 46,
                    ),
                    elevation: 10,
                    child: const Icon(Icons.add, color: Colors.black),
                  ),
                  const SizedBox(height: 5),
                  RawMaterialButton(
                    onPressed: _zoomOut,
                    fillColor: Colors.grey.shade300,
                    shape: const CircleBorder(),
                    constraints: const BoxConstraints.tightFor(
                      width: 46,
                      height: 46,
                    ),
                    elevation: 10,
                    child: const Icon(Icons.remove, color: Colors.black),
                  ),
                  const SizedBox(height: 5),
                  RawMaterialButton(
                    onPressed: _resetView,
                    fillColor: Colors.grey.shade300,
                    shape: const CircleBorder(),
                    constraints: const BoxConstraints.tightFor(
                      width: 50,
                      height: 50,
                    ),
                    elevation: 10,
                    child: const Icon(Icons.home, color: Colors.black),
                  ),
                  const SizedBox(height: 5),
                  RawMaterialButton(
                    onPressed: _locateUser,
                    fillColor: Colors.blueAccent,
                    shape: const CircleBorder(),
                    constraints: const BoxConstraints.tightFor(
                      width: 50,
                      height: 50,
                    ),
                    elevation: 10,
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ],
              ),
            ),

          //food alert button creation
          if (_activeFilter == 'food' && _foodAlertStep == _FoodAlertStep.none)
            Positioned(
              bottom: 300,
              right: 16,
              child: FloatingActionButton(
                onPressed: _startFoodAlertFlow,
                backgroundColor: Colors.red,
                elevation: 6,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),

          //food alert pin placement (START OF THE WHOLE WORK FLOW) (need to somehow add this button to top)
          if (_foodAlertStep == _FoodAlertStep.placingPin)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _foodAlertPinPosition != null
                              ? _confirmFoodAlertPin
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.red.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        "Confirm Location",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final Widget child;
  final VoidCallback onClose;
  const _FilterBottomSheet({required this.child, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.90,
      expand: false,
      snap: true,
      snapSizes: const [0.35, 0.90],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 40,
                          height: 5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFDDDDDD),
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(
                        Icons.close,
                        size: 22,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _ParkingSheetContent extends StatelessWidget {
  const _ParkingSheetContent();
  @override
  Widget build(BuildContext context) => const _SheetPlaceholder(
    icon: Icons.directions_car,
    label: 'Parking lots and structures',
  );
}

/// NEW FROM GISELLE: STUDY HALL
class _StudySheetContent extends StatelessWidget {
  const _StudySheetContent({
    required this.selectedBuildingFilter,
    required this.selectedExactBuilding,
    required this.onBuildingFilterChanged,
    required this.onStudyHallAdded,
  });

  final String selectedBuildingFilter;
  final String? selectedExactBuilding;
  final ValueChanged<String> onBuildingFilterChanged;
  final Future<void> Function() onStudyHallAdded;

  bool _matchesBuildingFilter(String buildingAbbrev) {
    if (selectedBuildingFilter == 'All') return true;

    final code = buildingAbbrev.trim().toUpperCase();

    switch (selectedBuildingFilter) {
      case 'LA':
        return code.startsWith('LA');
      case 'ENGR':
        return code.startsWith('EN') || code.startsWith('ENGR');
      case 'FA':
        return code.startsWith('FA');
      case 'HSCI':
        return code == 'HSCI' || code.contains('SCI');
      case 'PSY':
        return code == 'PSY' || code.startsWith('PSY');
      case 'HHS':
        return code.startsWith('HHS');
      case 'COB':
        return code == 'COB';
      case 'KIN':
        return code == 'KIN';
      default:
        return code == selectedBuildingFilter;
    }
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    try {
      final parts = value.trim().split(' ');
      if (parts.length != 2) return null;

      final timePart = parts[0];
      final periodPart = parts[1].toUpperCase();

      final timePieces = timePart.split(':');
      if (timePieces.length != 2) return null;

      int hour = int.parse(timePieces[0]);
      final minute = int.parse(timePieces[1]);

      if (periodPart == 'PM' && hour != 12) {
        hour += 12;
      } else if (periodPart == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  bool _isCurrentlyAvailable(String startTime, String endTime) {
    final start = _parseTimeOfDay(startTime);
    final end = _parseTimeOfDay(endTime);

    if (start == null || end == null) return false;

    final now = TimeOfDay.now();

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    }

    return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final buildingFilters = [
      'All',
      'COB',
      'KIN',
      'LA',
      'HSCI',
      'ENGR',
      'FA',
      'PSY',
      'HHS',
    ];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('study_halls')
              .where('status', isEqualTo: 'approved')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Could not load study halls: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredDocs =
            docs.where((doc) {
              final data = doc.data();
              final building = (data['buildingAbbrev'] ?? '').toString().trim();

              if (selectedExactBuilding != null &&
                  selectedExactBuilding!.isNotEmpty) {
                return building.toUpperCase() ==
                    selectedExactBuilding!.toUpperCase();
              }

              return _matchesBuildingFilter(building);
            }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 0, bottom: 5),
              child: Text(
                "Available Classrooms for Study Hall",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 6),

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: buildingFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = buildingFilters[index];
                  final isSelected =
                      selectedExactBuilding == null &&
                      selectedBuildingFilter == filter;

                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => onBuildingFilterChanged(filter),
                    selectedColor: const Color(0xFFF2D21B),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            if (selectedExactBuilding != null &&
                selectedExactBuilding!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Text(
                  'Showing: ${selectedExactBuilding!}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4B3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 22),
              ),
              title: const Text(
                'Add Study Hall',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddStudyHallScreen(),
                  ),
                );

                if (result == true) {
                  await onStudyHallAdded();
                }
              },
            ),

            Divider(color: Colors.grey.shade300, height: 20),

            if (filteredDocs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Text(
                  selectedExactBuilding != null &&
                          selectedExactBuilding!.isNotEmpty
                      ? 'No study halls found for ${selectedExactBuilding!}.'
                      : selectedBuildingFilter == 'All'
                      ? 'No study halls added yet.'
                      : 'No study halls found for $selectedBuildingFilter.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),

            if (filteredDocs.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                itemCount: filteredDocs.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(color: Colors.grey.shade200, height: 1),
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data();

                  final building =
                      (data['buildingAbbrev'] ?? '').toString().trim();
                  final room = (data['roomNumber'] ?? '').toString().trim();
                  final startTime = (data['startTime'] ?? '').toString();
                  final endTime = (data['endTime'] ?? '').toString();
                  final seats = data['seatCapacity'];
                  final amenities = List<String>.from(data['amenities'] ?? []);
                  final isAvailableNow = _isCurrentlyAvailable(
                    startTime,
                    endTime,
                  );

                  final cleanRoom =
                      room.toLowerCase().startsWith('room ')
                          ? room.substring(5).trim()
                          : room;

                  final title =
                      building.isNotEmpty
                          ? '$building Room $cleanRoom'
                          : 'Room $cleanRoom';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F0FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAvailableNow)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Available Now',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (startTime.isNotEmpty && endTime.isNotEmpty)
                            Text(
                              '$startTime - $endTime',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (seats != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Seats: $seats',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          if (amenities.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                amenities.length > 3
                                    ? 'Amenities: ${amenities.take(3).join(', ')} +${amenities.length - 3} more'
                                    : 'Amenities: ${amenities.join(', ')}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ExpandedStudyHallScreen(
                                title: title,
                                buildingName:
                                    (data['buildingName'] ?? '').toString(),
                                startTime: startTime,
                                endTime: endTime,
                                seats:
                                    seats is int
                                        ? seats
                                        : int.tryParse('$seats'),
                                amenities: amenities,
                              ),
                        ),
                      );
                    },
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

// ----------
// NEW FROM GISELLE: CREATING THE OUTLET SHEET DISPLAYED ON MAP
class _ChargingSheetContent extends StatelessWidget {
  const _ChargingSheetContent({
    required this.selectedBuildingFilter,
    required this.selectedExactBuilding,
    required this.onBuildingFilterChanged,
    required this.onOutletAdded,
  });

  final String selectedBuildingFilter;
  final String? selectedExactBuilding;
  final ValueChanged<String> onBuildingFilterChanged;
  final Future<void> Function() onOutletAdded;

  bool _matchesBuildingFilter(String buildingAbbrev) {
    if (selectedBuildingFilter == 'All') return true;

    final code = buildingAbbrev.trim().toUpperCase();

    switch (selectedBuildingFilter) {
      case 'LA':
        return code.startsWith('LA');
      case 'ENGR':
        return code.startsWith('EN') || code.startsWith('ENGR');
      case 'FA':
        return code.startsWith('FA');
      case 'HSCI':
        return code == 'HSCI' || code.contains('SCI');
      case 'PSY':
        return code == 'PSY' || code.startsWith('PSY');
      case 'HHS':
        return code.startsWith('HHS');
      case 'COB':
        return code == 'COB';
      case 'KIN':
        return code == 'KIN';
      default:
        return code == selectedBuildingFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildingFilters = [
      'All',
      'COB',
      'KIN',
      'LA',
      'HSCI',
      'ENGR',
      'FA',
      'PSY',
      'HHS',
    ];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('outlets')
              .where('status', isEqualTo: 'approved')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Could not load outlets: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredDocs =
            docs.where((doc) {
              final data = doc.data();
              final building = (data['buildingAbbrev'] ?? '').toString().trim();

              if (selectedExactBuilding != null &&
                  selectedExactBuilding!.isNotEmpty) {
                return building.toUpperCase() ==
                    selectedExactBuilding!.toUpperCase();
              }

              return _matchesBuildingFilter(building);
            }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 0, bottom: 5),
              child: Text(
                "Outlets in Classrooms ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 6),

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: buildingFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = buildingFilters[index];
                  final isSelected =
                      selectedExactBuilding == null &&
                      selectedBuildingFilter == filter;

                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => onBuildingFilterChanged(filter),
                    selectedColor: const Color(0xFFF2D21B),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            if (selectedExactBuilding != null &&
                selectedExactBuilding!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Text(
                  'Showing: ${selectedExactBuilding!}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4B3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 22),
              ),
              title: const Text(
                'Add Outlet Details',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddOutletScreen(),
                  ),
                );

                if (result == true) {
                  await onOutletAdded();
                }
              },
            ),

            Divider(color: Colors.grey.shade300, height: 20),

            if (filteredDocs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Text(
                  selectedExactBuilding != null &&
                          selectedExactBuilding!.isNotEmpty
                      ? 'No outlet entries found for ${selectedExactBuilding!}.'
                      : selectedBuildingFilter == 'All'
                      ? 'No outlet details added yet.'
                      : 'No outlet entries found for $selectedBuildingFilter.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),

            if (filteredDocs.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                itemCount: filteredDocs.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(color: Colors.grey.shade200, height: 1),
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data();

                  final building =
                      (data['buildingAbbrev'] ?? '').toString().trim();
                  final room = (data['roomNumber'] ?? '').toString().trim();
                  final outletCount = data['outletCount'];
                  final outletTypes = List<String>.from(
                    data['outletTypes'] ?? [],
                  );
                  final accessibilityLevels = List<String>.from(
                    data['accessibilityLevels'] ?? [],
                  );

                  final cleanRoom =
                      room.toLowerCase().startsWith('room ')
                          ? room.substring(5).trim()
                          : room;

                  final title =
                      building.isNotEmpty
                          ? '$building Room $cleanRoom ⚡'
                          : 'Room $cleanRoom ⚡';

                  String subtitle = '';
                  if (outletCount != null) {
                    subtitle = 'Number of Outlets: $outletCount';
                  }

                  if (outletTypes.isNotEmpty) {
                    subtitle =
                        subtitle.isEmpty
                            ? 'Type: ${outletTypes.join(', ')}'
                            : '$subtitle\nType: ${outletTypes.join(', ')}';
                  }

                  if (accessibilityLevels.isNotEmpty) {
                    subtitle =
                        subtitle.isEmpty
                            ? 'Accessibility: ${accessibilityLevels.join(', ')}'
                            : '$subtitle\nAccessibility: ${accessibilityLevels.join(', ')}';
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF4B3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.electric_bolt,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ExpandedOutletScreen(
                                title:
                                    building.isNotEmpty
                                        ? '$building Room $cleanRoom'
                                        : 'Room $cleanRoom',
                                buildingName:
                                    (data['buildingName'] ?? '').toString(),
                                outletCount:
                                    outletCount is int
                                        ? outletCount
                                        : int.tryParse('$outletCount'),
                                outletTypes: outletTypes,
                                accessibilityLevels: accessibilityLevels,
                              ),
                        ),
                      );
                    },
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _RestroomSheetContent extends StatefulWidget {
  final Position currentPosition;
  const _RestroomSheetContent({super.key, required this.currentPosition});
  @override
  State<_RestroomSheetContent> createState() => _RestroomSheetContentState();
}

class _RestroomSheetContentState extends State<_RestroomSheetContent> {
  List<Map<String, dynamic>> _dynamicList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  double _getDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)) * 3280.84;
  }

  Future<void> _loadList() async {
    try {
      final String geoJsonString = await rootBundle.loadString(
        'assets/csulb.geojson',
      );
      final Map<String, dynamic> geoJson = json.decode(geoJsonString);
      final List features = geoJson['features'] ?? [];

      List<Map<String, dynamic>> results = [];
      for (var feature in features) {
        final props = feature['properties'] ?? {};
        final geom = feature['geometry'] ?? {};
        if (props['feature_type'] != 'building') continue;

        double lat = 0.0, lng = 0.0;
        final type = geom['type'];
        final coords = geom['coordinates'];

        try {
          if (type == 'Point') {
            lng = (coords[0] as num).toDouble();
            lat = (coords[1] as num).toDouble();
          } else if (type == 'Polygon') {
            lng = (coords[0][0][0] as num).toDouble();
            lat = (coords[0][0][1] as num).toDouble();
          } else if (type == 'MultiPolygon') {
            lng = (coords[0][0][0][0] as num).toDouble();
            lat = (coords[0][0][0][1] as num).toDouble();
          }
        } catch (e) {
          continue;
        }

        if (lat == 0.0) continue;

        double dist = _getDistance(
          widget.currentPosition.lat.toDouble(),
          widget.currentPosition.lng.toDouble(),
          lat,
          lng,
        );
        results.add({
          'name': props['name'],
          'abbrev': props['abbrev'],
          'distVal': dist,
          'distStr':
              dist < 1000
                  ? "${dist.toStringAsFixed(0)} ft"
                  : "${(dist / 5280).toStringAsFixed(1)} mi",
          'details': 'Loading stats',
        });
      }

      results.sort((a, b) => a['distVal'].compareTo(b['distVal']));
      var top5 = results.take(5).toList();

      if (mounted)
        setState(() {
          _dynamicList = top5;
          _isLoading = false;
        });

      for (var b in top5) {
        String id = b['abbrev'] != 'None' ? b['abbrev'] : b['name'];
        final snap =
            await FirebaseFirestore.instance
                .collection('bathroom_reviews')
                .where('bathroomName', isGreaterThanOrEqualTo: id)
                .where('bathroomName', isLessThanOrEqualTo: '$id\uf8ff')
                .get();

        if (snap.docs.isNotEmpty) {
          Map<String, int> counts = {};
          for (var doc in snap.docs) {
            Map<String, dynamic> fts = doc.data()['features'] ?? {};
            fts.forEach((k, v) {
              if (v == true) counts[k] = (counts[k] ?? 0) + 1;
            });
          }
          if (counts.isNotEmpty && mounted) {
            setState(() {
              b['details'] =
                  counts.entries
                      .reduce((a, b) => a.value > b.value ? a : b)
                      .key;
            });
          } else if (mounted) {
            setState(() {
              b['details'] = "Functional";
            });
          }
        } else if (mounted) {
          setState(() {
            b['details'] = "No reviews yet";
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 0, bottom: 5),
          child: Text(
            "Nearby Restrooms",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!_isLoading)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 5, bottom: 20),
            itemCount: _dynamicList.length,
            separatorBuilder:
                (context, index) =>
                    Divider(color: Colors.grey.shade200, height: 1),
            itemBuilder: (context, index) {
              final b = _dynamicList[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 2,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F0FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wc,
                    color: Colors.blueAccent,
                    size: 22,
                  ),
                ),
                title: Text(
                  b["name"]!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  "${b["distStr"]} - ${b["details"]}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BathroomFinder(),
                      ),
                    ),
              );
            },
          ),
      ],
    );
  }
}

class _SheetPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SheetPlaceholder({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _BathroomClickListener extends OnPointAnnotationClickListener {
  final BuildContext context;
  _BathroomClickListener(this.context);
  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BathroomFinder()),
    );
  }
}

// NEW FROM GISELLE: STUDY HALL
class _StudyHallClickListener extends OnPointAnnotationClickListener {
  final void Function(Map<String, dynamic>) onTap;
  final Map<String, Map<String, dynamic>> pinData;

  _StudyHallClickListener(this.onTap, this.pinData);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    final data = pinData[annotation.id];
    if (data == null) return;
    onTap(data);
  }
}

// NEW FROM GISELLE: OUTLET
class _OutletClickListener extends OnPointAnnotationClickListener {
  final void Function(Map<String, dynamic>) onTap;
  final Map<String, Map<String, dynamic>> pinData;

  _OutletClickListener(this.onTap, this.pinData);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    final data = pinData[annotation.id];
    if (data == null) return;
    onTap(data);
  }
}

class _FoodAlertMapPinClickListener extends OnPointAnnotationClickListener {
  final void Function(Map<String, dynamic>) onTap;
  final Map<String, Map<String, dynamic>> pinData;
 
  _FoodAlertMapPinClickListener(this.onTap, this.pinData);
 
  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    final data = pinData[annotation.id];
    if (data == null) return;
    onTap(data);
  }
}