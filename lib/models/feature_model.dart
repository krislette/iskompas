import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// Represents a geographic feature
class GeoFeature {
  final String id;
  final Map<String, dynamic> properties;
  final Point geometry;

  // Constructor requiring an ID, properties map and geometry point
  GeoFeature({
    required this.id,
    required this.properties,
    required this.geometry,
  });

  // Getters to access common feature properties
  String get type => properties['type'] as String;
  String? get description => properties['description'] as String?;
  String? get name => properties['name'] as String?;
}
