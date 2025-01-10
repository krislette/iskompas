import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:iskompas/utils/pathfinder.dart';
import 'package:flutter/services.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late MapboxMap _mapboxMap;
  late PointAnnotationManager _pointAnnotationManager;
  late PolylineAnnotationManager _polylineAnnotationManager;
  late Future<Map<String, dynamic>> _mapDataFuture;

  final datasetLink = dotenv.env['DATASET_LINK']!;
  final startingPoint = Point(
      coordinates: Position(
          121.01150194357385, 14.598833219335527)); // Longitude, Latitude
  List<Point> currentRoute = []; // Route for navigation
  List<Point> pathfindingNodes = []; // Nodes for pathfinding

  @override
  void initState() {
    super.initState();

    // Ensure the access token is not null
    final accessToken = dotenv.env['ACCESS_TOKEN'];
    if (accessToken == null) {
      throw Exception('ACCESS_TOKEN is missing from the environment variables');
    }

    // Set the Mapbox access token globally
    MapboxOptions.setAccessToken(accessToken);

    // Initialize the map data future
    _mapDataFuture = fetchMapData();
  }

  Future<Map<String, dynamic>> fetchMapData() async {
    final response = await http.get(Uri.parse(datasetLink));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<Point> facilities = [];
      List<Point> nodes = [];
      List<List<Point>> lines = [];

      for (var feature in data['features']) {
        if (feature['geometry']['type'] == 'Point') {
          final type = feature['properties']['type'];
          if (type == 'facility') {
            facilities.add(Point(
              coordinates: Position(
                feature['geometry']['coordinates'][0],
                feature['geometry']['coordinates'][1],
              ),
            ));
          } else if (type == 'node') {
            nodes.add(Point(
              coordinates: Position(
                feature['geometry']['coordinates'][0],
                feature['geometry']['coordinates'][1],
              ),
            ));
          }
        } else if (feature['geometry']['type'] == 'LineString') {
          lines.add((feature['geometry']['coordinates'] as List)
              .map((coords) => Point(
                    coordinates: Position(coords[0], coords[1]),
                  ))
              .toList());
        }
      }

      pathfindingNodes = [...nodes, ...facilities];

      return {'facilities': facilities, 'lines': lines};
    } else {
      throw Exception('Failed to load map data');
    }
  }

  Future<void> initializeManagers(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Set a default style for the map
    // await _mapboxMap.loadStyleURI(MapboxStyles.LIGHT);

    // await _mapboxMap.style.setStyleImportConfigProperty(
    // "basemap", "showPointOfInterestLabels", false);

    // Initialize annotation managers
    _pointAnnotationManager =
        await _mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager =
        await _mapboxMap.annotations.createPolylineAnnotationManager();

    _pointAnnotationManager.addOnPointAnnotationClickListener(
      CustomPointAnnotationClickListener(
        showMarkerPopup: showMarkerPopup,
      ),
    );

    // var bounds = CoordinateBounds(
    //     southwest:
    //         Point(coordinates: Position(121.00814034481606, 14.59722716810296)),
    //     northeast: Point(
    //         coordinates: Position(121.01320393779709, 14.598189545981164)),
    // infiniteBounds: false);

    // // Set bounds
    // _mapboxMap.setBounds(
    //     CameraBoundsOptions(bounds: bounds, maxZoom: 10, minZoom: 6));
  }

  Future<void> addMarkers(List<Point> facilities, {Point? userLocation}) async {
    // Load the image from assets
    final ByteData bytes = await rootBundle.load('assets/icons/pin.png');
    final Uint8List imageData = bytes.buffer.asUint8List();

    final ByteData userBytes =
        await rootBundle.load('assets/icons/user-pin.png');
    final Uint8List userImageData = userBytes.buffer.asUint8List();

    for (var facility in facilities) {
      final PointAnnotationOptions markerOptions = PointAnnotationOptions(
        geometry: facility,
        image: imageData,
        iconSize: 0.2,
      );
      _pointAnnotationManager.create(markerOptions);
    }

    // Add only one user location marker
    if (userLocation != null) {
      final PointAnnotationOptions userMarkerOptions = PointAnnotationOptions(
        geometry: userLocation,
        image: userImageData,
        iconSize: 0.03,
      );
      _pointAnnotationManager.create(userMarkerOptions);
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
                  calculateRoute(startingPoint,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No route found')),
      );
      clearPolylines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final styleUri = dotenv.env['STYLE_URI']!;
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _mapDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading map data'));
          }

          final facilities = snapshot.data!['facilities'] as List<Point>;
          final lines = snapshot.data!['lines'] as List<List<Point>>;

          return MapWidget(
            cameraOptions: CameraOptions(
                center: Point(coordinates: startingPoint.coordinates),
                zoom: 18.0,
                pitch: 45),
            // styleUri: styleUri,
            onMapCreated: (mapboxMap) async {
              mapboxMap.scaleBar
                  .updateSettings(ScaleBarSettings(enabled: false));
              mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await initializeManagers(mapboxMap);
                if (facilities.isNotEmpty) {
                  addMarkers(facilities, userLocation: startingPoint);
                }
                for (var line in lines) {
                  addPolyline(line);
                }
              });
            },
          );
        },
      ),
    );
  }
}

class CustomPointAnnotationClickListener
    extends OnPointAnnotationClickListener {
  final Function(Point, String) showMarkerPopup;

  CustomPointAnnotationClickListener({
    required this.showMarkerPopup,
  });

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    // Customize the popup description as needed
    String description = "This is a sample description for ${annotation.id}";
    showMarkerPopup(annotation.geometry, description);
  }
}
