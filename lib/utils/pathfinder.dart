import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:math';

class PathFinder {
  static List<Point> findShortestPath(
      Point start, Point goal, List<Point> nodes) {
    // Simplified A* algorithm for demonstration
    List<Point> openSet = [start];
    Map<Point, Point?> cameFrom = {};
    Map<Point, double> gScore = {start: 0.0};
    Map<Point, double> fScore = {start: _heuristic(start, goal)};

    while (openSet.isNotEmpty) {
      openSet.sort((a, b) => fScore[a]!.compareTo(fScore[b]!));
      Point current = openSet.first;

      if (current == goal) {
        return _reconstructPath(cameFrom, current);
      }

      openSet.remove(current);
      for (Point neighbor in _getNeighbors(current, nodes)) {
        double tentativeGScore =
            gScore[current]! + _distance(current, neighbor);

        if (tentativeGScore < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] = gScore[neighbor]! + _heuristic(neighbor, goal);

          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }

    return []; // Return an empty list if no path is found
  }

  static double _heuristic(Point a, Point b) {
    return _distance(a, b);
  }

  static double _distance(Point a, Point b) {
    final dx = a.coordinates.lng - b.coordinates.lng;
    final dy = a.coordinates.lat - b.coordinates.lat;
    return sqrt(dx * dx + dy * dy); // Euclidean distance
  }

  static List<Point> _getNeighbors(Point node, List<Point> nodes) {
    return nodes
        .where((n) =>
            _distance(node, n) < 50.0) // Adjust neighbor threshold as needed
        .toList();
  }

  static List<Point> _reconstructPath(
      Map<Point, Point?> cameFrom, Point current) {
    List<Point> path = [current];
    while (cameFrom[current] != null) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }
    return path;
  }
}
