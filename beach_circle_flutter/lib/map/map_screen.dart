import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
 
  // Default location. Coordinates to CSULB
  static const double _centerLat = 33.7820;
  static const double _centerLng = -118.1126;

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

  Widget _buildFilterButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RawMaterialButton(
        onPressed: onPressed,
        fillColor: const ui.Color.fromARGB(255, 223, 239, 255),
        shape: const CircleBorder(),
        constraints: const BoxConstraints.tightFor(width: 55, height: 55),
        elevation: 4,
        child: Icon(icon, color: Colors.black87, size: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const ui.Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFFF2D21B), 
          elevation: 0,
          titleSpacing: 16,
          toolbarHeight: 300,
          title:
          Container(
            padding: const EdgeInsets.all(5), // inner padding
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
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black,
                  size: 28,
                ),
              ],
            ),
          ),
          automaticallyImplyLeading: false,
        ),
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
          ),

          // Positioned(
          //   top: 20,
          //   right: 12,
          //   child: Column(
          //     children: [
          //       _buildFilterButton(
          //         icon: Icons.directions_car,
          //         onPressed: () {},
          //       ),
          //       _buildFilterButton(
          //         icon: Icons.local_pizza,
          //         onPressed: () {},
          //       ),
          //       _buildFilterButton(
          //         icon: Icons.menu_book,
          //         onPressed: () {},
          //       ),
          //       _buildFilterButton(
          //         icon: Icons.electric_bolt,
          //         onPressed: () {},
          //       ),
          //       _buildFilterButton(
          //         icon: Icons.wc,
          //         onPressed: () {},
          //       ),
          //     ],
          //   ),
          // ),
          Positioned(
            top: 20,
            bottom: 380, // stay above the bottom nav bar
            right: 12,
            child: ScrollConfiguration(
              // Hide the scrollbar indicator entirely
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildFilterButton(
                      icon: Icons.directions_car,
                      onPressed: () {},
                    ),
                    _buildFilterButton(
                      icon: Icons.local_pizza,
                      onPressed: () {},
                    ),
                    _buildFilterButton(
                      icon: Icons.menu_book,
                      onPressed: () {},
                    ),
                    _buildFilterButton(
                      icon: Icons.electric_bolt,
                      onPressed: () {},
                    ),
                    _buildFilterButton(
                      icon: Icons.wc,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
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
                  shape: CircleBorder(),
                  constraints: BoxConstraints.tightFor(
                    width: 46,
                    height: 46,
                  ),
                  elevation: 10,
                  child: Icon(
                    Icons.add,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5),
                //Zoom out button
                RawMaterialButton(
                  onPressed: _zoomOut,
                  fillColor: Colors.grey.shade300,
                  shape: CircleBorder(),
                  constraints: BoxConstraints.tightFor(
                    width: 46,
                    height: 46,
                  ),
                  elevation: 10,
                  child: Icon(
                    Icons.remove,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5),
                //Center button
                RawMaterialButton(
                  onPressed: _resetView,
                  fillColor: Colors.grey.shade300,
                  shape: CircleBorder(),
                  constraints: BoxConstraints.tightFor(
                    width: 50,
                    height: 50,
                  ),
                  elevation: 10,
                  child: Icon(
                    Icons.home,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
