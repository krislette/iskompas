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

// TurnByTurnPage class for displaying route turn-by-turn instructions
class TurnByTurnPage extends StatefulWidget {
  final List<Point> route;

  const TurnByTurnPage({
    super.key,
    required this.route,
  });

  @override
  State<TurnByTurnPage> createState() => _TurnByTurnPageState();
}

// _TurnByTurnPageState handles the logic for turn-by-turn navigation
class _TurnByTurnPageState extends State<TurnByTurnPage> {
  // Initialize map and instructions
  late MapboxMap _mapboxMap;
  late List<Map<String, dynamic>> _instructions;

  PolylineAnnotationManager? _polylineAnnotationManager;
  Timer? _locationCheckTimer;
  DateTime? _lastProximityCheckTime;

  List<Point> _remainingRoute = [];
  int _currentInstructionIndex = 0;
  double totalDistance = 0;
  bool _isDestinationReached = false;

  Point? _previousLocation;

  // About 0.5 meters
  static const double _minimumMovementThreshold = 0.000005;

  @override
  void initState() {
    super.initState();
    _instructions = RouteManager.getRouteInstructions(widget.route);
    _remainingRoute = List.from(widget.route);

    // Start periodic location check
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkLocationAndUpdateRoute();
    });
  }

  @override
  void dispose() {
    // Cancel the periodic location check timer when the widget is disposed
    _locationCheckTimer?.cancel();
    super.dispose();
  }

  // Initialize map features and settings
  Future<void> _initializeMap(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Disable scale bar and compass on the map
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));

    // Disable various labels on the map (POI, place, transit)
    await _mapboxMap.style.setStyleImportConfigProperty(
        "basemap", "showPointOfInterestLabels", false);
    await _mapboxMap.style
        .setStyleImportConfigProperty("basemap", "showPlaceLabels", false);
    await _mapboxMap.style
        .setStyleImportConfigProperty("basemap", "showTransitLabels", false);

    // Enable the location component for displaying the user's location
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        showAccuracyRing: true,
      ),
    );

    // Initialize polyline annotation manager for route visualization
    _polylineAnnotationManager =
        await _mapboxMap.annotations.createPolylineAnnotationManager();

    // Set initial theme after map is initialized
    if (mounted) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      updateMapTheme(themeProvider.isDarkMode);
    }

    // Draw the initial route on the map
    _drawRoute(_remainingRoute);
  }

  // Update theme based on prefs
  void updateMapTheme(bool isDarkMode) {
    _mapboxMap.style.setStyleImportConfigProperty(
        "basemap", "lightPreset", isDarkMode ? "dusk" : "day");
  }

  // Draws the route as a polyline on the map
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

  // Helper method to check if significant movement occurred
  bool _hasSignificantMovement(Point currentLocation) {
    if (_previousLocation == null) {
      _previousLocation = currentLocation;
      return true;
    }

    // Calculate the distance between the previous and current location
    final distance = RouteManager.calculateDistance(
      _previousLocation!,
      currentLocation,
    );

    // If the user moves, return true
    if (distance > _minimumMovementThreshold) {
      _previousLocation = currentLocation;
      return true;
    }

    // If the movement is not significant, return false
    return false;
  }

  // Checks if the destination is reached, then updates the route and camera
  // based on the current location
  void _checkLocationAndUpdateRoute() {
    if (_isDestinationReached) return;

    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final currentLocation = locationProvider.currentLocation;

    if (currentLocation == null || _remainingRoute.isEmpty) return;

    // Check if there's significant movement before proceeding with updates
    if (!_hasSignificantMovement(currentLocation)) {
      // If no significant movement, only update camera position
      if (_remainingRoute.length > 1) {
        _mapboxMap.getCameraState().then((currentCameraState) {
          final currentPitch = currentCameraState.pitch;
          _mapboxMap.easeTo(
            CameraOptions(
              center: currentLocation,
              bearing: RouteManager.calculateBearing(
                  _remainingRoute[0], _remainingRoute[1]),
              zoom: 20.0,
              pitch: currentPitch,
            ),
            MapAnimationOptions(duration: 1000),
          );
        });
      }
      return;
    }

    // Only proceed with route updates if a movement is detected
    if (_lastProximityCheckTime != null &&
        DateTime.now().difference(_lastProximityCheckTime!) <
            const Duration(seconds: 1)) {
      return;
    }

    // Find the closest point on the route to current location
    var closestPointIndex = 0;
    var minDistance = double.infinity;

    // Performance improvement: Check every 1st point
    for (var i = 0; i < _remainingRoute.length; i += 1) {
      final distance =
          RouteManager.calculateDistance(currentLocation, _remainingRoute[i]);

      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }

    // If user is close enough to the closest point, update the route
    // Slightly increased threshold for more stable tracking (around 15 meters)
    if (minDistance < 0.00015) {
      setState(() {
        // Remove traversed points
        _remainingRoute = _remainingRoute.sublist(closestPointIndex);

        // Update instructions if needed
        _updateInstructions();
      });

      _drawRoute(_remainingRoute);

      // Check if user has reached the destination
      if (_remainingRoute.length <= 2 && _calculateRemainingDistance() < 8) {
        // Set the destination reached flag
        _isDestinationReached = true;

        // Cancel the timer to stop further updates
        _locationCheckTimer?.cancel();

        // Show the destination reached popup
        DestinationReachedPopup.show(context).then((_) {
          if (mounted) {
            // After the popup is dismissed, navigate back to the main map page
            Navigator.of(context).pop(_remainingRoute);
          }
        });
      }

      // Update last proximity check time
      _lastProximityCheckTime = DateTime.now();
    }
  }

  // Method to update route instructions based on remaining route
  void _updateInstructions() {
    if (_remainingRoute.isNotEmpty) {
      // Refresh instructions based on the updated remaining route
      _instructions = RouteManager.getRouteInstructions(_remainingRoute);
      _currentInstructionIndex = 0;
    }
  }

  // Getter to retrieve the current instruction with the remaining distance
  Map<String, dynamic> get currentInstruction {
    if (_instructions.isEmpty) {
      return {'direction': 'Desination Reached', 'distance': '0m'};
    }

    // Get current instruction from the list
    final instruction = _instructions[_currentInstructionIndex];

    // Calculate remaining distance
    final remainingDistance = _calculateRemainingDistance();

    return {...instruction, 'distance': '${remainingDistance.round()}m'};
  }

  // Helper method to calculate remaining distance
  double _calculateRemainingDistance() {
    if (_remainingRoute.length < 2) return 0;

    // Calculate the total distance of the remaining route by
    // summing up distances between consecutive points
    double totalDistance = 0;
    for (int i = 1; i < _remainingRoute.length; i++) {
      totalDistance += RouteManager.calculateDistance(
          _remainingRoute[i - 1], _remainingRoute[i]);
    }

    // Convert to meters
    return totalDistance * 1000;
  }

  // Calculates the total distance of the route in meters
  int _calculateTotalDistance(List<Point> route) {
    // Need at least two points
    if (route.length < 2) return 0;

    // Create an instance of FlutterMapMath
    final FlutterMapMath math = FlutterMapMath();

    // Get first and last points in the route
    Point firstPoint = route.first;
    Point lastPoint = route.last;

    // Calculate the distance between the first and last points
    double totalDistance = math.distanceBetween(
      firstPoint.coordinates[1]!.toDouble(),
      firstPoint.coordinates[0]!.toDouble(),
      lastPoint.coordinates[1]!.toDouble(),
      lastPoint.coordinates[0]!.toDouble(),
      "meters",
    );

    return totalDistance.round();
  }

  // Calculates the estimated walking time for the route
  int _calculateWalkingTime(List<Point> route) {
    // Total distance in meters
    int totalDistance = _calculateTotalDistance(route);
    // Walking speed in m/s
    double walkingSpeed = 0.75;

    int estimatedTimeSeconds = (totalDistance / walkingSpeed).round();
    int estimatedMinutes = (estimatedTimeSeconds / 60).round();

    return estimatedMinutes;
  }

  // Toggles the map's pitch between 0, 45, and 65 degrees
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

      // Apply the new pitch value with a smooth animation
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

    // Builds the UI for the entire turn by turn page
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
                  onPressed: () => Navigator.of(context).pop(_remainingRoute),
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
                    ? Iskolors.colorDarkShade
                    : Iskolors.colorWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(18),
              ),
              child: Icon(
                Icons.view_in_ar,
                color: themeProvider.isDarkMode
                    ? Iskolors.colorWhite
                    : Iskolors.colorMaroon,
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
                    ? Iskolors.colorDarkShade
                    : Iskolors.colorWhite,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_calculateWalkingTime(widget.route)} ${_calculateWalkingTime(widget.route) == 1 ? "minute" : "minutes"}',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Iskolors.colorYellow
                          : Iskolors.colorMaroon,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_calculateTotalDistance(widget.route)}m',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Iskolors.colorGrey
                          : Iskolors.colorDarkGrey,
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
                            ? Iskolors.colorMaroon
                            : Iskolors.colorMaroon,
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
