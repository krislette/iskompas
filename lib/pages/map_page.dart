import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iskompas/utils/color_extension.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/utils/pathfinder.dart';
import 'package:iskompas/utils/annotation_listener.dart';
import 'package:iskompas/widgets/search_bar.dart';
import 'package:iskompas/models/feature_model.dart';
import 'package:iskompas/widgets/category_filter_list.dart';
import 'package:iskompas/utils/location_provider.dart';
import 'package:iskompas/utils/theme_provider.dart';
import 'package:iskompas/widgets/navigation_button.dart';
import 'package:iskompas/widgets/theme_toggle_button.dart';
import 'package:iskompas/pages/turn_by_turn_page.dart';
import 'package:iskompas/pages/map_search_page.dart';
import 'package:iskompas/widgets/marker_popup.dart';
import 'package:iskompas/widgets/no_route_popup.dart';

class MapPage extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final List<dynamic> facilities;
  final String? focusFacilityName;

  const MapPage(
      {super.key,
      required this.mapData,
      required this.facilities,
      this.focusFacilityName});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
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

  final Map<String, List<Point>> _routeCache = {};

  final TextEditingController _searchController = TextEditingController();

  bool isMapInitialized = false;
  GeoFeature? deferredFocusFeature;

  @override
  void initState() {
    super.initState();
    initializeMapData();
  }

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

      // Categorize features
      categorizedFeatures = {
        'facility': facilities
            .where((f) => f.properties['type'] == 'facility')
            .toList(),
        'faculty':
            facilities.where((f) => f.properties['type'] == 'faculty').toList(),
        'sports':
            facilities.where((f) => f.properties['type'] == 'sports').toList(),
        'bathroom': facilities
            .where((f) => f.properties['type'] == 'bathroom')
            .toList(),
        'hangout':
            facilities.where((f) => f.properties['type'] == 'hangout').toList(),
        'landmark': facilities
            .where((f) => f.properties['type'] == 'landmark')
            .toList(),
        'node': nodes,
      };

      // If there's a facility to focus on
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
          deferredFocusFeature = facilityFeature; // Save for later
        }
      }
    } catch (e) {
      throw ('Error in processing mapData: $e');
    }
  }

  Future<void> initializeManagers(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    await _mapboxMap.style.setStyleImportConfigProperty(
        "basemap", "showPointOfInterestLabels", false);

    await _mapboxMap.style
        .setStyleImportConfigProperty("basemap", "showPlaceLabels", false);

    await _mapboxMap.style
        .setStyleImportConfigProperty("basemap", "showTransitLabels", false);

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

    _pointAnnotationManager =
        await _mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager =
        await _mapboxMap.annotations.createPolylineAnnotationManager();

    _pointAnnotationManager.addOnPointAnnotationClickListener(
      CustomPointAnnotationClickListener(
          showMarkerPopup: (geometry, title, description) {
            _showMarkerPopupBottomSheet(geometry, title, description);
          },
          annotationMetadata: annotationMetadata,
          annotationIdMap: annotationIdMap),
    );

    if (mounted) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      updateMapTheme(themeProvider.isDarkMode);
    }

    isMapInitialized = true;

    // Perform deferred focus and marker addition
    if (deferredFocusFeature != null) {
      focusOnLocation(deferredFocusFeature!.geometry);
      addMarkersFromFeatures([deferredFocusFeature!]);
      deferredFocusFeature = null; // Clear deferred action
    }
  }

  // Separate method to update map theme
  void updateMapTheme(bool isDarkMode) {
    _mapboxMap.style.setStyleImportConfigProperty(
        "basemap", "lightPreset", isDarkMode ? "dusk" : "day");
  }

  void toggleMapTheme() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.toggleTheme();
    updateMapTheme(themeProvider.isDarkMode);
  }

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

  Future<void> addMarkersFromFeatures(List<GeoFeature> features) async {
    // Cache to store loaded images
    final Map<String, Uint8List> imageCache = {};

    // Load image for each feature
    Future<Uint8List> getImageForType(String type) async {
      if (!imageCache.containsKey(type)) {
        final ByteData bytes =
            await rootBundle.load('assets/icons/$type-pin.png');
        imageCache[type] = bytes.buffer.asUint8List();
      }
      return imageCache[type]!;
    }

    // Create a list to hold all annotation options
    final List<PointAnnotationOptions> annotationOptionsList =
        await Future.wait(features.map((feature) async {
      final String type = feature.properties['type'].toString().toLowerCase();
      final Uint8List imageData = await getImageForType(type);

      return PointAnnotationOptions(
        geometry: feature.geometry,
        image: imageData,
        iconSize: 1,
        // textField: feature.properties['name'],
        // textOffset: [0, -2],
        // textSize: 12
      );
    }));

    // Create all annotations at once
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

  void updateMarkers(String? category) {
    _pointAnnotationManager.deleteAll();
    setState(() {
      selectedCategory = category;
      currentRoute = [];
    });

    if (category != null && categorizedFeatures.containsKey(category)) {
      final features = categorizedFeatures[category]!;
      addMarkersFromFeatures(categorizedFeatures[category]!);
      _fitMarkersInView(features);
    }
  }

  void _fitMarkersInView(List<GeoFeature> features) {
    if (features.isEmpty) return;

    // Find the bounds of all markers
    double minLng = features.first.geometry.coordinates[0]!.toDouble();
    double maxLng = features.first.geometry.coordinates[0]!.toDouble();
    double minLat = features.first.geometry.coordinates[1]!.toDouble();
    double maxLat = features.first.geometry.coordinates[1]!.toDouble();

    for (var feature in features) {
      final lng = feature.geometry.coordinates[0]!.toDouble();
      final lat = feature.geometry.coordinates[1]!.toDouble();

      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
    }

    // Add less padding to the bounds (adjust the 0.3 multiplier for tighter zoom)
    final lngPadding = (maxLng - minLng) * 0.4; // Reduce padding
    final latPadding = (maxLat - minLat) * 0.4; // Reduce padding

    minLng -= lngPadding;
    maxLng += lngPadding;
    minLat -= latPadding;
    maxLat += latPadding;

    // Calculate center point
    final centerLng = (minLng + maxLng) / 2;
    final centerLat = (minLat + maxLat) / 2;

    // Calculate appropriate zoom level based on bounds
    final lngSpan = (maxLng - minLng).abs();
    final latSpan = (maxLat - minLat).abs();

    // Base zoom level on the larger span
    final zoomLevel = max(
        16.0,
        -log(max(lngSpan, latSpan)) *
            3.0); // Adjust zoom multiplier for tighter zoom

    _mapboxMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: zoomLevel,
        bearing: 0.0,
        pitch: 45.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

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

  void addPolyline(List<Point> route) {
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

      if (dx1 * dx1 + dy1 * dy1 > minDistance * minDistance ||
          dx2 * dx2 + dy2 * dy2 > minDistance * minDistance) {
        simplified.add(curr);
      }
    }

    simplified.add(route.last);
    return simplified;
  }

  void clearPolylines() {
    _polylineAnnotationManager.deleteAll();
  }

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
      _fitRouteInView(route);
    } else {
      setState(() {
        currentRoute = [];
      });
      NoRoutePopup.show(context);
    }
  }

  void _fitRouteInView(List<Point> route) {
    if (route.isEmpty) return;

    // Find the bounds of the route
    double minLng = route.first.coordinates[0]!.toDouble();
    double maxLng = route.first.coordinates[0]!.toDouble();
    double minLat = route.first.coordinates[1]!.toDouble();
    double maxLat = route.first.coordinates[1]!.toDouble();

    for (var point in route) {
      final lng = point.coordinates[0]!.toDouble();
      final lat = point.coordinates[1]!.toDouble();

      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
    }

    // Calculate the route's span
    final lngSpan = (maxLng - minLng).abs();
    final latSpan = (maxLat - minLat).abs();

    // Force a closer zoom based on route length
    double zoomLevel;
    final routeLength = route.length;

    if (routeLength <= 2) {
      zoomLevel = 19.0; // Very close for direct routes
    } else if (routeLength <= 4) {
      zoomLevel = 18.5;
    } else if (routeLength <= 6) {
      zoomLevel = 18.0;
    } else if (routeLength <= 10) {
      zoomLevel = 17.5;
    } else {
      // For longer routes, calculate based on span but ensure it's not too far out
      zoomLevel = max(17.0, -log(max(lngSpan, latSpan)) * 2.5);
    }

    // Calculate center point
    final centerLng = (minLng + maxLng) / 2;
    final centerLat = (minLat + maxLat) / 2;

    // Get current camera position
    _mapboxMap.getCameraState().then((currentCamera) {
      // Force the zoom change by first zooming out slightly
      final initialZoom = currentCamera.zoom;

      // Two-step animation for more dramatic effect
      // First zoom out slightly if we're already zoomed in
      if (initialZoom > zoomLevel - 1) {
        _mapboxMap
            .flyTo(
          CameraOptions(
            center: Point(coordinates: Position(centerLng, centerLat)),
            zoom: zoomLevel - 1,
            bearing: 0.0,
            pitch: 45.0,
          ),
          MapAnimationOptions(duration: 500),
        )
            .then((_) {
          // Then zoom in to the final position
          _mapboxMap.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(centerLng, centerLat)),
              zoom: zoomLevel,
              bearing: 0.0,
              pitch: 45.0,
            ),
            MapAnimationOptions(duration: 500),
          );
        });
      } else {
        // Direct animation if we're already zoomed out
        _mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(centerLng, centerLat)),
            zoom: zoomLevel,
            bearing: 0.0,
            pitch: 45.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    });
  }

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
