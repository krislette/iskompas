import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iskompas/utils/shared/color_extension.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:iskompas/utils/shared/colors.dart';
import 'package:iskompas/utils/map/pathfinder.dart';
import 'package:iskompas/utils/map/annotation_listener.dart';
import 'package:iskompas/widgets/search_bar.dart';
import 'package:iskompas/models/feature_model.dart';
import 'package:iskompas/widgets/category_filter_list.dart';
import 'package:iskompas/utils/map/location_provider.dart';
import 'package:iskompas/utils/shared/theme_provider.dart';
import 'package:iskompas/widgets/navigation_button.dart';
import 'package:iskompas/widgets/theme_toggle_button.dart';
import 'package:iskompas/pages/turn_by_turn_page.dart';
import 'package:iskompas/pages/map_search_page.dart';
import 'package:iskompas/widgets/marker_popup.dart';
import 'package:iskompas/widgets/no_route_popup.dart';
import 'package:iskompas/utils/map/map_animations.dart';

// Page that displays a map with various facilities and functionalities
class MapPage extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final List<dynamic> facilities;
  final String? focusFacilityName;

  const MapPage({
    super.key,
    required this.mapData,
    required this.facilities,
    this.focusFacilityName,
  });

  @override
  State<MapPage> createState() => MapPageState();
}

// Manages the state and functionality of the map page
class MapPageState extends State<MapPage> {
  // Initialize significant mapbox components
  late MapboxMap _mapboxMap;
  late PointAnnotationManager _pointAnnotationManager;
  late PolylineAnnotationManager _polylineAnnotationManager;

  // Initialize routing objects
  List<Point> currentRoute = [];
  List<Point> pathfindingNodes = [];

  // Pin categories
  String? selectedCategory;
  Map<String, List<GeoFeature>> categorizedFeatures = {};
  List<GeoFeature> allFeatures = [];

  // Map to store annotation mapping
  final Map<String, String> annotationIdMap =
      {}; // Maps dynamic annotation.id to custom id
  final Map<String, Map<String, String>> annotationMetadata =
      {}; // Maps custom id to metadata

  // Used for route caching to avoid reloading everything
  final Map<String, List<Point>> _routeCache = {};

  // Controller for the search button
  final TextEditingController _searchController = TextEditingController();

  // Misc initializations and declarations for map design
  bool isMapInitialized = false;
  GeoFeature? deferredFocusFeature;

  @override
  void initState() {
    super.initState();
    initializeMapData();
  }

  // Initializes map data by extracting faciltiies and nodes
  void initializeMapData() {
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

      // Categorize features into specific types
      categorizedFeatures = {
        'facility': facilities
            .where((f) => f.properties['type'] == 'facility')
            .toList(),
        'faculty':
            facilities.where((f) => f.properties['type'] == 'faculty').toList(),
        'sports':
            facilities.where((f) => f.properties['type'] == 'sports').toList(),
        'hangout':
            facilities.where((f) => f.properties['type'] == 'hangout').toList(),
        'landmark': facilities
            .where((f) => f.properties['type'] == 'landmark')
            .toList(),
        'node': nodes,
      };

      // If there's a specific facility to focus on, find it
      if (widget.focusFacilityName != null) {
        final facilityFeature = facilities.firstWhere(
          (feature) => feature.properties['name'] == widget.focusFacilityName,
          orElse: () => GeoFeature(
            id: '',
            properties: {'name': ''},
            geometry: Point(coordinates: Position(0, 0)),
          ),
        );

        if (facilityFeature.id.isNotEmpty) {
          deferredFocusFeature = facilityFeature;
        }
      }
    } catch (e) {
      throw ('Error in processing mapData: $e');
    }
  }

  // Initializes managers for handling map interactions, annotations, & styles
  Future<void> initializeManagers(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Disable unnecessary labels on the basemap
    await _mapboxMap.style.setStyleImportConfigProperty(
        "basemap", "showPointOfInterestLabels", false);
    await _mapboxMap.style
        .setStyleImportConfigProperty("basemap", "showPlaceLabels", false);
    await _mapboxMap.style
        .setStyleImportConfigProperty("basemap", "showTransitLabels", false);

    // Set bounding box to restrict map view within specific coordinates
    await _mapboxMap.setBounds(
      CameraBoundsOptions(
        bounds: CoordinateBounds(
          // Lang: As is, Lat: higher is tighter; lower is wider
          southwest: Point(coordinates: Position(121.006, 14.594)),
          // Lang: As is, Last: higher is wider; lower is tighter
          northeast: Point(coordinates: Position(121.015, 14.602)),
          infiniteBounds: false,
        ),
      ),
    );

    // Create managers for handling annotations (points and polylines)
    _pointAnnotationManager =
        await _mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager =
        await _mapboxMap.annotations.createPolylineAnnotationManager();

    // Set up a click listener for point annotations to show marker detail
    _pointAnnotationManager.addOnPointAnnotationClickListener(
      CustomPointAnnotationClickListener(
          showMarkerPopup: (geometry, title, description) {
            _showMarkerPopupBottomSheet(geometry, title, description);
          },
          annotationMetadata: annotationMetadata,
          annotationIdMap: annotationIdMap),
    );

    // Apply theme updates based on the current theme mode
    if (mounted) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      updateMapTheme(themeProvider.isDarkMode);
    }

    isMapInitialized = true;

    // Handle deferred focus if a feature was selected before initialization
    if (deferredFocusFeature != null) {
      focusOnLocation(deferredFocusFeature!.geometry);
      addMarkersFromFeatures([deferredFocusFeature!]);
      deferredFocusFeature = null;
    }
  }

  // Separate method to update map theme
  void updateMapTheme(bool isDarkMode) {
    _mapboxMap.style.setStyleImportConfigProperty(
        "basemap", "lightPreset", isDarkMode ? "dusk" : "day");
  }

  // Toggles the map theme between light and dark
  void toggleMapTheme() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.toggleTheme();
    updateMapTheme(themeProvider.isDarkMode);
  }

  // Moves the camera to focus on a specific location
  void focusOnLocation(Point location) {
    if (!isMapInitialized) {
      return;
    }

    _mapboxMap.flyTo(
      CameraOptions(
        center: location,
        zoom: 18.0,
      ),
      MapAnimationOptions(duration: 2000),
    );
  }

  // Adds markers to the map based on a list of geographic features
  Future<void> addMarkersFromFeatures(List<GeoFeature> features) async {
    // Cache to store loaded images for marker types
    final Map<String, Uint8List> imageCache = {};

    // Loads an image corresponding to the feature type, caching it if necessary
    Future<Uint8List> getImageForType(String type) async {
      if (!imageCache.containsKey(type)) {
        final ByteData bytes =
            await rootBundle.load('assets/icons/$type-pin.png');
        imageCache[type] = bytes.buffer.asUint8List();
      }
      return imageCache[type]!;
    }

    // Generate annotation options for each feature
    final List<PointAnnotationOptions> annotationOptionsList =
        await Future.wait(features.map((feature) async {
      final String type = feature.properties['type'].toString().toLowerCase();
      final Uint8List imageData = await getImageForType(type);

      return PointAnnotationOptions(
        geometry: feature.geometry,
        image: imageData,
        iconSize: 1,
      );
    }));

    // Create all annotations at once and filter out null values
    final List<PointAnnotation> annotations =
        (await _pointAnnotationManager.createMulti(annotationOptionsList))
            .where((annotation) => annotation != null)
            .cast<PointAnnotation>()
            .toList();

    // Map the created annotations to their custom IDs and store metadata
    for (int i = 0; i < annotations.length; i++) {
      final customId = features[i].id;
      annotationIdMap[annotations[i].id] = customId;

      annotationMetadata[customId] = {
        'title': features[i].properties['name'].toString(),
        'description': features[i].properties['description'].toString(),
      };
    }
  }

  // Updates markers on the map based on selected category
  void updateMarkers(String? category) {
    _pointAnnotationManager.deleteAll();
    setState(() {
      selectedCategory = category;
      currentRoute = [];
    });

    // Add markers for the selected category and adjust the map view
    if (category != null && categorizedFeatures.containsKey(category)) {
      final features = categorizedFeatures[category]!;
      addMarkersFromFeatures(categorizedFeatures[category]!);
      MapAnimations.fitMarkersInView(_mapboxMap, features);
    }
  }

  // Displays a popup bottom sheet for marker details and navigation
  void _showMarkerPopupBottomSheet(
      Point geometry, String title, String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return MarkerPopup(
          geometry: geometry,
          title: title,
          description: description,
          facilities: widget.facilities,
          onNavigate: calculateRoute,
        );
      },
    );
  }

  // Adds a polyline on the map representing a route
  void addPolyline(List<Point> route) {
    // Reduce route complexity
    final simplifiedRoute = _simplifyRoute(route);

    final polylineOptions = PolylineAnnotationOptions(
        geometry: LineString(
          coordinates:
              simplifiedRoute.map((point) => point.coordinates).toList(),
        ),
        lineWidth: 8.0,
        lineColor: Iskolors.colorYellow.toInt());

    _polylineAnnotationManager.create(polylineOptions);
  }

  // Simplfies the route by removing unnecessary points while preserving shape
  List<Point> _simplifyRoute(List<Point> route) {
    if (route.length < 3) return route;

    const double minDistance = 0.00001;
    final simplified = <Point>[route.first];

    for (int i = 1; i < route.length - 1; i++) {
      final prev = route[i - 1];
      final curr = route[i];
      final next = route[i + 1];

      final dx1 = curr.coordinates[0]! - prev.coordinates[0]!;
      final dy1 = curr.coordinates[1]! - prev.coordinates[1]!;
      final dx2 = next.coordinates[0]! - curr.coordinates[0]!;
      final dy2 = next.coordinates[1]! - curr.coordinates[1]!;

      // Retain points that contribute significantly to route shape
      if (dx1 * dx1 + dy1 * dy1 > minDistance * minDistance ||
          dx2 * dx2 + dy2 * dy2 > minDistance * minDistance) {
        simplified.add(curr);
      }
    }

    simplified.add(route.last);
    return simplified;
  }

  // Clears all polylines from the map
  void clearPolylines() {
    _polylineAnnotationManager.deleteAll();
  }

  // Calculates the shortest route between two points and displays it on the map
  void calculateRoute(Point from, Point to) {
    clearPolylines();

    final String routeKey = '${from.hashCode}-${to.hashCode}';
    if (_routeCache.containsKey(routeKey)) {
      setState(() {
        currentRoute = _routeCache[routeKey]!;
      });
      addPolyline(_routeCache[routeKey]!);
      return;
    }

    final route = Pathfinder.findShortestPath(from, to, pathfindingNodes);

    if (route.isNotEmpty) {
      setState(() {
        currentRoute = route;
      });
      addPolyline(route);
      _routeCache[routeKey] = route;
      MapAnimations.fitRouteInView(_mapboxMap, route);
    } else {
      setState(() {
        currentRoute = [];
      });
      NoRoutePopup.show(context);
    }
  }

  // Clears the search input field
  void clearSearch() {
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isNightMode = themeProvider.isDarkMode;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                    controller: _searchController,
                    hintText: 'Search location...',
                    isDarkMode: isNightMode,
                    onTap: () async {
                      final selectedFacility = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SearchPage(facilities: widget.facilities)));

                      if (selectedFacility != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              selectedCategory = null;
                            });
                          }
                        });

                        // Find the matching facility from widget.mapData to get its geometry
                        final fullFacilityData =
                            (widget.mapData['facilities'] as List).firstWhere(
                          (facility) =>
                              facility['properties']['name'] ==
                              selectedFacility['name'],
                          orElse: () => Map<String, dynamic>.from(
                              {}), // Fixed orElse return type
                        );

                        if (fullFacilityData.isNotEmpty) {
                          // Check if we found a matching facility
                          // Create a GeoFeature for the selected facility
                          final facilityFeature = GeoFeature(
                            id: fullFacilityData['id'] ?? '',
                            properties: {
                              'name': selectedFacility['name'],
                              'description':
                                  selectedFacility['description'] ?? '',
                              'type': 'facility',
                            },
                            geometry: fullFacilityData['geometry'],
                          );

                          // Clear existing markers and route
                          _pointAnnotationManager.deleteAll();
                          clearPolylines();

                          // Add marker for the selected facility
                          addMarkersFromFeatures([facilityFeature]);

                          // Focus the map on the facility location
                          focusOnLocation(fullFacilityData['geometry']);
                        }
                      }
                    },
                  ),
                ),
                // Category filters
                CategoryFiltersList(
                  selectedCategory: selectedCategory,
                  isDarkMode: isNightMode,
                  onCategorySelected: updateMarkers,
                  clearPolylines: clearPolylines,
                ),
              ],
            ),
          ),
          // Turn by turn navigation button
          if (currentRoute.isNotEmpty)
            NavigationButton(
              onPressed: () async {
                // Navigate to the TurnByTurnPage and wait for the result
                final remainingRoute = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TurnByTurnPage(
                      route: currentRoute,
                    ),
                  ),
                );

                // If a remaining route is returned, update the polyline
                if (remainingRoute != null && remainingRoute is List<Point>) {
                  setState(() {
                    currentRoute = remainingRoute;
                  });
                  clearPolylines();
                  addPolyline(currentRoute);
                }
              },
            ),
          // Theme Toggle Button
          ThemeToggleButton(
            onPressed: toggleMapTheme,
            isNightMode: isNightMode,
          ),
        ],
      ),
    );
  }
}
