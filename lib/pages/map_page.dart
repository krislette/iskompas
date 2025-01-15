import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/utils/pathfinder.dart';
import 'package:iskompas/utils/annotation_listener.dart';
import 'package:iskompas/widgets/search_bar.dart';
import 'package:iskompas/utils/feature_model.dart';
import 'package:iskompas/widgets/category_filter.dart';

class MapPage extends StatefulWidget {
  final Map<String, dynamic> mapData;
  const MapPage({super.key, required this.mapData});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late MapboxMap _mapboxMap;
  late PointAnnotationManager _pointAnnotationManager;
  late PolylineAnnotationManager _polylineAnnotationManager;

  // final datasetLink = dotenv.env['DATASET_LINK']!;
  final Location location = Location();
  Point? startingPoint;
  bool isLocationPermissionGranted = false;
  List<Point> currentRoute = []; // Route for navigation
  List<Point> pathfindingNodes = []; // Nodes for pathfinding

  // Pin categories
  String? selectedCategory;
  Map<String, List<GeoFeature>> categorizedFeatures = {};
  List<GeoFeature> allFeatures = [];

  @override
  void initState() {
    super.initState();

    try {
      // Retrieve facilities and nodes
      final facilities =
          (widget.mapData['facilities'] as List<Point>).map((point) {
        return GeoFeature(
          id: '', // Update this later! (If an ID is required in the future)
          properties: {}, // Give default or empty properties
          geometry: point,
        );
      }).toList();

      final nodes = (widget.mapData['nodes'] as List<Point>).map((point) {
        return GeoFeature(
          id: '',
          properties: {},
          geometry: point,
        );
      }).toList();

      // Combine nodes and facilities into pathfindingNodes
      pathfindingNodes =
          [...facilities, ...nodes].map((feature) => feature.geometry).toList();

      // Categorize features
      categorizedFeatures = {
        'facility': facilities,
        'node': nodes,
      };
    } catch (e) {
      throw ('Error in processing mapData: $e');
    }

    checkLocationPermission();
  }

  Future<void> checkLocationPermission() async {
    final permissionStatus = await Permission.locationWhenInUse.request();
    setState(() {
      isLocationPermissionGranted = permissionStatus.isGranted;
    });

    if (isLocationPermissionGranted) {
      await getUserLocation();
    }
  }

  Future<void> getUserLocation() async {
    try {
      final userLocation = await location.getLocation();
      setState(() {
        startingPoint = Point(
          coordinates: Position(
            userLocation.longitude!,
            userLocation.latitude!,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get your location')),
      );
    }
  }

  Future<void> initializeManagers(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    _pointAnnotationManager =
        await _mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager =
        await _mapboxMap.annotations.createPolylineAnnotationManager();

    _pointAnnotationManager.addOnPointAnnotationClickListener(
      CustomPointAnnotationClickListener(
        showMarkerPopup: showMarkerPopup,
      ),
    );
  }

  Future<void> addMarkersFromFeatures(List<GeoFeature> features) async {
    final ByteData bytes = await rootBundle.load('assets/icons/pin.png');
    final Uint8List imageData = bytes.buffer.asUint8List();

    final markerOptionsList = features.map((feature) {
      return PointAnnotationOptions(
          geometry: feature.geometry, image: imageData, iconSize: 0.2);
    }).toList();

    await _pointAnnotationManager.createMulti(markerOptionsList);
  }

  void updateMarkers(String? category) {
    _pointAnnotationManager.deleteAll();
    setState(() {
      selectedCategory = category;
    });

    if (category != null && categorizedFeatures.containsKey(category)) {
      addMarkersFromFeatures(categorizedFeatures[category]!);
    }
  }

  void showMarkerPopup(Point geometry, String description) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                description,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close the popup

                  // Check if starting point is null (no location set)
                  if (startingPoint == null) {
                    // Ask for location permission again
                    await checkLocationPermission();

                    // If permission granted, get user location
                    if (startingPoint != null) {
                      calculateRoute(
                          startingPoint!, geometry); // Proceed with routing
                    } else {
                      // Show a snackbar or alert if no location is still available
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Unable to get your location')),
                        );
                      });
                    }
                  } else {
                    // Proceed with routing if location is already available
                    calculateRoute(startingPoint!, geometry);
                  }
                },
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25), // Capsule shape
                    ),
                    backgroundColor: Iskolors.colorMaroon,
                    foregroundColor: Iskolors.colorWhite),
                child: const Text(
                  "Navigate",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void addPolyline(List<Point> route) {
    final polylineOptions = PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: route.map((point) => point.coordinates).toList(),
        ),
        lineWidth: 8.0,
        lineColor: Iskolors.colorYellow.value);
    _polylineAnnotationManager.create(polylineOptions);
  }

  void clearPolylines() {
    _polylineAnnotationManager.deleteAll();
  }

  void calculateRoute(Point from, Point to) {
    // Clear existing polyline before adding a new one
    clearPolylines();

    final route = PathFinder.findShortestPath(from, to, pathfindingNodes);
    if (route.isNotEmpty) {
      setState(() {
        currentRoute = route;
      });
      print("Route found: $route");
      addPolyline(route);
    } else {
      print("No route found from $from to $to");
      clearPolylines();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No route found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Map as the bottom layer
          MapWidget(
            cameraOptions: CameraOptions(
              center: startingPoint ??
                  Point(
                    coordinates:
                        Position(121.01067214130658, 14.597708356992062),
                  ),
              zoom: 18.0,
              pitch: 45,
            ),
            onMapCreated: (mapboxMap) async {
              mapboxMap.scaleBar
                  .updateSettings(ScaleBarSettings(enabled: false));
              mapboxMap.compass.updateSettings(CompassSettings(enabled: false));

              // Enable the location component
              await mapboxMap.location.updateSettings(
                LocationComponentSettings(
                  enabled: true,
                  pulsingEnabled: true,
                  puckBearingEnabled: true,
                  showAccuracyRing: true,
                ),
              );

              await initializeManagers(mapboxMap);
            },
          ),

          // Permission check and loading overlay
          if (!isLocationPermissionGranted || startingPoint == null)
            const Center(child: CircularProgressIndicator()),

          // Search bar as the top layer
          SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 11.0, horizontal: 16.0),
                  child: CustomSearchBar(
                    hintText: 'Search location...',
                    isDarkMode: false,
                    onChanged: (value) {
                      print('Searching for: $value');
                    },
                  ),
                ),

                // Category filters
                SizedBox(
                  height: 40,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      CategoryFilter(
                          icon: Icons.image,
                          label: 'Facilities',
                          isSelected: selectedCategory == 'facility',
                          onTap: () {
                            clearPolylines();
                            updateMarkers(selectedCategory == 'facility'
                                ? null
                                : 'facility');
                          }),
                      CategoryFilter(
                        icon: Icons.bathroom,
                        label: 'Bathrooms',
                        isSelected: selectedCategory == 'bathroom',
                        onTap: () {
                          clearPolylines();
                          updateMarkers(selectedCategory == 'bathroom'
                              ? null
                              : 'bathroom');
                        },
                      ),
                      // To be added: Stalls, Labs, etc.
                    ],
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
