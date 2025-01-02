import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:math';

class PathFinder {
  static List<Point> findShortestPath(
      Point start, Point end, List<Point> nodes) {
    // Create open and closed sets
    final openSet = <Point>{start};
    final closedSet = <Point>{};

    // Maps to store the cost and parent of each node
    final gScore = <Point, double>{start: 0}; // Cost from start to the node
    final fScore = <Point, double>{
      start: _heuristic(start, end)
    }; // Estimated total cost
    final cameFrom = <Point, Point?>{};

    while (openSet.isNotEmpty) {
      // Get the node with the lowest fScore
      final current = openSet.reduce((a, b) => fScore[a]! < fScore[b]! ? a : b);

      // If we reached the target, reconstruct the path
      if (_isEqual(current, end)) {
        return _reconstructPath(cameFrom, current);
      }

      openSet.remove(current);
      closedSet.add(current);

      for (final neighbor in _getNearestNeighbors(current, nodes, closedSet)) {
        if (closedSet.contains(neighbor)) continue;

        final tentativeGScore = gScore[current]! + _distance(current, neighbor);

        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        } else if (tentativeGScore >= (gScore[neighbor] ?? double.infinity)) {
          continue;
        }

        // This path is the best so far
        cameFrom[neighbor] = current;
        gScore[neighbor] = tentativeGScore;
        fScore[neighbor] = gScore[neighbor]! + _heuristic(neighbor, end);
      }
    }

    // Return an empty list if no path is found
    return [];
  }

  // Heuristic function (straight-line distance)
  static double _heuristic(Point a, Point b) {
    return _distance(a, b);
  }

  // Euclidean distance
  static double _distance(Point a, Point b) {
    final dx = a.coordinates.lng - b.coordinates.lng;
    final dy = a.coordinates.lat - b.coordinates.lat;
    return sqrt(dx * dx + dy * dy);
  }

  // Reconstruct the path from the 'cameFrom' map
  static List<Point> _reconstructPath(
      Map<Point, Point?> cameFrom, Point current) {
    final path = <Point>[current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.add(current);
    }
    return path.reversed.toList();
  }

  // Get nearest neighbors from the dataset nodes
  static List<Point> _getNearestNeighbors(
      Point node, List<Point> nodes, Set<Point> closedSet) {
    const double searchRadius = 0.0005; // Adjust this for tightness
    const int maxNeighbors = 5; // Adjust this for density

    // Filter nodes by proximity and exclude already-visited ones
    final nearbyNodes = nodes
        .where(
            (n) => !closedSet.contains(n) && _distance(node, n) <= searchRadius)
        .toList();

    // Sort by distance and limit to maxNeighbors
    nearbyNodes
        .sort((a, b) => _distance(node, a).compareTo(_distance(node, b)));

    return nearbyNodes.take(maxNeighbors).toList();
  }

  // Check if two points are equal
  static bool _isEqual(Point a, Point b) {
    return a.coordinates.lng == b.coordinates.lng &&
        a.coordinates.lat == b.coordinates.lat;
  }
}
