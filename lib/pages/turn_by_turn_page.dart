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
import 'package:iskompas/widgets/dest_reached_popup.dart';

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

  PolylineAnnotationManager? _polylineAnnotationManager;
  Timer? _locationCheckTimer;
  DateTime? _lastProximityCheckTime;

  List<Point> _remainingRoute = [];
  int _currentInstructionIndex = 0;
  double totalDistance = 0;
  bool _isDestinationReached = false;

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

    await _mapboxMap.style.setStyleImportConfigProperty(
        "basemap", "showPointOfInterestLabels", false);

    await _mapboxMap.style
        .setStyleImportConfigProperty("basemap", "showPlaceLabels", false);

    await _mapboxMap.style
        .setStyleImportConfigProperty("basemap", "showTransitLabels", false);

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
    if (_isDestinationReached) return;

    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final currentLocation = locationProvider.currentLocation;

    if (currentLocation == null || _remainingRoute.isEmpty) return;

    // Update camera position to follow user
    if (_remainingRoute.length > 1) {
      // Retrieve the current camera state to preserve the user-selected pitch
      _mapboxMap.getCameraState().then((currentCameraState) {
        final currentPitch = currentCameraState.pitch;

        _mapboxMap.easeTo(
          CameraOptions(
            center: currentLocation,
            bearing: RouteManager.calculateBearing(
                _remainingRoute[0], _remainingRoute[1]),
            zoom: 20.0,
            pitch:
                currentPitch, // Use the current pitch instead of hardcoding 65.0
          ),
          MapAnimationOptions(duration: 1000), // 1 second smooth transition
        );
      });
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

    // Performance improvement: Check every 2nd point
    for (var i = 0; i < _remainingRoute.length; i += 2) {
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
      if (_remainingRoute.length <= 2 && _calculateRemainingDistance() < 8) {
        // Set the destination reached flag
        _isDestinationReached = true;

        // Cancel the timer to stop further updates
        _locationCheckTimer?.cancel();

        // Show the destination reached popup
        DestinationReachedPopup.show(context).then((_) {
          // Check if the widget is still mounted before using the context
          if (mounted) {
            // After the popup is dismissed, navigate back to the main map page
            Navigator.of(context)
                .pop(_remainingRoute); // Only one pop() call here
          }
        });
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

  Map<String, dynamic> get currentInstruction {
    if (_instructions.isEmpty) {
      return {'direction': 'Desination Reached', 'distance': '0m'};
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

  int _calculateWalkingTime(List<Point> route) {
    int totalDistance = _calculateTotalDistance(route); // in meters
    double walkingSpeed = 0.75; // m/s (approx. 5 km/h)

    int estimatedTimeSeconds = (totalDistance / walkingSpeed).round();
    int estimatedMinutes =
        (estimatedTimeSeconds / 60).round(); // Convert to minutes

    return estimatedMinutes;
  }

  void _toggleMapPitch() {
    _mapboxMap.getCameraState().then((currentOptions) {
      final currentPitch = currentOptions.pitch;
      double newPitch;

      // Cycle through pitch values
      if (currentPitch == 0.0) {
        newPitch = 45.0;
      } else if (currentPitch == 45.0) {
        newPitch = 65.0;
      } else {
        newPitch = 0.0;
      }

      _mapboxMap.easeTo(
        CameraOptions(
          pitch: newPitch,
          center: currentOptions.center,
          zoom: currentOptions.zoom,
          bearing: currentOptions.bearing,
        ),
        MapAnimationOptions(duration: 500),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
          // Map pitch button
          Positioned(
            right: 16,
            bottom: 175,
            child: ElevatedButton(
              onPressed: _toggleMapPitch,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.isDarkMode
                    ? Iskolors.colorDarkShade // Dark mode color
                    : Iskolors.colorWhite, // Light mode color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(18),
              ),
              child: Icon(
                Icons.view_in_ar,
                color: themeProvider.isDarkMode
                    ? Iskolors.colorWhite // Dark mode icon color
                    : Iskolors.colorMaroon, // Light mode icon color
                size: 24,
              ),
            ),
          ),
          // Bottom info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? Iskolors.colorDarkShade // Dark mode color
                    : Iskolors.colorWhite, // Light mode color
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_calculateWalkingTime(widget.route)} minutes',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Iskolors.colorYellow // Dark mode text color
                          : Iskolors.colorMaroon, // Light mode text color
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_calculateTotalDistance(widget.route)}m',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Iskolors.colorGrey // Dark mode text color
                          : Iskolors.colorDarkGrey, // Light mode text color
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_remainingRoute),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: themeProvider.isDarkMode
                            ? Iskolors.colorMaroon // Dark mode button color
                            : Iskolors.colorMaroon, // Light mode button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Stop Navigation',
                        style: TextStyle(
                          color: Iskolors.colorPureWhite, // Button text color
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
