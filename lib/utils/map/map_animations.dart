import 'dart:math';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:iskompas/models/feature_model.dart';

class MapAnimations {
  static void fitMarkersInView(MapboxMap mapboxMap, List<GeoFeature> features) {
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

    mapboxMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: zoomLevel,
        bearing: 0.0,
        pitch: 45.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  static void fitRouteInView(MapboxMap mapboxMap, List<Point> route) {
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
    mapboxMap.getCameraState().then((currentCamera) {
      // Force the zoom change by first zooming out slightly
      final initialZoom = currentCamera.zoom;

      // Two-step animation for more dramatic effect
      // First zoom out slightly if we're already zoomed in
      if (initialZoom > zoomLevel - 1) {
        mapboxMap
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
          mapboxMap.flyTo(
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
        mapboxMap.flyTo(
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
}
