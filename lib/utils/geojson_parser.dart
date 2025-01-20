import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

Map<String, dynamic> parseGeoJson(String geoJsonString) {
  try {
    final data = jsonDecode(geoJsonString);
    List<Map<String, dynamic>> facilities = [];
    List<Map<String, dynamic>> nodes = [];
    List<List<Point>> lines = [];

    for (var feature in data['features']) {
      if (feature['geometry']['type'] == 'Point') {
        final type = feature['properties']['type'];
        final point = Point(
          coordinates: Position(
            feature['geometry']['coordinates'][0],
            feature['geometry']['coordinates'][1],
          ),
        );

        if (type == 'facility') {
          facilities.add({
            'geometry': point,
            'properties': feature['properties'],
            'id': feature['id']
          });
        } else if (type == 'node') {
          nodes.add({
            'geometry': point,
            'properties': feature['properties'],
            'id': feature['id']
          });
        }
      } else if (feature['geometry']['type'] == 'LineString') {
        lines.add((feature['geometry']['coordinates'] as List)
            .map((coords) => Point(
                  coordinates: Position(coords[0], coords[1]),
                ))
            .toList());
      }
    }

    return {'facilities': facilities, 'nodes': nodes, 'lines': lines};
  } catch (e) {
    throw Exception('Failed to load map data from local file: $e');
  }
}
