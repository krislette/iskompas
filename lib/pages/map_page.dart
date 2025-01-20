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
import 'package:iskompas/widgets/marker_popup.dart';

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

  bool isMapInitialized = false;
  GeoFeature? deferredFocusFeature;

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

      // If there's a facility to focus on
      if (widget.focusFacilityName != null) {
        final facilityFeature = facilities.firstWhere(
          (feature) =>
              feature.properties['type'] == 'facility' &&
              feature.properties['name'] == widget.focusFacilityName,
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

    isMapInitialized = true;

    // Perform deferred focus and marker addition
    if (deferredFocusFeature != null) {
      focusOnLocation(deferredFocusFeature!.geometry);
      addMarkersFromFeatures([deferredFocusFeature!]);
      deferredFocusFeature = null; // Clear deferred action
    }
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
    final ByteData bytes = await rootBundle.load('assets/icons/pin.png');
    final Uint8List imageData = bytes.buffer.asUint8List();

    // Create a list to hold all annotation options
    final List<PointAnnotationOptions> annotationOptionsList =
        features.map((feature) {
      return PointAnnotationOptions(
        geometry: feature.geometry,
        image: imageData,
        iconSize: 0.2,
        textField: feature.properties['name'],
      );
    }).toList();

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
      addMarkersFromFeatures(categorizedFeatures[category]!);
    }
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
