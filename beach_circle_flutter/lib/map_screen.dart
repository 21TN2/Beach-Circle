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
 
  // Default location (CSULB)
  static const double _centerLat = 33.7820;
  static const double _centerLng = -118.1126;


  static final campusBounds = CoordinateBounds(
      southwest: Point(
        coordinates: Position(-118.1218, 33.7755),
      ),
      northeast: Point(
        coordinates: Position(-118.10769, 33.7888),
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
        iconImage: "marker", // Built-in marker icon
      );
     
      pointAnnotationManager?.create(pointAnnotationOptions);
    });
  }


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
      body: Column(
        children: [
          Expanded(
            child: MapWidget(
              // IMPORTANT: Replace this with your own Mapbox access token
              // Get one for free at https://account.mapbox.com/access-tokens/
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
          ),
          
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _zoomIn,
                  icon: const Icon(Icons.add),
                  label: const Text('Zoom In'),
                ),
                ElevatedButton.icon(
                  onPressed: _zoomOut,
                  icon: const Icon(Icons.remove),
                  label: const Text('Zoom Out'),
                ),
                ElevatedButton.icon(
                  onPressed: _resetView,
                  icon: const Icon(Icons.home),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class MapScreen extends StatelessWidget {
//   const MapScreen({super.key});

//   //log out button
//   void _logOut() async {
//     await FirebaseAuth.instance.signOut();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;
//     final name = user?.email ?? "User"; //in the future change this to fetching a username from Firestore (need to change signup requirements)
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('Map'),
//         actions: [
//           //log out button
//           IconButton(
//             icon: const Icon(Icons.logout),
//             tooltip: 'Log Out',
//             onPressed: _logOut,
//           ),
//         ],
//       ),
//       body: Center(
//         child: Text(
//           'Hello $name',
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }