import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// Parses a GeoJSON string into a structured map containing facilities, nodes, and lines
Map<String, dynamic> parseGeoJson(String geoJsonString) {
  // Decodes the GeoJSON string and store facility, nodes, and lines features
  try {
    final data = jsonDecode(geoJsonString);
    List<Map<String, dynamic>> facilities = [];
    List<Map<String, dynamic>> nodes = [];
    List<List<Point>> lines = [];

    // Iterate through each feature in the GeoJSON
    for (var feature in data['features']) {
      if (feature['geometry']['type'] == 'Point') {
        final type = feature['properties']['type'];
        final point = Point(
          coordinates: Position(
            feature['geometry']['coordinates'][0],
            feature['geometry']['coordinates'][1],
          ),
        );

        // Check if it's a node
        if (type == 'node') {
          nodes.add({
            'geometry': point,
            'properties': feature['properties'],
            'id': feature['id']
          });
        }
        // All other types (facility, faculty, sports) go into facilities
        else {
          facilities.add({
            'geometry': point,
            'properties': feature['properties'],
            'id': feature['id']
          });
        }
      } else if (feature['geometry']['type'] == 'LineString') {
        // Convert LineString coordinates to a list of `Point` objects
        lines.add((feature['geometry']['coordinates'] as List)
            .map((coords) => Point(
                  coordinates: Position(coords[0], coords[1]),
                ))
            .toList());
      }
    }

    // Return the parsed data
    return {'facilities': facilities, 'nodes': nodes, 'lines': lines};
  } catch (e) {
    throw Exception('Failed to load map data from local file: $e');
  }
}
