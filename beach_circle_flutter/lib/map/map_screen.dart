import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

//new dart
class FilterOption {
  final String key;
  final IconData icon;
  final String label;
  final bool hasBottomSheet; // false = marker-only (e.g. Food)
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
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  // Currently selected filter key (null = none selected)
  String? _activeFilter;
 
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

  //filter details
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
      hasBottomSheet: false,
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
      sheetContent: _RestroomSheetContent(),
    ),

    FilterOption(
      key: 'restroom',
      icon: Icons.wc,
      label: 'Restrooms',
      hasBottomSheet: true,
      sheetContent: _RestroomSheetContent(),
    ),
    FilterOption(
      key: 'restroom',
      icon: Icons.wc,
      label: 'Restrooms',
      hasBottomSheet: true,
      sheetContent: _RestroomSheetContent(),
    ),
    FilterOption(
      key: 'restroom',
      icon: Icons.wc,
      label: 'Restrooms',
      hasBottomSheet: true,
      sheetContent: _RestroomSheetContent(),
    ),
  ];

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

  ///filter stuff

  void _onFilterTapped(FilterOption filter) {
    setState(() {
      // Tapping the active filter deselects it; tapping a new one selects it
      _activeFilter = (_activeFilter == filter.key) ? null : filter.key;
    });
    // TODO: toggle map markers for _activeFilter
  }

  // Returns the sheet content for the active filter, or null if no sheet.
  Widget? get _activeSheetContent {
    if (_activeFilter == null) return null;
    final filter = _filters.firstWhere(
      (f) => f.key == _activeFilter,
      orElse: () => _filters.first,
    );
    return filter.hasBottomSheet ? filter.sheetContent : null;
  }


  // Widget _buildFilterButton({
  //   required IconData icon,
  //   required VoidCallback onPressed,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 10),
  //     child: RawMaterialButton(
  //       onPressed: onPressed,
  //       fillColor: const ui.Color.fromARGB(255, 223, 239, 255),
  //       shape: const CircleBorder(),
  //       constraints: const BoxConstraints.tightFor(width: 55, height: 55),
  //       elevation: 4,
  //       child: Icon(icon, color: Colors.black87, size: 30),
  //     ),
  //   );
  // }
  Widget _buildFilterButton(FilterOption filter) {
    final bool isActive = _activeFilter == filter.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RawMaterialButton(
        onPressed: () => _onFilterTapped(filter),
        fillColor: isActive ? const Color(0xFFFFCC00) : const ui.Color.fromARGB(255, 243, 250, 255),
        shape: const CircleBorder(),
        constraints: const BoxConstraints.tightFor(width: 55, height: 55),
        elevation: 4,
        child: Icon(filter.icon, color: Colors.black87, size: 30),
      ),
    );
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

      // ── PERSISTENT BOTTOM SHEET ───────────────────────────────────────────
      // Scaffold automatically pushes the bottomNavigationBar up when set.
      bottomSheet: sheetContent != null
          ? _FilterBottomSheet(
              child: sheetContent,
              onClose: () => setState(() => _activeFilter = null),
            )
          : null,

      body: Stack(
        children: [
          MapWidget(
              key: const ValueKey("mapWidget"),
              
              // Map style 
              styleUri: "mapbox://styles/theresa2/cmlbykdmm000s01su4z139emu",
              
              textureView: true, // Better for web/Android
              onMapCreated: _onMapCreated,
          ),

          Positioned(
            top: 20,
            bottom: 380,
            right: 12,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: _filters.map(_buildFilterButton).toList(),
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


//test

///new dart
class _FilterBottomSheet extends StatelessWidget {
  final Widget child;
  final VoidCallback onClose;

  const _FilterBottomSheet({required this.child, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          // Drag handle row with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close, size: 20, color: Colors.black54),
                ),
              ],
            ),
          ),
          // Filter-specific content
          Expanded(child: child),
        ],
      ),
    );
  }
}

///new dart
class _ParkingSheetContent extends StatelessWidget {
  const _ParkingSheetContent();
  @override
  Widget build(BuildContext context) => const _SheetPlaceholder(
        icon: Icons.directions_car,
        label: 'Parking lots & structures',
      );
}

class _StudySheetContent extends StatelessWidget {
  const _StudySheetContent();
  @override
  Widget build(BuildContext context) => const _SheetPlaceholder(
        icon: Icons.menu_book,
        label: 'Study spaces & libraries',
      );
}

class _ChargingSheetContent extends StatelessWidget {
  const _ChargingSheetContent();
  @override
  Widget build(BuildContext context) => const _SheetPlaceholder(
        icon: Icons.electric_bolt,
        label: 'EV & device charging stations',
      );
}

class _RestroomSheetContent extends StatelessWidget {
  const _RestroomSheetContent();
  @override
  Widget build(BuildContext context) => const _SheetPlaceholder(
        icon: Icons.wc,
        label: 'Restroom locations',
      );
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
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }
}