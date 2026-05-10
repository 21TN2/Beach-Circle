import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:async';
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
import '../map_features/expanded_bathroom_finder_screen.dart';

//New packages from old map screen
import 'package:beach_circle_flutter/community_goods/smf/service/moderation_service.dart';
import 'package:http/http.dart' as http;
import 'package:beach_circle_flutter/mapbox.dart';
import 'package:beach_circle_flutter/community_goods/smf/model/csulb_buildings.dart';

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
  bool _isAddingPersonalPin = false;
  Position? _simulatedPosition;

  String? _activeFilter;
  String _selectedStudyBuildingFilter = 'All';
  String? _selectedExactStudyBuilding;

  String _selectedOutletBuildingFilter = 'All';
  String? _selectedExactOutletBuilding;

  String _selectedParkingZoneFilter = 'All';
  String? _reportingLotName;

  PolygonAnnotationManager? _parkingLotManager;
  PointAnnotationManager? _parkingLabelManager;
  final Map<String, List<Position>> _parkingGeometries = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _parkingStreamSubscription;
  final Map<String, String> _polygonIdToLotName = {};
  final Map<String, String> _labelIdToLotName = {};

  //============NEW FOR ROUTE OPTIONS===================
  //Building Coordinates
  PolylineAnnotationManager? polylineAnnotationManager;
  PolylineAnnotation? currentRouteAnnotation;
  Building? startBuilding;
  Building? endBuilding;
  String? startCategory;
  String? endCategory;

  //Creates circle pins on the map
  CircleAnnotationManager? circleAnnotationManager;
  CircleAnnotationManager? _routeTrailManager;
  PointAnnotationManager? _routeMarkerManager;
  //Pins Id for the firebase
  final Map<String, String> _annotationToDocId = {};

  bool _ignoreNextMapTap = false;

  //Show or hide route panel
  bool _showRoutePanel = false;

  Future<Uint8List> _createRouteMarker({
    required String label,
    required Color color,
  }) async {
    const double width = 170;
    const double height = 140;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    final Paint pinPaint = Paint()..color = color;
    final Paint whitePaint = Paint()..color = Colors.white;

    canvas.drawCircle(const Offset(85, 48), 32, shadowPaint);

    canvas.drawCircle(const Offset(85, 44), 32, pinPaint);
    canvas.drawCircle(const Offset(85, 44), 11, whitePaint);

    final Path triangle = Path()
      ..moveTo(67, 72)
      ..lineTo(103, 72)
      ..lineTo(85, 108)
      ..close();
    canvas.drawPath(triangle, pinPaint);

    final RRect labelBox = RRect.fromRectAndRadius(
      const Rect.fromLTWH(35, 92, 100, 38),
      const Radius.circular(18),
    );

    canvas.drawRRect(labelBox, pinPaint);

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(85 - textPainter.width / 2, 111 - textPainter.height / 2),
    );

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  //ROUTE OPTIONS BUILDING CATEGORIES
  List<String> get buildingCategories {
    final categories = csulbBuildings.map((b) => b.category).toSet().toList();
    categories.sort();
    return categories;
  }

  List<Building> get startCategoryBuildings {
    if (startCategory == null) return [];
    return csulbBuildings.where((b) => b.category == startCategory).toList();
  }

  List<Building> get endCategoryBuildings {
    if (endCategory == null) return [];
    return csulbBuildings.where((b) => b.category == endCategory).toList();
  }

  //Clear route selections and map line
  Future<void> _clearRoute() async {
    setState(() {
      startBuilding = null;
      endBuilding = null;
      startCategory = null;
      endCategory = null;
      _showRoutePanel = false;
    });

    //Remove route line from map
    if (polylineAnnotationManager != null) {
      await polylineAnnotationManager!.deleteAll();
      currentRouteAnnotation = null;
    }
    await _routeTrailManager?.deleteAll();
    await _routeMarkerManager?.deleteAll();
  }

  List<Position> _createTrailDots(List<Position> routePoints) {
    final List<Position> dots = [];

    for (int i = 0; i < routePoints.length - 1; i++) {
      final start = routePoints[i];
      final end = routePoints[i + 1];

      const int dotsPerSegment = 6;

      for (int j = 1; j < dotsPerSegment; j += 2) {
        final double t = j / dotsPerSegment;

        final double lng = start.lng + ((end.lng - start.lng) * t);
        final double lat = start.lat + ((end.lat - start.lat) * t);

        dots.add(Position(lng, lat));
      }
    }

    return dots;
  }

  //Building Selection
  Future<void> _getRoute() async {
    if (startBuilding == null || endBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both buildings.')),
      );
      return;
    }

    if (polylineAnnotationManager == null || mapboxMap == null) return;

    try {
      await polylineAnnotationManager!.deleteAll();
      currentRouteAnnotation = null;

      final url =
          'https://api.mapbox.com/directions/v5/mapbox/walking/'
          '${startBuilding!.lng},${startBuilding!.lat};'
          '${endBuilding!.lng},${endBuilding!.lat}'
          '?geometries=geojson&access_token=$mapboxAccessToken';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get route: ${response.statusCode}'),
          ),
        );
        return;
      }

      final data = jsonDecode(response.body);
      final routes = data['routes'];

      if (routes == null || routes.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No route found.')));
        return;
      }

      final coordinates = routes[0]['geometry']['coordinates'] as List;

      final List<Position> routePoints = coordinates.map((point) {
        return Position(
          (point[0] as num).toDouble(),
          (point[1] as num).toDouble(),
        );
      }).toList();

      // Clear old route drawings
      await polylineAnnotationManager!.deleteAll();
      await _routeMarkerManager?.deleteAll();
      await _routeTrailManager?.deleteAll();

      // Shadow
      await polylineAnnotationManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePoints),
          lineColor: Colors.black.withValues(alpha: 0.24).toARGB32(),
          lineWidth: 16.0,
        ),
      );

      // White outline
      await polylineAnnotationManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePoints),
          lineColor: Colors.white.toARGB32(),
          lineWidth: 13.0,
        ),
      );

      // Main blue route
      currentRouteAnnotation = await polylineAnnotationManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePoints),
          lineColor: const Color(0xFF1A73E8).toARGB32(),
          lineWidth: 9.0,
        ),
      );

      // Recreate trail manager AFTER route line so dots sit on top
      _routeTrailManager = await mapboxMap!.annotations
          .createCircleAnnotationManager();

      // Recreate marker manager AFTER route line and trail so START/END sit on top
      _routeMarkerManager = await mapboxMap!.annotations
          .createPointAnnotationManager();

      final Position startPoint = routePoints.first;
      final Position endPoint = routePoints.last;

      final startMarker = await _createRouteMarker(
        label: 'START',
        color: const Color(0xFF1E9E59),
      );

      final endMarker = await _createRouteMarker(
        label: 'END',
        color: const Color(0xFFD93025),
      );

      await _routeMarkerManager?.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: startPoint),
          image: startMarker,
          iconSize: 1.35,
          iconOffset: [0.0, -25.0],
        ),
      );

      await _routeMarkerManager?.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: endPoint),
          image: endMarker,
          iconSize: 1.35,
          iconOffset: [0.0, -25.0],
        ),
      );

      setState(() {
        _showRoutePanel = false;
      });

      await mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(startBuilding!.lng, startBuilding!.lat),
          ),
          zoom: 16.0,
        ),
        MapAnimationOptions(duration: 1200),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting route: $e')));
    }
  }

  //=========================LOCATION PINS========================
  //Load pins to the map
  Future<void> _refreshPinsFromFirebase() async {
    if (circleAnnotationManager == null) return;

    await circleAnnotationManager!.deleteAll();
    _annotationToDocId.clear();

    final snapshot = await FirebaseFirestore.instance.collection('pins').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final latRaw = data['lat'];
      final lngRaw = data['lng'];
      final colorRaw = data['color'];

      if (latRaw == null || lngRaw == null) continue;

      final double lat = (latRaw as num).toDouble();
      final double lng = (lngRaw as num).toDouble();
      final String colorName = (colorRaw ?? 'blue').toString();

      //Draws blue circle as a pin
      final annotation = await circleAnnotationManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          circleRadius: 8.0,
          circleColor: _getPinColor(colorName),
          circleStrokeWidth: 2.0,
          circleStrokeColor: Colors.white.value,
        ),
      );

      _annotationToDocId[annotation.id] = doc.id;
    }
  }

  //Edit existing pin
  Future<void> _showEditPinDialog({
    required String docId,
    required String currentLabel,
    required String currentDescription,
    required String currentColor,
  }) async {
    final TextEditingController labelController = TextEditingController(
      text: currentLabel,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: currentDescription,
    );

    String selectedColor = currentColor;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit pin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Label'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        hintText: 'Example: Fav study spot',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text('Description'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Example: Quiet, good views, near outlets',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text('Choose pin color'),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: selectedColor,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'blue', child: Text('Blue')),
                        DropdownMenuItem(value: 'red', child: Text('Red')),
                        DropdownMenuItem(value: 'green', child: Text('Green')),
                        DropdownMenuItem(
                          value: 'purple',
                          child: Text('Purple'),
                        ),
                        DropdownMenuItem(
                          value: 'orange',
                          child: Text('Orange'),
                        ),
                        DropdownMenuItem(
                          value: 'yellow',
                          child: Text('Yellow'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedColor = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) return;

    final String updatedLabel = labelController.text.trim();
    final String updatedDescription = descriptionController.text.trim();

    //Moderation for edited content
    if (ModerationService.containsBlockedContent(updatedLabel) ||
        ModerationService.containsBlockedContent(updatedDescription)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inappropriate language is not allowed.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('pins').doc(docId).update({
      'label': updatedLabel,
      'description': updatedDescription,
      'color': selectedColor,
    });

    await _refreshPinsFromFirebase();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pin updated')));
  }

  // User input for creating a personal location pin
  Future<void> _showAddUserPinDialog(
    MapContentGestureContext tapContext,
  ) async {
    final double lat = tapContext.point.coordinates.lat.toDouble();
    final double lng = tapContext.point.coordinates.lng.toDouble();

    // Default Color Pin
    String selectedColor = 'blue';

    // User input for pin details
    final TextEditingController labelController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    // Ask users if they want to pin location
    final shouldPin = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pin this location?'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Do you want to pin this spot?'),
                    const SizedBox(height: 12),

                    const Text('Label'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        hintText: 'Example: Fav study spot',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text('Description'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Example: Quiet, good views, near outlets',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text('Choose pin color'),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: selectedColor,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'blue', child: Text('Blue')),
                        DropdownMenuItem(value: 'red', child: Text('Red')),
                        DropdownMenuItem(value: 'green', child: Text('Green')),
                        DropdownMenuItem(
                          value: 'purple',
                          child: Text('Purple'),
                        ),
                        DropdownMenuItem(
                          value: 'orange',
                          child: Text('Orange'),
                        ),
                        DropdownMenuItem(
                          value: 'yellow',
                          child: Text('Yellow'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedColor = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldPin != true) return;
    if (circleAnnotationManager == null) return;

    final String label = labelController.text.trim();
    final String description = descriptionController.text.trim();

    // Checks for inappropriate content
    if (ModerationService.containsBlockedContent(label) ||
        ModerationService.containsBlockedContent(description)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inappropriate language is not allowed.')),
      );
      return;
    }

    CircleAnnotation? annotation;

    try {
      // Pin shown immediately
      annotation = await circleAnnotationManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          circleRadius: 8.0,
          circleColor: _getPinColor(selectedColor),
          circleStrokeWidth: 2.0,
          circleStrokeColor: Colors.white.value,
        ),
      );

      // Save pin in firebase
      final docRef = await FirebaseFirestore.instance.collection('pins').add({
        'lat': lat,
        'lng': lng,
        'color': selectedColor,
        'label': label,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _annotationToDocId[annotation.id] = docRef.id;

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pin saved')));
    } catch (e) {
      if (annotation != null) {
        await circleAnnotationManager!.delete(annotation);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save pin: $e')));
    }
  }

  //Pin Colors
  int _getPinColor(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red.value;
      case 'green':
        return Colors.green.value;
      case 'purple':
        return Colors.purple.value;
      case 'orange':
        return Colors.orange.value;
      case 'yellow':
        return Colors.yellow.value;
      case 'blue':
      default:
        return Colors.blue.value;
    }
  }

  // --- NEW: LIFTED PARKING STATE ---
  // This holds the live data so both Firebase AND the Demo can update the bottom sheet!
  Map<String, Map<String, dynamic>> _liveParkingData = {};

  // DEMO STATE
  Timer? _demoTimer;
  final Map<String, int> _demoLotCounts = {};

  PointAnnotationManager? _studyHallPinManager;
  final Map<String, Map<String, dynamic>> _studyHallPinData = {};

  PointAnnotationManager? _outletPinManager;
  final Map<String, Map<String, dynamic>> _outletPinData = {};

  // NEW FROM GISELLE REVIEW 4: Keeps bathroom building data in the same order as bathroom pin options
  final List<Map<String, dynamic>> _bathroomBuildingData = [];

  // NEW FROM GISELLE REVIEW 4: Connects each created bathroom pin id to its building data
  final Map<String, Map<String, dynamic>> _bathroomPinData = {};

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

  // filter req
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

  void _handleParkingLotTap(String lotName) {
    setState(() {
      _activeFilter = 'parking';
      _reportingLotName = lotName;
    });
  }

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
    ),
    FilterOption(
      key: 'food',
      icon: Icons.local_pizza,
      label: 'Food',
      hasBottomSheet: true,
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

  final List<PointAnnotationOptions> _bathroomPinOptions = [];

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
  }

  @override
  void dispose() {
    _parkingStreamSubscription?.cancel();
    _demoTimer?.cancel();
    super.dispose();
  }

  // --- DRAW THE 5-PERSON RATING MARKER ---
  Future<Uint8List> _createOccupancyMarker(double occupancy) async {
    const double width = 110;
    const double height = 36;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Paint bgPaint = Paint()..color = Colors.white;
    final RRect rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(18),
    );

    canvas.drawShadow(Path()..addRRect(rrect), Colors.black, 4, true);
    canvas.drawRRect(rrect, bgPaint);

    int filledCount = (occupancy * 5).round();

    for (int i = 0; i < 5; i++) {
      bool isFilled = i < filledCount;
      Color iconColor = isFilled ? Colors.black87 : Colors.grey.shade300;

      final TextPainter iconPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(Icons.person.codePoint),
          style: TextStyle(
            fontSize: 18,
            fontFamily: Icons.person.fontFamily,
            package: Icons.person.fontPackage,
            color: iconColor,
          ),
        ),
      );
      iconPainter.layout();
      double startX = 10.0 + (i * 18.0);
      iconPainter.paint(canvas, Offset(startX, 9));
    }

    final ui.Image image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
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

  Future<Uint8List> _createCountMarker({
    required IconData icon,
    required Color circleColor,
    required String badgeText,
    required Color badgeColor,
  }) async {
    const double width = 118;
    const double height = 118;
    const double circleRadius = 36;
    const Offset circleCenter = Offset(59, 64);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.20)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);

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
          fontSize: 42,
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

    final double badgeWidth = badgeText.length >= 3 ? 68 : 50;
    final Rect badgeRect = Rect.fromLTWH(16, 4, badgeWidth, 36);
    final RRect badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      const Radius.circular(15),
    );

    final Paint badgePaint = Paint()..color = badgeColor;
    canvas.drawRRect(badgeRRect, badgePaint);

    final Paint badgeBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(badgeRRect, badgeBorderPaint);

    final TextPainter badgePainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
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

  Future<void> _loadStudyHallPins() async {
    try {
      if (_studyHallPinManager == null) return;

      await _studyHallPinManager!.deleteAll();
      _studyHallPinData.clear();

      final snapshot = await FirebaseFirestore.instance
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
            iconSize: 1.08,
          ),
        );

        if (annotation != null) {
          _studyHallPinData[annotation.id] = {
            'buildingAbbrev': buildingData['buildingAbbrev'],
            'buildingName': buildingData['buildingName'],
          };
        }
      }
    } catch (e) {
      debugPrint('Error loading study hall pins: $e');
    }
  }

  Future<void> _loadOutletPins() async {
    try {
      if (_outletPinManager == null) return;

      await _outletPinManager!.deleteAll();
      _outletPinData.clear();

      final snapshot = await FirebaseFirestore.instance
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
            iconSize: 1.08,
          ),
        );

        if (annotation != null) {
          _outletPinData[annotation.id] = {
            'buildingAbbrev': buildingData['buildingAbbrev'],
            'buildingName': buildingData['buildingName'],
          };
        }
      }
    } catch (e) {
      debugPrint('Error loading outlet pins: $e');
    }
  }

  Future<void> _loadBuildingBathrooms() async {
    try {
      final String geoJsonString = await rootBundle.loadString(
        'assets/csulb.geojson',
      );
      final Map<String, dynamic> geoJson = json.decode(geoJsonString);
      final List features = geoJson['features'] ?? [];
      final Uint8List customIconBytes = await _createWcMarker();

      _bathroomPinOptions.clear();
      _bathroomBuildingData.clear();
      _bathroomPinData.clear();

      for (var feature in features) {
        final properties = feature['properties'] ?? {};
        final geometry = feature['geometry'] ?? {};
        final name = (properties['name'] ?? '').toString();
        final abbrev = (properties['abbrev'] ?? '').toString();
        final featureType = (properties['feature_type'] ?? '').toString();

        final isBathroomBuilding =
            featureType == 'building' || abbrev.toUpperCase() == 'VEC';

        if (isBathroomBuilding) {
          final type = geometry['type'];
          final coords = geometry['coordinates'];

          double lat = 0.0;
          double lng = 0.0;

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
                iconSize: 1.20,
              ),
            );

            _bathroomBuildingData.add({
              'name': name,
              'abbrev': abbrev,
              'lat': lat,
              'lng': lng,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading buildings: $e");
    }
  }

  double _getDistanceFeet(double lat1, double lon1, double lat2, double lon2) {
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

  String _formatDistance(double dist) {
    return dist < 1000
        ? "${dist.toStringAsFixed(0)} ft"
        : "${(dist / 5280).toStringAsFixed(1)} mi";
  }

  void _handleBathroomPinTap(Map<String, dynamic> data) {
    final bathroomName = (data['name'] ?? '').toString();
    final buildingAbbrev = (data['abbrev'] ?? '').toString();

    final bathroomLat = (data['lat'] as num?)?.toDouble();
    final bathroomLng = (data['lng'] as num?)?.toDouble();

    final Position locationToUse = (_isDevMode && _simulatedPosition != null)
        ? _simulatedPosition!
        : Position(_centerLng, _centerLat);

    String distance = '';

    if (bathroomLat != null && bathroomLng != null) {
      final dist = _getDistanceFeet(
        locationToUse.lat.toDouble(),
        locationToUse.lng.toDouble(),
        bathroomLat,
        bathroomLng,
      );

      distance = _formatDistance(dist);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpandedBathroomFinderPage(
          bathroomName: bathroomName,
          buildingAbbrev: buildingAbbrev,
          distance: distance,
          details: '',
        ),
      ),
    );
  }

  Future<void> _loadBathroomPins() async {
    if (pointAnnotationManager == null) return;

    _bathroomPinData.clear();

    for (int i = 0; i < _bathroomPinOptions.length; i++) {
      final annotation = await pointAnnotationManager!.create(
        _bathroomPinOptions[i],
      );

      if (i < _bathroomBuildingData.length) {
        _bathroomPinData[annotation.id] = _bathroomBuildingData[i];
      }
    }
  }

  // --- PARKING GEOJSON PARSING ---
  Future<void> _loadParkingLotGeometries() async {
    try {
      final String geoJsonString = await rootBundle.loadString(
        'assets/csulb.geojson',
      );
      final Map<String, dynamic> geoJson = json.decode(geoJsonString);
      final List features = geoJson['features'] ?? [];

      _parkingGeometries.clear();

      for (var feature in features) {
        final properties = feature['properties'] ?? {};
        final geometry = feature['geometry'] ?? {};

        final featureType = (properties['feature_type'] ?? '').toString();
        final lotName = (properties['name'] ?? 'Unnamed Lot').toString().trim();

        if (featureType == 'parking' ||
            lotName.toUpperCase().contains('LOT ') ||
            lotName.toUpperCase().contains('PARKING')) {
          final type = geometry['type'];
          final coords = geometry['coordinates'];

          List<Position> positions = [];

          try {
            if (type == 'Polygon') {
              for (var point in coords[0]) {
                positions.add(
                  Position(
                    (point[0] as num).toDouble(),
                    (point[1] as num).toDouble(),
                  ),
                );
              }
            } else if (type == 'MultiPolygon') {
              for (var point in coords[0][0]) {
                positions.add(
                  Position(
                    (point[0] as num).toDouble(),
                    (point[1] as num).toDouble(),
                  ),
                );
              }
            }
          } catch (e) {
            continue;
          }

          if (positions.isNotEmpty && lotName.isNotEmpty) {
            _parkingGeometries[lotName] = positions;
          }
        }
      }
    } catch (e) {
      debugPrint("Error parsing parking geometries: $e");
    }
  }

  // --- DRAW PARKING POLYGONS AND MARKERS ---
  Future<void> _drawParkingPolygons([
    Map<String, int> counts = const {},
  ]) async {
    if (_parkingLotManager == null) return;
    await _parkingLotManager!.deleteAll();
    if (_parkingLabelManager != null) await _parkingLabelManager!.deleteAll();

    _polygonIdToLotName.clear();
    _labelIdToLotName.clear();

    List<PolygonAnnotationOptions> polygonOptions = [];
    List<PointAnnotationOptions> labelOptions = [];
    List<String> lotNamesList = [];

    for (final name in _parkingGeometries.keys) {
      int searchingCount = counts[name] ?? 0;

      double occupancy =
          searchingCount / 20.0; // Assume 20 is max for the UI scale
      if (occupancy > 1.0) occupancy = 1.0;

      int colorValue = Colors.green.toARGB32();
      if (occupancy >= 0.75) {
        colorValue = Colors.red.toARGB32();
      } else if (occupancy >= 0.25) {
        colorValue = Colors.orange.toARGB32();
      }

      polygonOptions.add(
        PolygonAnnotationOptions(
          geometry: Polygon(coordinates: [_parkingGeometries[name]!]),
          fillColor: colorValue,
          fillOpacity: 0.5,
          fillOutlineColor: Colors.black.toARGB32(),
        ),
      );
      lotNamesList.add(name);

      double sumX = 0;
      double sumY = 0;
      for (var pos in _parkingGeometries[name]!) {
        sumX += pos.lng;
        sumY += pos.lat;
      }
      double centerX = sumX / _parkingGeometries[name]!.length;
      double centerY = sumY / _parkingGeometries[name]!.length;

      final markerBytes = await _createOccupancyMarker(occupancy);
      labelOptions.add(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(centerX, centerY)),
          image: markerBytes,
          iconSize: 1.0,
        ),
      );
    }

    if (polygonOptions.isNotEmpty) {
      final annotations = await _parkingLotManager!.createMulti(polygonOptions);
      for (int i = 0; i < annotations.length; i++) {
        if (annotations[i] != null) {
          _polygonIdToLotName[annotations[i]!.id] = lotNamesList[i];
        }
      }
    }

    if (labelOptions.isNotEmpty && _parkingLabelManager != null) {
      final labelAnnotations = await _parkingLabelManager!.createMulti(
        labelOptions,
      );
      for (int i = 0; i < labelAnnotations.length; i++) {
        if (labelAnnotations[i] != null) {
          _labelIdToLotName[labelAnnotations[i]!.id] = lotNamesList[i];
        }
      }
    }
  }

  // --- LISTEN TO FIREBASE ---
  void _listenToParkingFirebase() {
    _parkingStreamSubscription?.cancel();
    _parkingStreamSubscription = FirebaseFirestore.instance
        .collection('parking_lots')
        .snapshots()
        .listen((snapshot) {
          final Map<String, int> liveCounts = {};
          final Map<String, Map<String, dynamic>> fullData = {};

          for (var doc in snapshot.docs) {
            final name = (doc.data()['name'] ?? '').toString();
            final count = doc.data()['searching_count'] ?? 0;
            liveCounts[name] = count;
            fullData[name] = doc.data();
          }

          // Update central state so bottom sheet can re-render instantly
          if (mounted) {
            setState(() {
              _liveParkingData = fullData;
            });
          }
          _drawParkingPolygons(liveCounts);
        });

    _drawParkingPolygons();
  }

  // --- REFINED DEMO SIMULATION LOGIC ---
  void _runParkingDemo() async {
    _demoTimer?.cancel();
    _parkingStreamSubscription?.cancel(); // Stop firebase from overwriting demo
    int tick = 0;

    setState(() {
      _activeFilter = 'parking';
      _selectedParkingZoneFilter = 'G Lots';
      _reportingLotName = null;
      _demoLotCounts.clear();
      // Inject fake empty data for the menu to read
      _liveParkingData['Lot G3'] = {'searching_count': 0, 'parked_count': 0};
    });

    double lotCenterX = -118.1135;
    double lotCenterY = 33.7840;

    final lotG3Coords = _parkingGeometries['Lot G3'];
    if (lotG3Coords != null && lotG3Coords.isNotEmpty) {
      double sumX = 0;
      double sumY = 0;
      for (var pos in lotG3Coords) {
        sumX += pos.lng;
        sumY += pos.lat;
      }
      lotCenterX = sumX / lotG3Coords.length;
      lotCenterY = sumY / lotG3Coords.length;
    }

    mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lotCenterX, lotCenterY)),
        zoom: 17.5,
      ),
      MapAnimationOptions(duration: 1000),
    );

    _demoTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      tick++;

      setState(() {
        _demoLotCounts['Lot G3'] = math.min(tick, 20);
        // Feed fake live data into the bottom sheet state
        _liveParkingData['Lot G3'] = {
          'searching_count': math.min(tick, 20),
          'parked_count': tick > 5 ? (tick - 5) : 0,
        };
      });

      _drawParkingPolygons(_demoLotCounts);

      if (_devPinManager != null) {
        await _devPinManager!.deleteAll();

        for (int i = 0; i < math.min(tick, 20); i++) {
          double offsetX = math.sin(i * 1.5) * 0.00025;
          double offsetY = math.cos(i * 1.5) * 0.00025;
          double progress = math.min((tick - i) / 3.0, 1.0);

          double startX = lotCenterX - 0.0008;
          double startY = lotCenterY - 0.0008;
          double endX = lotCenterX + offsetX;
          double endY = lotCenterY + offsetY;

          double currentX = startX + (endX - startX) * progress;
          double currentY = startY + (endY - startY) * progress;

          await _devPinManager!.create(
            PointAnnotationOptions(
              geometry: Point(coordinates: Position(currentX, currentY)),
              textField: progress >= 1.0
                  ? "Car ${i + 1} (Parked)"
                  : "Car ${i + 1}",
              textColor: progress >= 1.0
                  ? Colors.green.toARGB32()
                  : Colors.blueAccent.toARGB32(),
              textHaloColor: Colors.white.toARGB32(),
              textHaloWidth: 2.0,
            ),
          );
        }
      }

      if (tick >= 20) {
        timer.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("20s Demo Complete: Lot G3 has reached capacity."),
          ),
        );
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            _devPinManager?.deleteAll();
            setState(() {
              _demoLotCounts.clear();
            });
            _listenToParkingFirebase(); // Restart live sync
          }
        });
      }
    });
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

    pointAnnotationManager = await mapboxMap!.annotations
        .createPointAnnotationManager();
    pointAnnotationManager?.addOnPointAnnotationClickListener(
      _BathroomClickListener(_handleBathroomPinTap, _bathroomPinData),
    );

    // User pins(Circle pins)
    circleAnnotationManager = await mapboxMap!.annotations
        .createCircleAnnotationManager();
    _routeMarkerManager = await mapboxMap!.annotations
        .createPointAnnotationManager();
    _routeTrailManager = await mapboxMap!.annotations
        .createCircleAnnotationManager();
    // If user wants to edit or delete existing pins
    circleAnnotationManager!.addOnCircleAnnotationClickListener(
      _PinClickListener(
        onPinTapped: (annotation) async {
          _ignoreNextMapTap = true;

          // Gets pin's Id from firebase
          final docId = _annotationToDocId[annotation.id];
          if (docId == null) return;

          // Pin Details
          final pinDoc = await FirebaseFirestore.instance
              .collection('pins')
              .doc(docId)
              .get();

          final pinData = pinDoc.data() ?? {};
          final String label = (pinData['label'] ?? '').toString();
          final String description = (pinData['description'] ?? '').toString();
          final String color = (pinData['color'] ?? 'blue').toString();

          final action = await showDialog<String>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(label.isEmpty ? 'Pinned location' : label),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty) Text(description),
                    if (description.isNotEmpty) const SizedBox(height: 12),
                    Text('Color: $color'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'close'),
                    child: const Text('Close'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'edit'),
                    child: const Text('Edit'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, 'delete'),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );

          if (action == 'delete') {
            // Deletes pin from firebase
            await FirebaseFirestore.instance
                .collection('pins')
                .doc(docId)
                .delete();

            await _refreshPinsFromFirebase();

            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Pin deleted')));
            return;
          }

          if (action == 'edit') {
            await _showEditPinDialog(
              docId: docId,
              currentLabel: label,
              currentDescription: description,
              currentColor: color,
            );
          }
        },
      ),
    );

    // Route Options
    polylineAnnotationManager = await mapboxMap!.annotations
        .createPolylineAnnotationManager();

    _devPinManager = await mapboxMap!.annotations
        .createPointAnnotationManager();
    _devCircleManager = await mapboxMap!.annotations
        .createCircleAnnotationManager();
    _foodAlertPinManager = await mapboxMap!.annotations
        .createPointAnnotationManager();

    _foodAlertMapPinManager = await mapboxMap!.annotations
        .createPointAnnotationManager();
    _foodAlertMapPinManager?.addOnPointAnnotationClickListener(
      _FoodAlertMapPinClickListener(_handleFoodAlertPinTap, _foodAlertPinData),
    );

    _studyHallPinManager = await mapboxMap!.annotations
        .createPointAnnotationManager();
    _studyHallPinManager?.addOnPointAnnotationClickListener(
      _StudyHallClickListener(_handleStudyHallPinTap, _studyHallPinData),
    );

    _outletPinManager = await mapboxMap!.annotations
        .createPointAnnotationManager();
    _outletPinManager?.addOnPointAnnotationClickListener(
      _OutletClickListener(_handleOutletPinTap, _outletPinData),
    );

    _parkingLotManager = await mapboxMap!.annotations
        .createPolygonAnnotationManager();
    _parkingLabelManager = await mapboxMap!.annotations
        .createPointAnnotationManager();

    _foodAlertMarkerBytes = await _createFoodAlertMarker();

    await _loadBuildingBathrooms();

    await _loadParkingLotGeometries();

    // Load personal saved pins from Firebase
    await _refreshPinsFromFirebase();

    if (widget.initialFilter != null) {
      await Future.delayed(const Duration(milliseconds: 150));
    }

    await _updateMapPins();
  }

  void _onMapTapped(MapContentGestureContext context) async {
    if (_foodAlertStep == _FoodAlertStep.placingPin) {
      await _placeFoodAlertPin(context.point);
      return;
    }

    // Prevents users from pinning while route panel is open
    if (_showRoutePanel) return;

    if (_ignoreNextMapTap) {
      _ignoreNextMapTap = false;
      return;
    }

    if (_isDevMode) {
      _simulatedPosition = context.point.coordinates;

      if (_devPin != null) {
        await _devPinManager?.delete(_devPin!);
      }

      if (_devCircle != null) {
        await _devCircleManager?.delete(_devCircle!);
      }

      _devCircle = await _devCircleManager?.create(
        CircleAnnotationOptions(
          geometry: context.point,
          circleRadius: 9.0,
          circleColor: const Color(0xFF4285F4).toARGB32(),
          circleStrokeWidth: 3.0,
          circleStrokeColor: Colors.white.toARGB32(),
        ),
      );

      _devPin = await _devPinManager?.create(
        PointAnnotationOptions(
          geometry: context.point,
          textField: "You (Simulated)",
          textColor: Colors.black.toARGB32(),
          textHaloColor: Colors.white.toARGB32(),
          textHaloWidth: 2.0,
          textOffset: [0.0, 1.2],
        ),
      );

      setState(() {});
      return;
    }

    // Creates a personal location pin
    // Only create personal pins when pin mode is ON
    if (_isAddingPersonalPin) {
      await _showAddUserPinDialog(context);

      if (mounted) {
        setState(() {
          _isAddingPersonalPin = false;
        });
      }
    }
  }

  Future<void> _placeFoodAlertPin(Point point) async {
    if (_foodAlertPin != null) {
      await _foodAlertPinManager?.delete(_foodAlertPin!);
    }
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

  void _startFoodAlertFlow() {
    setState(() {
      _activeFilter = null;
      _foodAlertStep = _FoodAlertStep.placingPin;
      _foodAlertPinPosition = null;
    });
  }

  void _confirmFoodAlertPin() {
    if (_foodAlertPinPosition == null) return;
    setState(() {
      _foodAlertStep = _FoodAlertStep.fillingForm;
    });
  }

  Future<void> _cancelFoodAlertFlow() async {
    if (_foodAlertPin != null) {
      await _foodAlertPinManager?.delete(_foodAlertPin!);
    }
    setState(() {
      _foodAlertStep = _FoodAlertStep.none;
      _foodAlertPin = null;
      _foodAlertPinPosition = null;
    });
  }

  void _flyToFoodAlert(double lat, double lng) {
    mapboxMap?.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 17.5),
      MapAnimationOptions(duration: 600),
    );
  }

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

        if (ts != null) {
          final age = now.difference(ts.toDate());
          if (age >= const Duration(hours: 5)) continue;
        }

        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

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
      _reportingLotName = null;

      if (!wasSameFilter && filter.key == 'study') {
        _selectedStudyBuildingFilter = 'All';
        _selectedExactStudyBuilding = null;
      }

      if (!wasSameFilter && filter.key == 'charging') {
        _selectedOutletBuildingFilter = 'All';
        _selectedExactOutletBuilding = null;
      }

      if (!wasSameFilter && filter.key == 'parking') {
        _selectedParkingZoneFilter = 'All';
      }
    });
    _updateMapPins();
  }

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

  Future<void> _updateMapPins() async {
    if (pointAnnotationManager == null) return;

    await pointAnnotationManager!.deleteAll();

    if (_activeFilter == 'restroom' && _bathroomPinOptions.isNotEmpty) {
      await _loadBathroomPins();
    } else {
      _bathroomPinData.clear();
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

    if (_parkingLotManager != null) {
      if (_activeFilter == 'parking') {
        if (_isDevMode && _demoTimer != null && _demoTimer!.isActive) {
          // Let demo keep rendering
        } else {
          _listenToParkingFirebase();
        }
      } else {
        _parkingStreamSubscription?.cancel();
        await _parkingLotManager!.deleteAll();
        await _parkingLabelManager?.deleteAll();
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

    // Keep personal location pins visible after filter changes
    await _refreshPinsFromFirebase();
  }

  Widget? get _activeSheetContent {
    if (_foodAlertStep == _FoodAlertStep.fillingForm) {
      return CreateFoodAlertSheet(
        pinPosition: _foodAlertPinPosition!,
        onClose: _cancelFoodAlertFlow,
        onSubmitted: () {
          _cancelFoodAlertFlow();
          if (_activeFilter == 'food') {
            _loadFoodAlertMapPins();
          }
        },
      );
    }

    if (_activeFilter == null) return null;

    final Position locationToUse = (_isDevMode && _simulatedPosition != null)
        ? _simulatedPosition!
        : Position(_centerLng, _centerLat);

    if (_activeFilter == 'restroom') {
      return _RestroomSheetContent(currentPosition: locationToUse);
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

    if (_activeFilter == 'parking') {
      if (_reportingLotName != null) {
        return _ParkingReportSheetContent(
          lotName: _reportingLotName!,
          // Pass the live data down into the report sheet!
          lotData: _liveParkingData[_reportingLotName!] ?? {},
          onBack: () {
            setState(() {
              _reportingLotName = null;
            });
          },
        );
      }

      final lots = _parkingGeometries.keys.toList()..sort();

      return _ParkingSheetContent(
        availableLots: lots,
        // Pass the live data down into the main list!
        liveDataMap: _liveParkingData,
        selectedZoneFilter: _selectedParkingZoneFilter,
        onZoneFilterChanged: (value) {
          setState(() {
            _selectedParkingZoneFilter = value;
          });
        },
        onReportTapped: (String lotName) {
          setState(() {
            _reportingLotName = lotName;
          });
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
                    if (_isDevMode)
                      TextButton.icon(
                        onPressed: _runParkingDemo,
                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.red,
                        ),
                        label: const Text(
                          "Run 20s Demo",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                      activeThumbImage: null,
                      activeTrackColor: Colors.red.withValues(alpha: 0.5),
                      activeColor: Colors.red,
                      onChanged: (val) {
                        setState(() {
                          _isDevMode = val;
                        });
                        if (!val) {
                          if (_devPin != null) {
                            _devPinManager?.delete(_devPin!);
                          }
                          if (_devCircle != null) {
                            _devCircleManager?.delete(_devCircle!);
                          }
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

      bottomSheet: sheetContent != null
          ? _FilterBottomSheet(
              child: sheetContent,
              onClose: () {
                if (_foodAlertStep == _FoodAlertStep.fillingForm) {
                  _cancelFoodAlertFlow();
                } else {
                  setState(() {
                    _activeFilter = null;
                    _reportingLotName = null;
                  });
                  _updateMapPins();
                }
              },
            )
          : null,

      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            styleUri: "mapbox://styles/theresa2/cmlbykdmm000s01su4z139emu",
            textureView: true,
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTapped,
          ),

          // Route panel only shows when user taps directions button
          if (_showRoutePanel)
            Positioned(
              top: 20,
              left: 12,
              right: 80,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Route panel header
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Find Route',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Close route panel button
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showRoutePanel = false;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),

                      DropdownButton<String>(
                        value: startCategory,
                        hint: const Text('Select start category'),
                        isExpanded: true,
                        items: buildingCategories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            startCategory = value;
                            startBuilding = null;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      DropdownButton<Building>(
                        value: startBuilding,
                        hint: const Text('Select start building'),
                        isExpanded: true,
                        items: startCategoryBuildings.map((building) {
                          return DropdownMenuItem<Building>(
                            value: building,
                            child: Text(building.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            startBuilding = value;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      DropdownButton<String>(
                        value: endCategory,
                        hint: const Text('Select destination category'),
                        isExpanded: true,
                        items: buildingCategories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            endCategory = value;
                            endBuilding = null;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      DropdownButton<Building>(
                        value: endBuilding,
                        hint: const Text('Select destination building'),
                        isExpanded: true,
                        items: endCategoryBuildings.map((building) {
                          return DropdownMenuItem<Building>(
                            value: building,
                            child: Text(building.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            endBuilding = value;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // Get Route Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _getRoute,
                          child: const Text('Get Route'),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Clear Route Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _clearRoute,
                          child: const Text('Clear Route'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

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

          if (_foodAlertStep == _FoodAlertStep.none)
            Positioned(
              top: 20,
              bottom: 250,
              right: 12,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      ..._filters.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RawMaterialButton(
                            onPressed: () => _onFilterTapped(f),
                            fillColor: _activeFilter == f.key
                                ? const Color(0xFFFFCC00)
                                : const ui.Color.fromARGB(255, 243, 250, 255),
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
                      ),

                      // 🚀 ROUTE BUTTON (cleanly added under others)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RawMaterialButton(
                          onPressed: () {
                            setState(() {
                              _showRoutePanel = !_showRoutePanel;
                            });
                          },
                          fillColor: const ui.Color.fromARGB(
                            255,
                            243,
                            250,
                            255,
                          ), // ✅ MATCHED
                          shape: const CircleBorder(),
                          constraints: const BoxConstraints.tightFor(
                            width: 55,
                            height: 55,
                          ),
                          elevation: 4,
                          child: const Icon(
                            Icons.directions,
                            color: Colors.black87,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 📍 Add Personal Pin Button
          if (_foodAlertStep == _FoodAlertStep.none)
            Positioned(
              bottom: 270, // sits above zoom controls
              left: 15,
              child: RawMaterialButton(
                onPressed: () {
                  setState(() {
                    _isAddingPersonalPin = !_isAddingPersonalPin;
                  });
                },
                fillColor: _isAddingPersonalPin
                    ? const Color(0xFFFFCC00) // active = yellow
                    : Colors.grey.shade300,
                shape: const CircleBorder(),
                constraints: const BoxConstraints.tightFor(
                  width: 50,
                  height: 50,
                ),
                elevation: 10,
                child: const Icon(Icons.add_location_alt, color: Colors.black),
              ),
            ),
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

          if (_foodAlertStep == _FoodAlertStep.placingPin)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _foodAlertPinPosition != null
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

// Detects when a user taps a saved personal pin
class _PinClickListener extends OnCircleAnnotationClickListener {
  final Future<void> Function(CircleAnnotation annotation) onPinTapped;

  _PinClickListener({required this.onPinTapped});

  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    onPinTapped(annotation);
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
  final String selectedZoneFilter;
  final ValueChanged<String> onZoneFilterChanged;
  final ValueChanged<String> onReportTapped;
  final List<String> availableLots;
  final Map<String, Map<String, dynamic>> liveDataMap;

  const _ParkingSheetContent({
    required this.selectedZoneFilter,
    required this.onZoneFilterChanged,
    required this.onReportTapped,
    required this.availableLots,
    required this.liveDataMap,
  });

  final List<String> _zoneFilters = const [
    'All',
    'Pyramid',
    'G Lots',
    'E Lots',
    'Palo Verde',
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'full':
        return Colors.red.shade600;
      case 'moderate':
        return Colors.orange.shade600;
      case 'empty':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _calculateStatus(int searchingCount, int parkedCount) {
    if (searchingCount >= 15) return 'Full';
    if (searchingCount >= 5) return 'Moderate';
    return 'Empty';
  }

  bool _matchesZone(String lotName, String zone) {
    if (zone == 'All') return true;
    final name = lotName.toUpperCase();
    if (zone == 'G Lots') return name.contains(' G') || name.startsWith('G');
    if (zone == 'E Lots') return name.contains(' E') || name.startsWith('E');
    if (zone == 'Pyramid') return name.contains('PYRAMID');
    if (zone == 'Palo Verde')
      return name.contains('PALO VERDE') || name.contains('PV');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final filteredLots = availableLots
        .where((name) => _matchesZone(name, selectedZoneFilter))
        .toList();
    filteredLots.sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 0, bottom: 8),
          child: Text(
            "Parking lots and structures",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _zoneFilters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = _zoneFilters[index];
              final isSelected = selectedZoneFilter == filter;

              return ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => onZoneFilterChanged(filter),
                selectedColor: const Color(0xFFF2D21B),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: Colors.black87,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.grey.shade300,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        if (filteredLots.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No parking lots found for $selectedZoneFilter.',
              style: const TextStyle(color: Colors.grey),
            ),
          ),

        if (filteredLots.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 5, bottom: 20),
            itemCount: filteredLots.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey.shade300, height: 1, thickness: 1),
            itemBuilder: (context, index) {
              final name = filteredLots[index];

              final liveData = liveDataMap[name] ?? {};
              final searchingCount = liveData['searching_count'] ?? 0;
              final parkedCount = liveData['parked_count'] ?? 0;

              final statusText = _calculateStatus(searchingCount, parkedCount);
              final statusColor = _getStatusColor(statusText);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Status : $statusText',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '● Actively Searching: $searchingCount',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '● Parked Vehicles: $parkedCount',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onReportTapped(name),
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.black87,
                          size: 20,
                        ),
                        label: const Text(
                          'Make a Report',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ParkingReportSheetContent extends StatelessWidget {
  final String lotName;
  final VoidCallback onBack;
  final Map<String, dynamic> lotData;

  const _ParkingReportSheetContent({
    required this.lotName,
    required this.onBack,
    required this.lotData,
  });

  void _submitReport(BuildContext context, String status) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('parking_lots')
          .where('name', isEqualTo: lotName)
          .get();

      int newSearch = 0;
      if (status == 'Full') newSearch = 20;
      if (status == 'Moderate') newSearch = 10;
      if (status == 'Empty') newSearch = 1;

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'searching_count': newSearch,
          'last_report': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('parking_lots').add({
          'name': lotName,
          'searching_count': newSearch,
          'parked_count': 0,
          'last_report': FieldValue.serverTimestamp(),
        });
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Report submitted for $lotName')));
      onBack();
    } catch (e) {
      debugPrint("Error updating report: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int searchingCount = lotData['searching_count'] ?? 0;
    int parkedCount = lotData['parked_count'] ?? 0;

    final total = searchingCount + parkedCount;
    double occupancy = total == 0 ? 0 : searchingCount / 20.0;
    if (occupancy > 1.0) occupancy = 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Location:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    lotName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 30,
                  color: Colors.black54,
                ),
                onPressed: onBack,
              ),
            ],
          ),
          const Divider(thickness: 1.5, height: 30),

          Text(
            "Predicted Capacity: ${(occupancy * 100).toInt()}%",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(painter: _DonutChartPainter(occupancy)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    bool filled = index < (occupancy * 5).round();
                    return Icon(
                      Icons.person,
                      size: 20,
                      color: filled ? Colors.black : Colors.grey.shade400,
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            "How's the parking here?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ReportButton(
                label: "Empty",
                color: Colors.green.shade600,
                icon: Icons.check_circle_outline,
                onTap: () => _submitReport(context, "Empty"),
              ),
              _ReportButton(
                label: "Moderate",
                color: Colors.orange.shade600,
                icon: Icons.error_outline,
                onTap: () => _submitReport(context, "Moderate"),
              ),
              _ReportButton(
                label: "Full",
                color: Colors.red.shade600,
                icon: Icons.cancel_outlined,
                onTap: () => _submitReport(context, "Full"),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double capacity;
  _DonutChartPainter(this.capacity);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;

    paint.color = Colors.green.shade400;
    canvas.drawCircle(center, radius, paint);

    paint.color = Colors.red.shade400;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * capacity,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ReportButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ReportButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// NEW FROM GISELLE: STUDY HALL Map Preview
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
    // building filter
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

  // boo to calculate if study hall is available based on user time
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

  // filter options
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
    // building study hall card
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
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

        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          final building = (data['buildingAbbrev'] ?? '').toString().trim();

          if (selectedExactBuilding != null &&
              selectedExactBuilding!.isNotEmpty) {
            return building.toUpperCase() ==
                selectedExactBuilding!.toUpperCase();
          }

          return _matchesBuildingFilter(building);
        }).toList();
        // title card
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
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
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
            // if building is not a filter option
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
            // if filter option has no study hall
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
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.grey.shade200, height: 1),
                // what  study hall description needs
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data();
                  // NEW FROM GISELLE REVIEW 4: gets Firestore doc id for study hall reports
                  final docId = filteredDocs[index].id;

                  final building = (data['buildingAbbrev'] ?? '')
                      .toString()
                      .trim();
                  final room = (data['roomNumber'] ?? '').toString().trim();
                  final startTime = (data['startTime'] ?? '').toString();
                  final endTime = (data['endTime'] ?? '').toString();
                  final seats = data['seatCapacity'];
                  final amenities = List<String>.from(data['amenities'] ?? []);
                  final isAvailableNow = _isCurrentlyAvailable(
                    startTime,
                    endTime,
                  );
                  // final room presentation
                  final cleanRoom = room.toLowerCase().startsWith('room ')
                      ? room.substring(5).trim()
                      : room;
                  // final title presentation
                  final title = building.isNotEmpty
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
                    // how availabile now is gonna show when true
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
                          // to adjust how amentities look
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
                          builder: (context) => ExpandedStudyHallScreen(
                            // NEW FROM GISELLE REVIEW 4: pass report info
                            docId: docId,
                            reportedUserId:
                                (data['userId'] ?? data['createdBy'] ?? '')
                                    .toString(),
                            title: title,
                            buildingName: (data['buildingName'] ?? '')
                                .toString(),
                            startTime: startTime,
                            endTime: endTime,
                            seats: seats is int
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
    // building filter req
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

  // filter building options
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
      stream: FirebaseFirestore.instance
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
        // error handling
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Could not load outlets: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        // how to filter building
        final filteredDocs = docs.where((doc) {
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
                  // how filter chips are displayed
                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => onBuildingFilterChanged(filter),
                    selectedColor: const Color(0xFFF2D21B),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
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
            // creating how 'add outlet details' button looks
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
            // if filter options are empty
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
            // how filter options look
            if (filteredDocs.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                itemCount: filteredDocs.length,
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.grey.shade200, height: 1),
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data();
                  final docId = filteredDocs[index].id;

                  final building = (data['buildingAbbrev'] ?? '')
                      .toString()
                      .trim();
                  final room = (data['roomNumber'] ?? '').toString().trim();
                  final outletCount = data['outletCount'];
                  final outletTypes = List<String>.from(
                    data['outletTypes'] ?? [],
                  );
                  final accessibilityLevels = List<String>.from(
                    data['accessibilityLevels'] ?? [],
                  );

                  final cleanRoom = room.toLowerCase().startsWith('room ')
                      ? room.substring(5).trim()
                      : room;
                  // how title is gonna be displayed
                  final title = building.isNotEmpty
                      ? '$building Room $cleanRoom ⚡'
                      : 'Room $cleanRoom ⚡';

                  String subtitle = '';
                  if (outletCount != null) {
                    subtitle = 'Number of Outlets: $outletCount';
                  }
                  // outlet types
                  if (outletTypes.isNotEmpty) {
                    subtitle = subtitle.isEmpty
                        ? 'Type: ${outletTypes.join(', ')}'
                        : '$subtitle\nType: ${outletTypes.join(', ')}';
                  }
                  // accessibility display
                  if (accessibilityLevels.isNotEmpty) {
                    subtitle = subtitle.isEmpty
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
                          builder: (context) => ExpandedOutletScreen(
                            docId: docId,
                            reportedUserId:
                                (data['userId'] ?? data['createdBy'] ?? '')
                                    .toString(),
                            title: building.isNotEmpty
                                ? '$building Room $cleanRoom'
                                : 'Room $cleanRoom',
                            buildingName: (data['buildingName'] ?? '')
                                .toString(),
                            outletCount: outletCount is int
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

  // --- NEW: This forces the list to reload when the Dev Pin moves! ---
  @override
  void didUpdateWidget(covariant _RestroomSheetContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition.lat != widget.currentPosition.lat ||
        oldWidget.currentPosition.lng != widget.currentPosition.lng) {
      setState(() => _isLoading = true);
      _loadList();
    }
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
          'distStr': dist < 1000
              ? "${dist.toStringAsFixed(0)} ft"
              : "${(dist / 5280).toStringAsFixed(1)} mi",
          'details': 'Loading stats...',
        });
      }

      results.sort((a, b) => a['distVal'].compareTo(b['distVal']));
      var top5 = results.take(5).toList();

      if (mounted) {
        setState(() {
          _dynamicList = top5;
          _isLoading = false;
        });
      }

      for (var b in top5) {
        // NEW FROM GISELLE REVIEW 4: Match reviews by building name,
        final String buildingName = (b['name'] ?? '').toString().trim();

        final snap = await FirebaseFirestore.instance
            .collection('bathroom_reviews')
            .where('bathroomName', isGreaterThanOrEqualTo: buildingName)
            .where('bathroomName', isLessThanOrEqualTo: '$buildingName\uf8ff')
            .get();
        // how to format preview
        if (snap.docs.isNotEmpty) {
          Map<String, int> counts = {};
          double ratingTotal = 0;
          int ratingCount = 0;

          for (var doc in snap.docs) {
            final data = doc.data();

            final rating = data['rating'];
            if (rating is int) {
              ratingTotal += rating;
              ratingCount++;
            } else if (rating is double) {
              ratingTotal += rating;
              ratingCount++;
            }
            // features
            Map<String, dynamic> fts = data['features'] ?? {};
            fts.forEach((k, v) {
              if (v == true) counts[k] = (counts[k] ?? 0) + 1;
            });
          }
          // top features
          final String topFeature = counts.isNotEmpty
              ? counts.entries.reduce((a, b) => a.value > b.value ? a : b).key
              : 'Reviewed';
          // review
          final String ratingText = ratingCount > 0
              ? '⭐ ${(ratingTotal / ratingCount).toStringAsFixed(1)} ($ratingCount)'
              : 'Reviewed';

          if (mounted) {
            setState(() {
              b['details'] = '$ratingText • $topFeature';
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

        // NEW FROM GISELLE: Add Bathroom Review button for restroom bottom sheet
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.black, size: 22),
          ),
          title: const Text(
            'Add Bathroom Review',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BathroomFinder()),
            );

            if (result == true) {
              _loadList();
            }
          },
        ),

        // NEW FROM GISELLE: Divider to match Study Hall and Outlet sheet layout
        Divider(color: Colors.grey.shade300, height: 20),

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
            separatorBuilder: (context, index) =>
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

                // NEW FROM GISELLE REVIEW 4: Opens expanded bathroom page from restroom preview
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpandedBathroomFinderPage(
                        bathroomName: (b["name"] ?? '').toString(),
                        buildingAbbrev: (b["abbrev"] ?? '').toString(),
                        distance: (b["distStr"] ?? '').toString(),
                        details: (b["details"] ?? '').toString(),
                      ),
                    ),
                  );
                },
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

// NEW FROM GISELLE REVIEW 4: Restroom pin opens expanded bathroom page for that building
class _BathroomClickListener extends OnPointAnnotationClickListener {
  final void Function(Map<String, dynamic>) onTap;
  final Map<String, Map<String, dynamic>> pinData;

  _BathroomClickListener(this.onTap, this.pinData);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    final data = pinData[annotation.id];
    if (data == null) return;

    onTap(data);
  }
}

// NEW FROM GISELLE: STUDY HALL click listener
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

// NEW FROM GISELLE: OUTLET Click listener
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
