import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //Added for firebase to track pins

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;

  //Creates circle pins on the map
  CircleAnnotationManager? circleAnnotationManager;

  //Pins Id for the firebase
  final Map<String, String> _annotationToDocId = {};

  bool _ignoreNextMapTap = false;

  // Default location. Coordinates to CSULB
  static const double _centerLat = 33.7820;
  static const double _centerLng = -118.1126;

  //coordinates for map boundaries
  static final campusBounds = CoordinateBounds(
    southwest: Point(
      coordinates: Position(-118.1225, 33.77387), //long, lat
    ),
    northeast: Point(coordinates: Position(-118.1070, 33.78988)),
    infiniteBounds: false,
  );

  void _onMapCreated(MapboxMap map) async {
    mapboxMap = map;

    await mapboxMap!.gestures.updateSettings(
      GesturesSettings(rotateEnabled: false, pitchEnabled: false),
    );

    //Set camera
    await mapboxMap!.setCamera(
      CameraOptions(
        bearing: 0,
        center: Point(coordinates: Position(_centerLng, _centerLat)),
        zoom: 15.0,
      ),
    );

    //setting map boundaries
    await mapboxMap!.setBounds(
      CameraBoundsOptions(bounds: campusBounds, minZoom: 13.0, maxZoom: 20.0),
    );

    //User pins(Circle pins)
    circleAnnotationManager =
        await mapboxMap!.annotations.createCircleAnnotationManager();

    //If user wants to delete existing pins
    circleAnnotationManager!.addOnCircleAnnotationClickListener(
      _PinClickListener(
        onPinTapped: (annotation) async {
          _ignoreNextMapTap = true;

          //Gets pin's Id from the firebase
          final docId = _annotationToDocId[annotation.id];
          if (docId == null) return;

          //Pin Details
          final pinDoc =
              await FirebaseFirestore.instance
                  .collection('pins')
                  .doc(docId)
                  .get();

          final pinData = pinDoc.data() ?? {};
          final String label = (pinData['label'] ?? '').toString();
          final String description = (pinData['description'] ?? '').toString();
          final String color = (pinData['color'] ?? 'blue').toString();

          final shouldDelete = await showDialog<bool>(
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
                    const SizedBox(height: 12),
                    const Text('Do you want to remove this pinned location?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );

          if (shouldDelete != true) return;

          //Deletes pin from firebase
          await FirebaseFirestore.instance
              .collection('pins')
              .doc(docId)
              .delete();

          await _refreshPinsFromFirebase();

          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Pin deleted')));
        },
      ),
    );

    await _refreshPinsFromFirebase();
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

  //When User Taps on the Map
  Future<void> _onMapTap(MapContentGestureContext tapContext) async {
    if (_ignoreNextMapTap) {
      _ignoreNextMapTap = false;
      return;
    }

    final double lat = tapContext.point.coordinates.lat.toDouble();
    final double lng = tapContext.point.coordinates.lng.toDouble();

    //Default Color Pin 
    String selectedColor = 'blue';

    //User input for pin details
    final TextEditingController labelController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    //Ask users if they want to pin location
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

                    //Pin Details Title
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

                    //Description for pins
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

                    //Color options
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

    CircleAnnotation? annotation;

    try {
      //Pin shown immediately
      annotation = await circleAnnotationManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          circleRadius: 8.0,
          circleColor: _getPinColor(selectedColor),
          circleStrokeWidth: 2.0,
          circleStrokeColor: Colors.white.value,
        ),
      );

      //Save pin in the firebase
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

  //zoom into map
  void _zoomIn() async {
    final cameraState = await mapboxMap?.getCameraState();
    final currentZoom = cameraState?.zoom ?? 12.0;

    mapboxMap?.flyTo(
      CameraOptions(zoom: currentZoom + 1),
      MapAnimationOptions(duration: 500),
    );
  }

  // zoom out of map
  void _zoomOut() async {
    final cameraState = await mapboxMap?.getCameraState();
    final currentZoom = cameraState?.zoom ?? 12.0;

    mapboxMap?.flyTo(
      CameraOptions(zoom: currentZoom - 1),
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

            // cameraOptions: CameraOptions(
            //   center: Point(coordinates: Position(_centerLng, _centerLat)),
            //   zoom: 12.0,
            // ),

            // Map style
            styleUri: "mapbox://styles/theresa2/cmlbykdmm000s01su4z139emu",

            textureView: true, // Better for web/Android
            onMapCreated: _onMapCreated,

            //Detects pin on the map
            onTapListener: _onMapTap,
          ),

          //bottom left positioning buttons
          Positioned(
            bottom: 40,
            left: 15,
            child: Column(
              children: [
                //Zoom in button
                RawMaterialButton(
                  onPressed: _zoomIn,
                  fillColor: Colors.grey.shade300,
                  shape: const CircleBorder(),
                  constraints: BoxConstraints.tightFor(width: 46, height: 46),
                  elevation: 10,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 5),
                //Zoom out button
                RawMaterialButton(
                  onPressed: _zoomOut,
                  fillColor: Colors.grey.shade300,
                  shape: const CircleBorder(),
                  constraints: BoxConstraints.tightFor(width: 46, height: 46),
                  elevation: 10,
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
                const SizedBox(height: 5),
                //Center button
                RawMaterialButton(
                  onPressed: _resetView,
                  fillColor: Colors.grey.shade300,
                  shape: const CircleBorder(),
                  constraints: BoxConstraints.tightFor(width: 50, height: 50),
                  elevation: 10,
                  child: const Icon(Icons.home, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//Detects when a users taps the map
class _PinClickListener extends OnCircleAnnotationClickListener {
  final Future<void> Function(CircleAnnotation annotation) onPinTapped;

  _PinClickListener({required this.onPinTapped});

  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    onPinTapped(annotation);
  }
}
