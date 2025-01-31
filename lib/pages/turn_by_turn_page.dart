import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_math/flutter_geo_math.dart';
import 'package:iskompas/utils/shared/colors.dart';
import 'package:iskompas/utils/map/route_manager.dart';
import 'package:iskompas/utils/map/location_provider.dart';
import 'package:iskompas/utils/shared/theme_provider.dart';
import 'package:iskompas/utils/shared/color_extension.dart';

class TurnByTurnPage extends StatefulWidget {
  final List<Point> route;

  const TurnByTurnPage({
    super.key,
    required this.route,
  });

  @override
  State<TurnByTurnPage> createState() => _TurnByTurnPageState();
}

class _TurnByTurnPageState extends State<TurnByTurnPage> {
  late MapboxMap _mapboxMap;
  late List<Map<String, dynamic>> _instructions;
  int _currentInstructionIndex = 0;
  PolylineAnnotationManager? _polylineAnnotationManager;
  List<Point> _remainingRoute = [];
  Timer? _locationCheckTimer;
  DateTime? _lastProximityCheckTime;
  double totalDistance = 0;

  @override
  void initState() {
    super.initState();
    _instructions = RouteManager.getRouteInstructions(widget.route);
    _remainingRoute = List.from(widget.route);

    // Start periodic location check
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkLocationAndUpdateRoute();
    });
  }

  @override
  void dispose() {
    _locationCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));

    // Enable location component
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        showAccuracyRing: true,
      ),
    );

    _polylineAnnotationManager =
        await _mapboxMap.annotations.createPolylineAnnotationManager();

    // Set initial theme after map is initialized
    if (mounted) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      updateMapTheme(themeProvider.isDarkMode);
    }

    _drawRoute(_remainingRoute);
  }

  void updateMapTheme(bool isDarkMode) {
    _mapboxMap.style.setStyleImportConfigProperty(
        "basemap", "lightPreset", isDarkMode ? "dusk" : "day");
  }

  Future<void> _drawRoute(List<Point> route) async {
    if (_polylineAnnotationManager == null) return;

    final polylineOptions = PolylineAnnotationOptions(
      geometry: LineString(
        coordinates: route.map((point) => point.coordinates).toList(),
      ),
      lineWidth: 8.0,
      lineColor: Iskolors.colorYellow.toInt(),
    );

    // Simply create a new polyline each time
    await _polylineAnnotationManager!.deleteAll();
    await _polylineAnnotationManager!.create(polylineOptions);
  }

  void _checkLocationAndUpdateRoute() {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final currentLocation = locationProvider.currentLocation;

    if (currentLocation == null || _remainingRoute.isEmpty) return;

    // Update camera position to follow user
    if (_remainingRoute.length > 1) {
      _mapboxMap.easeTo(
        CameraOptions(
          center: currentLocation,
          bearing: RouteManager.calculateBearing(
              _remainingRoute[0], _remainingRoute[1]),
          zoom: 20.0,
          pitch: 65.0,
        ),
        MapAnimationOptions(duration: 1000), // 1 second smooth transition
      );
    }

    // Optimization: Only check proximity every few seconds
    if (_lastProximityCheckTime != null &&
        DateTime.now().difference(_lastProximityCheckTime!) <
            const Duration(seconds: 3)) {
      return;
    }

    // Find the closest point on the route to current location
    var closestPointIndex = 0;
    var minDistance = double.infinity;

    // Performance improvement: Check every 5th point instead of every 3rd
    for (var i = 0; i < _remainingRoute.length; i += 5) {
      final distance =
          RouteManager.calculateDistance(currentLocation, _remainingRoute[i]);

      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }

    // If we're close enough to the closest point, update the route
    // Slightly increased threshold for more stable tracking
    if (minDistance < 0.0002) {
      // About 20 meters
      setState(() {
        // Remove traversed points
        _remainingRoute = _remainingRoute.sublist(closestPointIndex);

        // Update instructions if needed
        _updateInstructions();
      });

      _drawRoute(_remainingRoute);

      // Check if we've reached the destination
      if (_remainingRoute.length <= 2) {
        _showDestinationReachedDialog();
      }

      // Update last proximity check time
      _lastProximityCheckTime = DateTime.now();
    }
  }

  void _updateInstructions() {
    if (_remainingRoute.isNotEmpty) {
      _instructions = RouteManager.getRouteInstructions(_remainingRoute);
      _currentInstructionIndex = 0;
    }
  }

  void _showDestinationReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Destination Reached!'),
        content: const Text('You have arrived at your destination.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to map
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> get currentInstruction {
    if (_instructions.isEmpty) {
      return {'direction': 'Calculating...', 'distance': '0m'};
    }

    // Get current instruction
    final instruction = _instructions[_currentInstructionIndex];

    // Calculate remaining distance (you might need to adjust this based on your RouteManager)
    final remainingDistance = _calculateRemainingDistance();

    return {...instruction, 'distance': '${remainingDistance.round()}m'};
  }

  // Helper method to calculate remaining distance
  double _calculateRemainingDistance() {
    if (_remainingRoute.length < 2) return 0;

    // Implement a method to calculate total distance of remaining route
    double totalDistance = 0;
    for (int i = 1; i < _remainingRoute.length; i++) {
      totalDistance += RouteManager.calculateDistance(
          _remainingRoute[i - 1], _remainingRoute[i]);
    }

    return totalDistance * 1000; // Convert to meters
  }

  int _calculateTotalDistance(List<Point> route) {
    if (route.length < 2) return 0; // Need at least two points

    // Create an instance of FlutterMapMath
    final FlutterMapMath math = FlutterMapMath();

    // Get first and last points in the route
    Point firstPoint = route.first;
    Point lastPoint = route.last;

    // Calculate the distance in meters
    double totalDistance = math.distanceBetween(
      firstPoint.coordinates[1]!.toDouble(),
      firstPoint.coordinates[0]!.toDouble(),
      lastPoint.coordinates[1]!.toDouble(),
      lastPoint.coordinates[0]!.toDouble(),
      "meters",
    );

    return totalDistance.round(); // Return total distance in meters
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            cameraOptions: CameraOptions(
              center: widget.route.first,
              bearing: RouteManager.calculateBearing(
                  widget.route.first, widget.route[1]),
              zoom: 20.0,
              pitch: 65.0,
            ),
            onMapCreated: _initializeMap,
          ),

          // Navigation header
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 30,
              top: MediaQuery.of(context).padding.top + 30,
            ),
            decoration: const BoxDecoration(
              color: Iskolors.colorMaroon,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Iskolors.colorPureWhite),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentInstruction['direction'],
                        style: const TextStyle(
                          color: Iskolors.colorPureWhite,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentInstruction['distance'],
                        style: const TextStyle(
                          color: Iskolors.colorPureWhite,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Iskolors.colorDarkShade,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ! EST TIME CALCULATE LATER
                  const Text(
                    '10 minutes',
                    style: TextStyle(
                        color: Iskolors.colorYellow,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_calculateTotalDistance(widget.route)}m',
                    style: const TextStyle(
                      color: Iskolors.colorGrey,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Iskolors.colorMaroon,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Stop Navigation',
                        style: TextStyle(
                          color: Iskolors.colorPureWhite,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
