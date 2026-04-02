import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bathroom_finder.dart';

import '../map_features/add_study_hall_screen.dart';
import '../map_features/add_outlet_screen.dart';

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

  String? _activeFilter;

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
      sheetContent: _FoodAlertSheetContent(),
    ),
    FilterOption(
      key: 'study',
      icon: Icons.menu_book,
      label: 'Study',
      hasBottomSheet: true,
      sheetContent: _StudySheetContent(),
    ),
    FilterOption(
      key: 'charging',
      icon: Icons.electric_bolt,
      label: 'Charging',
      hasBottomSheet: true,
      sheetContent: _ChargingSheetContent(),
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
    await mapboxMap?.annotations.createPointAnnotationManager().then((
      manager,
    ) async {
      pointAnnotationManager = manager;
      await _loadBuildingBathrooms();
      pointAnnotationManager?.addOnPointAnnotationClickListener(
        _BathroomClickListener(context),
      );
      _updateMapPins();
    });
    _devPinManager =
        await mapboxMap?.annotations.createPointAnnotationManager();
    _devCircleManager =
        await mapboxMap?.annotations.createCircleAnnotationManager();
  }

  void _onMapTapped(MapContentGestureContext context) async {
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
      _activeFilter = (_activeFilter == filter.key) ? null : filter.key;
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
        setState(() {});
      }
      // } else if (_activeFilter == 'charging') {
      //   final result = await Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (context) => const AddOutletScreen()),
      //   );

      // if (result == true) {
      //   setState(() {});
      //}
    }
  }

  // --------
  Future<void> _updateMapPins() async {
    if (pointAnnotationManager == null) return;
    await pointAnnotationManager?.deleteAll();
    if (_activeFilter == 'restroom' && _bathroomPinOptions.isNotEmpty) {
      await pointAnnotationManager?.createMulti(_bathroomPinOptions);
    }
  }

  Widget? get _activeSheetContent {
    if (_activeFilter == null) return null;

    // Fixed null safety access for lng and lat
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
    final filter = _filters.firstWhere(
      (f) => f.key == _activeFilter,
      orElse: () => _filters.first,
    );
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
                  setState(() => _activeFilter = null);
                  _updateMapPins();
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
          // NEW from Giselle: show + button for study hall and outlets
          if (_activeFilter == 'study' || _activeFilter == 'charging')
            Positioned(
              right: 16,
              bottom: 310,
              child: FloatingActionButton(
                onPressed: _onAddTapped,
                backgroundColor: const Color(0xFFD4C400),
                foregroundColor: Colors.black,
                child: const Icon(Icons.add),
              ),
            ),

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

class _StudySheetContent extends StatelessWidget {
  const _StudySheetContent();
  @override
  Widget build(BuildContext context) => const _SheetPlaceholder(
    icon: Icons.menu_book,
    label: 'Study spaces and libraries',
  );
}

class _ChargingSheetContent extends StatelessWidget {
  const _ChargingSheetContent();
  @override
  Widget build(BuildContext context) => const _SheetPlaceholder(
    icon: Icons.electric_bolt,
    label: 'EV and device charging stations',
  );
}

class _FoodAlertSheetContent extends StatelessWidget {
  const _FoodAlertSheetContent();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 0, bottom: 5),
          child: Text(
            "Food Alerts",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 5, bottom: 20),
          itemCount: 3,
          separatorBuilder:
              (context, index) =>
                  Divider(color: Colors.grey.shade200, height: 1),
          itemBuilder: (context, index) {
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
                child: const Icon(Icons.pin_drop, color: Colors.red, size: 22),
              ),
              title: const Text(
                "Recent Alert",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: const Text(
                "Details coming soon",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            );
          },
        ),
      ],
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
