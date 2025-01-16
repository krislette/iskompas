import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class GeoFeature {
  final String id;
  final Map<String, dynamic> properties;
  final Point geometry;

  GeoFeature({
    required this.id,
    required this.properties,
    required this.geometry,
  });

  String get type => properties['type'] as String;
  String? get description => properties['description'] as String?;
  String? get name => properties['name'] as String?;
}
