import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:iskompas/utils/pathfinder.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  void initState() {
    super.initState();
    if (datasetLink.isEmpty || tileLink.isEmpty) {
      throw Exception(
          'Environment variables DATASET_LINK or TILE_LINK are missing.');
    }
  }

  final datasetLink = dotenv.env['DATASET_LINK']!;
  final tileLink = dotenv.env['TILE_LINK']!;

  final MapController controller = MapController();
  LatLng startingPoint = const LatLng(
      14.599100484656496, 121.0117890766243); // Defined starting point
  List<LatLng> currentRoute = []; // For routing between starting point and pin
  List<LatLng> pathfindingNodes = []; // Nodes used for pathfinding

  // Function to fetch map data (nodes and lines) from the dataset
  Future<Map<String, dynamic>> fetchMapData() async {
    final response = await http.get(
      Uri.parse(datasetLink),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<LatLng> facilities = [];
      List<LatLng> nodes = [];
      List<List<LatLng>> lines = [];

      for (var feature in data['features']) {
        if (feature['geometry']['type'] == 'Point') {
          final type = feature['properties']['type'];
          if (type == 'facility') {
            facilities.add(LatLng(
              feature['geometry']['coordinates'][1],
              feature['geometry']['coordinates'][0],
            ));
          } else if (type == 'node') {
            nodes.add(LatLng(
              feature['geometry']['coordinates'][1],
              feature['geometry']['coordinates'][0],
            ));
          }
        } else if (feature['geometry']['type'] == 'LineString') {
          lines.add((feature['geometry']['coordinates'] as List)
              .map((coords) => LatLng(coords[1], coords[0]))
              .toList());
        }
      }

      // Combine facilities and nodes into a single list for pathfinding
      pathfindingNodes = [...nodes, ...facilities];

      return {'facilities': facilities, 'lines': lines};
    } else {
      throw Exception('Failed to load map data');
    }
  }

// Function to calculate route between two points using A* algorithm
  void calculateRoute(LatLng from, LatLng to) {
    // Debug: Check input values
    print('Calculating route from: $from to: $to');

    // Compute the route using combined facilities and nodes
    final route = PathFinder.findShortestPath(from, to, pathfindingNodes);

    // Debug: Check the returned route
    print('Computed route: $route');

    if (route.isNotEmpty) {
      setState(() {
        currentRoute = route;
      });
    } else {
      // Debug: No route found
      print('No route found between the selected points.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No route found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchMapData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading map data'));
          }

          final facilities = snapshot.data!['facilities'] as List<LatLng>;
          final lines = snapshot.data!['lines'] as List<List<LatLng>>;

          return FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: startingPoint,
              initialZoom: 18,
            ),
            children: [
              // Base map layer with custom tileset
              TileLayer(
                urlTemplate: tileLink,
              ),
              // Render markers for facilities
              MarkerLayer(
                markers: facilities.map((LatLng facility) {
                  return Marker(
                    point: facility,
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Facility Details"),
                              content: const Text(
                                  "Do you want to navigate to this location?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    calculateRoute(startingPoint, facility);
                                  },
                                  child: const Text("Navigate"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.blue,
                        size: 50,
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Render polylines for lines
              PolylineLayer(
                polylines: [
                  ...lines.map((line) {
                    return Polyline(
                      points: line,
                      color: Colors.red,
                      strokeWidth: 4,
                    );
                  }),
                  if (currentRoute.isNotEmpty)
                    Polyline(
                      points: currentRoute,
                      color: Colors.yellow,
                      strokeWidth: 4,
                    ),
                ],
              ),
              // Render starting point marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: startingPoint,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
