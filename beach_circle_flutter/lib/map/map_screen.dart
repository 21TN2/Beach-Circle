import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  String? _selectedBuildingId;

  // Bottom bar state. Might change later
  String? _selectedBuildingLabel; // e: "COB: College of Business"
 
  // Default location. Coordinates to CSULB
  static const double _centerLat = 33.7820;
  static const double _centerLng = -118.1126;

  // Layer / source IDs
  static const String _buildingSourceId = 'buildings-source';
  static const String _buildingFillLayerId = 'buildings-fill-layer';
  static const String _buildingOutlineLayerId = 'buildings-outline-layer';

  //coordinates for map boundaries
  static final campusBounds = CoordinateBounds(
      southwest: Point(
        coordinates: Position(-118.1225, 33.77387), //long, lat
      ),
      northeast: Point(
        coordinates: Position(-118.1070, 33.78988),
      ),
      infiniteBounds: false,
    );

  void _onMapCreated(MapboxMap map) async {
    mapboxMap = map;

    await mapboxMap!.gestures.updateSettings(
      GesturesSettings(
        rotateEnabled: false,
        pitchEnabled: false,
      ),
    );

    //Set camera
    await mapboxMap!.setCamera(
      CameraOptions(
        bearing: 0,
        center: Point(
          coordinates: Position(
            _centerLng,
            _centerLat,
          ),
        ),
        zoom: 15.0,
      ),
    );

    //setting map boundaries
    await mapboxMap!.setBounds(
      CameraBoundsOptions(
        bounds: campusBounds,
        minZoom: 13.0,
        maxZoom: 20.0,
      ),
    );
   
    // Add a marker at the center location
    await mapboxMap?.annotations.createPointAnnotationManager().then((manager) async {
      pointAnnotationManager = manager;
     
      final pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(_centerLng, _centerLat)),
        iconSize: 1.5,
        iconImage: "marker", 
      );
     
      pointAnnotationManager?.create(pointAnnotationOptions);
    });

    // Load buildings from Firebase and add to map
    await _loadBuildingsFromFirebase();
  }

  Future<void> _loadBuildingsFromFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('buildings')
          .get();

      final features = snapshot.docs.map((doc) {
        final data = doc.data();

        // Reconstruct coords from [{lng, lat}, ...] back into GeoJSON ring format
        final rawCoords = data['coords'] as List<dynamic>? ?? [];
        final ring = rawCoords
            .map((c) => [
                  (c['lng'] as num).toDouble(),
                  (c['lat'] as num).toDouble(),
                ])
            .toList();

        final geometryType = data['geometry_type'] as String? ?? 'Polygon';

        // GeoJSON Polygon coords = [ [ring] ], MultiPolygon = [ [ [ring] ] ]
        // For simplicity we wrap MultiPolygon flattened coords as a single Polygon ring
        final coordinates = [ring];

        final abbrev = data['abbrev'] as String? ?? '';
        final name = data['name'] as String? ?? '';

        return {
          'type': 'Feature',
          'id': doc.id,
          'geometry': {
            'type': 'Polygon',
            'coordinates': coordinates,
          },
          'properties': {
            'id': doc.id,
            'name': name,
            'abbreviation': abbrev, // normalize to 'abbreviation' internally
          },
        };
      }).toList();

      final geojson = jsonEncode({
        'type': 'FeatureCollection',
        'features': features,
      });

      await mapboxMap!.style.addSource(
        GeoJsonSource(
          id: _buildingSourceId,
          data: geojson,
        ),
      );

      // Add fill layer with no paint properties first
      await mapboxMap!.style.addLayer(
        FillLayer(
          id: _buildingFillLayerId,
          sourceId: _buildingSourceId,
        ),
      );

      // Set fill color expression via JSON string
      await mapboxMap!.style.setStyleLayerProperty(
        _buildingFillLayerId,
        'fill-color',
        jsonEncode([
          'case',
          ['boolean', ['feature-state', 'selected'], false],
          '#4A90D9',
          'rgba(0,0,0,0)',
        ]),
      );

      await mapboxMap!.style.setStyleLayerProperty(
        _buildingFillLayerId,
        'fill-opacity',
        jsonEncode([
          'case',
          ['boolean', ['feature-state', 'selected'], false],
          0.45,
          0.0,
        ]),
      );

      // Add outline layer
      await mapboxMap!.style.addLayer(
        LineLayer(
          id: _buildingOutlineLayerId,
          sourceId: _buildingSourceId,
        ),
      );

      await mapboxMap!.style.setStyleLayerProperty(
        _buildingOutlineLayerId,
        'line-color',
        jsonEncode([
          'case',
          ['boolean', ['feature-state', 'selected'], false],
          '#1A5FA8',
          'rgba(0,0,0,0)',
        ]),
      );

      await mapboxMap!.style.setStyleLayerProperty(
        _buildingOutlineLayerId,
        'line-width',
        jsonEncode([
          'case',
          ['boolean', ['feature-state', 'selected'], false],
          2.0,
          0.0,
        ]),
      );
    } catch (e) {
      debugPrint('Error loading buildings from Firebase: $e');
    }
  }

  void _onMapTap(MapContentGestureContext context) async {
    if (mapboxMap == null) return;

    // Query rendered features at the tapped screen point
    final screenPoint = context.touchPosition;

    final features = await mapboxMap!.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(
        ScreenCoordinate(x: screenPoint.x, y: screenPoint.y),
      ),
      RenderedQueryOptions(
        layerIds: [_buildingFillLayerId],
      ),
    );

    if (features.isEmpty) {
      // Tapped on empty area — deselect
      await _deselectBuilding();
      return;
    }

    // final tappedFeature = features.first;
    // final featureId = tappedFeature?.queriedContent?.feature['id'] as String?;
    // final properties = tappedFeature?.queriedContent?.feature['properties']
    //     as Map<String, dynamic>?;

    // final tappedFeature = features.first;
    // final feature = tappedFeature?.queriedFeature.feature;
    // final featureId = feature?['id'] as String?;
    // final properties = feature?['properties'] as Map<String, dynamic>?;

    final tappedFeature = features.first;
    final feature = tappedFeature?.queriedFeature.feature;
    final featureId = feature?['id']?.toString();
    final rawProperties = feature?['properties'];
    final properties = rawProperties != null 
        ? Map<String, dynamic>.from(rawProperties as Map) 
        : null;

    if (featureId == null || properties == null) return;

    // If tapping the already-selected building, deselect it
    if (featureId == _selectedBuildingId) {
      await _deselectBuilding();
      return;
    }

    // Deselect previous
    if (_selectedBuildingId != null) {
      await mapboxMap!.setFeatureState(
        _buildingSourceId,
        null,
        _selectedBuildingId!,
        jsonEncode({'selected': false}),
      );
    }

    // Select new building
    await mapboxMap!.setFeatureState(
      _buildingSourceId,
      null,
      featureId,
      jsonEncode({'selected': true}),
    );

    final name = properties['name'] as String? ?? '';
    final abbreviation = properties['abbreviation'] as String? ?? '';
    final label =
        abbreviation.isNotEmpty ? '$abbreviation: $name' : name;

    setState(() {
      _selectedBuildingId = featureId;
      _selectedBuildingLabel = label;
    });
  }

  Future<void> _deselectBuilding() async {
    if (_selectedBuildingId != null && mapboxMap != null) {
      await mapboxMap!.setFeatureState(
        _buildingSourceId,
        null,
        _selectedBuildingId!,
        jsonEncode({'selected': false}),
      );
    }
    setState(() {
      _selectedBuildingId = null;
      _selectedBuildingLabel = null;
    });
  }

  //zoom into map
  void _zoomIn() async {
    final cameraState = await mapboxMap?.getCameraState();
    final currentZoom = cameraState?.zoom ?? 12.0;
    
    mapboxMap?.flyTo(
      CameraOptions(
        zoom: currentZoom + 1,
      ),
      MapAnimationOptions(duration: 500),
    );
  }

  // zoom out of map
  void _zoomOut() async {
    final cameraState = await mapboxMap?.getCameraState();
    final currentZoom = cameraState?.zoom ?? 12.0;
    
    mapboxMap?.flyTo(
      CameraOptions(
        zoom: currentZoom - 1,
      ),
      MapAnimationOptions(duration: 500),
    );
  }

  //refreshing to center view
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            styleUri: "mapbox://styles/theresa2/cmlbykdmm000s01su4z139emu",
            textureView: true,
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTap,
          ),

          // Zoom / home controls — fixed position, never moves
          Positioned(
            bottom: 40,
            left: 15,
            child: Column(
              children: [
                RawMaterialButton(
                  onPressed: _zoomIn,
                  fillColor: Colors.grey.shade300,
                  shape: const CircleBorder(),
                  constraints: const BoxConstraints.tightFor(width: 46, height: 46),
                  elevation: 10,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 5),
                RawMaterialButton(
                  onPressed: _zoomOut,
                  fillColor: Colors.grey.shade300,
                  shape: const CircleBorder(),
                  constraints: const BoxConstraints.tightFor(width: 46, height: 46),
                  elevation: 10,
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
                const SizedBox(height: 5),
                RawMaterialButton(
                  onPressed: _resetView,
                  fillColor: Colors.grey.shade300,
                  shape: const CircleBorder(),
                  constraints: const BoxConstraints.tightFor(width: 50, height: 50),
                  elevation: 10,
                  child: const Icon(Icons.home, color: Colors.black),
                ),
              ],
            ),
          ),

          // Building info bar — separate Positioned, direct Stack child
          if (_selectedBuildingLabel != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BuildingInfoBar(
                label: _selectedBuildingLabel!,
                onClose: _deselectBuilding,
              ),
            ),
        ],
      ),
    );
  }
}


//make this a nenw widget in the future
class _BuildingInfoBar extends StatelessWidget {
  const _BuildingInfoBar({
    required this.label,
    required this.onClose,
  });

  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}