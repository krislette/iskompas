import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final accessToken = dotenv.env['ACCESS_TOKEN']!;
  final datasetId = dotenv.env['DATASET_ID']!;

  final MapController controller = MapController();
  LatLng startingPoint = const LatLng(
      14.599100484656496, 121.0117890766243); // Defined starting point
  List<LatLng> currentRoute = []; // For routing between starting point and pin

  // Function to fetch map data (nodes and lines) from the dataset
  Future<Map<String, List>> fetchMapData() async {
    final response = await http.get(
      Uri.parse(
          'https://api.mapbox.com/datasets/v1/gggaysapdv/$datasetId/features?access_token=$accessToken'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Separate nodes and lines
      List<LatLng> nodes = [];
      List<List<LatLng>> lines = [];

      for (var feature in data['features']) {
        if (feature['geometry']['type'] == 'Point') {
          nodes.add(LatLng(
            feature['geometry']['coordinates'][1],
            feature['geometry']['coordinates'][0],
          ));
        } else if (feature['geometry']['type'] == 'LineString') {
          lines.add((feature['geometry']['coordinates'] as List)
              .map((coords) => LatLng(coords[1], coords[0]))
              .toList());
        }
      }
      return {'nodes': nodes, 'lines': lines};
    } else {
      throw Exception('Failed to load map data');
    }
  }

  // Function to calculate route between two points
  void calculateRoute(LatLng from, LatLng to) {
    setState(() {
      currentRoute = [from, to]; // Straight-line route for simplicity
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, List>>(
        future: fetchMapData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading map data'));
          }

          final nodes = snapshot.data!['nodes'] as List<LatLng>;
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
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/gggaysapdv/cm4uvrqe2001501sv3uqzfdmy/tiles/256/{z}/{x}/{y}@2x?access_token=$accessToken',
              ),
              // Render markers for nodes
              MarkerLayer(
                markers: nodes.map((LatLng node) {
                  return Marker(
                    point: node,
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Node Details"),
                              content: const Text(
                                  "Do you want to navigate to this location?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    calculateRoute(startingPoint, node);
                                  },
                                  child: const Text("Show Location"),
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
