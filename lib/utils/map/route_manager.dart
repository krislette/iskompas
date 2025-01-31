import 'dart:math';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class RouteManager {
  // Cache for bearing calculations to avoid recalculating
  static final Map<String, double> _bearingCache = {};

  static double calculateDistance(Point a, Point b) {
    final dx = a.coordinates.lng - b.coordinates.lng;
    final dy = a.coordinates.lat - b.coordinates.lat;
    return sqrt(dx * dx + dy * dy);
  }

  // Calculate bearing between two points
  static double calculateBearing(Point start, Point end) {
    // Check cache first
    String key =
        '${start.coordinates.lng},${start.coordinates.lat}->${end.coordinates.lng},${end.coordinates.lat}';
    if (_bearingCache.containsKey(key)) {
      return _bearingCache[key]!;
    }

    double startLat = start.coordinates.lat * pi / 180;
    double startLng = start.coordinates.lng * pi / 180;
    double endLat = end.coordinates.lat * pi / 180;
    double endLng = end.coordinates.lng * pi / 180;

    double y = sin(endLng - startLng) * cos(endLat);
    double x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(endLng - startLng);
    double bearing = atan2(y, x) * 180 / pi;
    bearing = (bearing + 360) % 360;

    // Cache the result
    _bearingCache[key] = bearing;

    return bearing;
  }

  // Get turn direction between segments
  static String getTurnDirection(
      double previousBearing, double currentBearing) {
    double angleDiff = (currentBearing - previousBearing + 360) % 360;

    if (angleDiff < 45 || angleDiff > 315) {
      return "Continue straight";
    } else if (angleDiff >= 45 && angleDiff <= 135) {
      return "Turn right";
    } else if (angleDiff >= 225 && angleDiff <= 315) {
      return "Turn left";
    }

    return "Continue straight";
  }

  // Get simplified instructions for a route
  static List<Map<String, dynamic>> getRouteInstructions(List<Point> route) {
    if (route.length < 2) return [];

    List<Map<String, dynamic>> instructions = [];
    double? previousBearing;

    // Process every 3rd point to reduce computation
    for (int i = 0; i < route.length - 1; i += 3) {
      Point current = route[i];
      Point next = route[min(i + 1, route.length - 1)];

      double currentBearing = calculateBearing(current, next);

      if (previousBearing != null) {
        String direction = getTurnDirection(previousBearing, currentBearing);

        // Only add instruction if it's different from the previous one
        if (instructions.isEmpty ||
            instructions.last['direction'] != direction) {
          instructions.add({
            'point': current,
            'direction': direction,
            'distance': '${(i * 5).round()}m', // Rough estimation
          });
        }
      }

      previousBearing = currentBearing;
    }

    return instructions;
  }
}
