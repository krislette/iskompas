import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/utils/pathfinder.dart';
import 'package:iskompas/utils/annotation_listener.dart';
import 'package:iskompas/widgets/search_bar.dart';
import 'package:iskompas/utils/feature_model.dart';
import 'package:iskompas/widgets/category_filter.dart';
import 'package:iskompas/utils/location_provider.dart';

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

  void showMarkerPopup(Point geometry, String title, String description) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: SizedBox(
                height: 150,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Iskolors.colorDarkShade,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Spacer(),
                    // Buttons row
                    Row(
                      children: [
                        // Save button
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Iskolors.colorDarkShade,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Add save functionality LATER!!!
                            },
                            icon: const Icon(Icons.bookmark),
                            color: Iskolors.colorYellow,
                            iconSize: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Navigate button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final locationProvider =
                                  Provider.of<LocationProvider>(context,
                                      listen: false);
                              if (locationProvider.currentLocation == null) {
                                await locationProvider
                                    .checkLocationPermission();
                                if (locationProvider.currentLocation != null) {
                                  calculateRoute(
                                      locationProvider.currentLocation!,
                                      geometry);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Unable to get your location')),
                                  );
                                }
                              } else {
                                calculateRoute(
                                    locationProvider.currentLocation!,
                                    geometry);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              backgroundColor: Iskolors.colorMaroon,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Navigate",
                              style: TextStyle(
                                color: Iskolors.colorPureWhite,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Location icon at the top
            Positioned(
              top: -30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Iskolors.colorPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pin_drop,
                    color: Iskolors.colorPureWhite,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
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
    final locationProvider = Provider.of<LocationProvider>(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Map as the bottom layer
          MapWidget(
            cameraOptions: CameraOptions(
              center: locationProvider.currentLocation ??
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
