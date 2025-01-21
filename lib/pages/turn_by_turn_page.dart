import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/utils/route_manager.dart';
import 'package:iskompas/utils/location_provider.dart';
import 'package:iskompas/utils/theme_provider.dart';

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
    await _polylineAnnotationManager?.deleteAll();

    if (route.isEmpty) return;

    final polylineOptions = PolylineAnnotationOptions(
      geometry: LineString(
        coordinates: route.map((point) => point.coordinates).toList(),
      ),
      lineWidth: 8.0,
      lineColor: Iskolors.colorYellow.value,
    );
    await _polylineAnnotationManager?.create(polylineOptions);
  }

  void _checkLocationAndUpdateRoute() {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final currentLocation = locationProvider.currentLocation;

    if (currentLocation == null || _remainingRoute.isEmpty) return;

    // Find the closest point on the route to current location
    var closestPointIndex = 0;
    var minDistance = double.infinity;

    // Only check every 3rd point for performance
    for (var i = 0; i < _remainingRoute.length; i += 3) {
      final distance =
          RouteManager.calculateDistance(currentLocation, _remainingRoute[i]);

      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }

    // If we're close enough to the closest point, update the route
    if (minDistance < 0.00015) {
      // About 15 meters
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
    return _instructions[_currentInstructionIndex];
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
                    '${(widget.route.length * 5).round()}m',
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
