import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/utils/pathfinder.dart';
import 'package:iskompas/utils/annotation_listener.dart';
import 'package:iskompas/widgets/search_bar.dart';

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

  @override
  void initState() {
    super.initState();

    // Set pathfindingNodes from widget.mapData
    final nodes = (widget.mapData['nodes'] as List).cast<Point>();
    final facilities = (widget.mapData['facilities'] as List).cast<Point>();
    pathfindingNodes = [...nodes, ...facilities];

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
      if (!mounted) return;
      setState(() {
        startingPoint = Point(
          coordinates: Position(
            userLocation.longitude!,
            userLocation.latitude!,
          ),
        );
      });
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get your location')),
      );
    }
  }

  Future<void> requestLocationAndNavigate(Point destination) async {
    if (startingPoint == null) {
      // Show dialog asking for location permission
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Location Required'),
            content: const Text(
                'Navigation requires access to your location. Would you like to enable location services?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await checkLocationPermission();
                  if (startingPoint != null) {
                    calculateRoute(startingPoint!, destination);
                  }
                },
                child: const Text('Enable Location'),
              ),
            ],
          );
        },
      );
    } else {
      calculateRoute(startingPoint!, destination);
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

  Future<void> addMarkers(List<Point> facilities, {Point? userLocation}) async {
    // Load the image from assets
    final ByteData bytes = await rootBundle.load('assets/icons/pin.png');
    final Uint8List imageData = bytes.buffer.asUint8List();

    for (var facility in facilities) {
      final PointAnnotationOptions markerOptions = PointAnnotationOptions(
        geometry: facility,
        image: imageData,
        iconSize: 0.2,
      );
      _pointAnnotationManager.create(markerOptions);
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
                onPressed: () {
                  Navigator.pop(context); // Close popup
                  // Note: Added guard here
                  if (startingPoint == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Starting location is not set')),
                    );
                    return;
                  }
                  calculateRoute(startingPoint!,
                      geometry); // Geometry represents the selected facility
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
              final facilities =
                  (widget.mapData['facilities'] as List).cast<Point>();
              final lines =
                  (widget.mapData['lines'] as List).cast<List<Point>>();

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

              // Initialize managers and markers
              bool markersAdded = false;
              bool linesAdded = false;

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!markersAdded && facilities.isNotEmpty) {
                  await addMarkers(facilities, userLocation: startingPoint);
                  markersAdded = true;
                }
                if (!linesAdded && lines.isNotEmpty) {
                  for (var line in lines) {
                    addPolyline(line);
                  }
                  linesAdded = true;
                }
              });
            },
          ),
          // Permission check and loading overlay
          if (!isLocationPermissionGranted || startingPoint == null)
            const Center(child: CircularProgressIndicator()),

          // Search bar as the top layer
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 11.0, horizontal: 16.0),
              child: CustomSearchBar(
                hintText: 'Search location...',
                onChanged: (value) {
                  print('Searching for: $value');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
