import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/utils/pathfinder.dart';
import 'package:iskompas/utils/annotation_listener.dart';
import 'package:iskompas/widgets/search_bar.dart';
import 'package:iskompas/models/feature_model.dart';
import 'package:iskompas/widgets/category_filter.dart';
import 'package:iskompas/utils/location_provider.dart';
import 'package:iskompas/widgets/navigation_button.dart';
import 'package:iskompas/pages/turn_by_turn_page.dart';
import 'package:iskompas/utils/saved_facilities_service.dart';

class MapPage extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final List<dynamic> facilities;
  const MapPage({
    super.key,
    required this.mapData,
    required this.facilities,
  });

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

  // Map to store annotation mapping
  final Map<String, String> annotationIdMap =
      {}; // Maps dynamic annotation.id to custom id
  final Map<String, Map<String, String>> annotationMetadata =
      {}; // Maps custom id to metadata

  @override
  void initState() {
    super.initState();

    try {
      final facilities = (widget.mapData['facilities'] as List).map((facility) {
        return GeoFeature(
          id: facility['id'] ?? '',
          properties: facility['properties'] ?? {},
          geometry: facility['geometry'] as Point,
        );
      }).toList();

      final nodes = (widget.mapData['nodes'] as List).map((node) {
        return GeoFeature(
          id: node['id'] ?? '',
          properties: node['properties'] ?? {},
          geometry: node['geometry'] as Point,
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
          annotationMetadata: annotationMetadata,
          annotationIdMap: annotationIdMap),
    );
  }

  Future<void> addMarkersFromFeatures(List<GeoFeature> features) async {
    final ByteData bytes = await rootBundle.load('assets/icons/pin.png');
    final Uint8List imageData = bytes.buffer.asUint8List();

    for (final feature in features) {
      final customId = feature.id; // Custom ID from GeoFeature

      final annotationOptions = PointAnnotationOptions(
        geometry: feature.geometry,
        image: imageData,
        iconSize: 0.2,
        textField: feature.properties['name'],
      );

      // Create the annotation
      final annotation =
          await _pointAnnotationManager.create(annotationOptions);

      // Map dynamic annotation.id to custom id
      annotationIdMap[annotation.id] = customId;

      // Store metadata by custom id
      annotationMetadata[customId] = {
        'title': feature.properties['name'].toString(),
        'description': feature.properties['description'].toString(),
      };
    }
  }

  void updateMarkers(String? category) {
    _pointAnnotationManager.deleteAll();
    setState(() {
      selectedCategory = category;
      currentRoute = [];
    });

    if (category != null && categorizedFeatures.containsKey(category)) {
      addMarkersFromFeatures(categorizedFeatures[category]!);
    }
  }

  void showMarkerPopup(Point geometry, String title, String description) {
    bool isSaved = false;

    SavedFacilitiesService.isFacilitySaved(title).then((saved) {
      setState(() {
        isSaved = saved;
      });
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
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
                              onPressed: () async {
                                final Map<String, dynamic> matchingFacility =
                                    widget.facilities.firstWhere(
                                  (facility) =>
                                      (facility['name']?.toLowerCase() ?? '') ==
                                      title.toLowerCase().trim(),
                                  orElse: () => <String, dynamic>{},
                                );

                                if (matchingFacility.isEmpty) {
                                  print(
                                      "No matching facility found in facilities.json for title: $title");
                                  return;
                                }

                                if (isSaved) {
                                  // Pass just the facility name to remove
                                  await SavedFacilitiesService.removeFacility(
                                      title);
                                } else {
                                  // Save the whole facility object
                                  await SavedFacilitiesService.saveFacility(
                                      matchingFacility);
                                }

                                setModalState(() {
                                  isSaved = !isSaved;
                                });
                              },
                              icon: const Icon(Icons.bookmark),
                              color: isSaved
                                  ? Iskolors.colorYellow
                                  : Iskolors.colorPureWhite,
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
                                  if (locationProvider.currentLocation !=
                                      null) {
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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
        });
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
      setState(() {
        currentRoute = [];
      });
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
              pitch: 45.0,
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
          if (currentRoute.isNotEmpty)
            NavigationButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TurnByTurnPage(
                      route: currentRoute,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
