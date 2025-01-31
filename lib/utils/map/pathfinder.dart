import 'dart:math';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class SpatialNode {
  final Point point;
  final List<SpatialNode> neighbors;
  final String id;

  SpatialNode(this.point, this.id) : neighbors = [];
}

class GridCell {
  final List<SpatialNode> nodes;
  GridCell() : nodes = [];
}

class Pathfinder {
  static const int gridSize = 50;
  static Map<String, GridCell> spatialGrid = {};
  static Map<String, SpatialNode> nodeMap = {};
  static double minLat = double.infinity;
  static double maxLat = double.negativeInfinity;
  static double minLon = double.infinity;
  static double maxLon = double.negativeInfinity;
  static double latGridSize = 0;
  static double lonGridSize = 0;

  static void initializeGrid(List<Point> nodes) {
    _resetGridState(); // Reset state before initialization

    // Find bounds
    for (var node in nodes) {
      minLat = min(minLat, node.coordinates.lat.toDouble());
      maxLat = max(maxLat, node.coordinates.lat.toDouble());
      minLon = min(minLon, node.coordinates.lng.toDouble());
      maxLon = max(maxLon, node.coordinates.lng.toDouble());
    }

    latGridSize = (maxLat - minLat) / gridSize;
    lonGridSize = (maxLon - minLon) / gridSize;

    // Create spatial nodes and add to grid
    for (var node in nodes) {
      final spatialNode = SpatialNode(node, node.hashCode.toString());
      nodeMap[spatialNode.id] = spatialNode;

      final gridKey = _getGridKey(
          node.coordinates.lat.toDouble(), node.coordinates.lng.toDouble());
      spatialGrid.putIfAbsent(gridKey, () => GridCell()).nodes.add(spatialNode);
    }

    // Connect nearby nodes
    for (var node in nodeMap.values) {
      _connectToNearbyNodes(node);
    }
  }

  static void _resetGridState() {
    // Reset bounds
    minLat = double.infinity;
    maxLat = double.negativeInfinity;
    minLon = double.infinity;
    maxLon = double.negativeInfinity;
    latGridSize = 0;
    lonGridSize = 0;

    // Clear maps
    spatialGrid.clear();
    nodeMap.clear();
  }

  static String _getGridKey(double lat, double lon) {
    final gridX = ((lon - minLon) / lonGridSize).floor();
    final gridY = ((lat - minLat) / latGridSize).floor();
    return '$gridX:$gridY';
  }

  static void _connectToNearbyNodes(SpatialNode node) {
    final lat = node.point.coordinates.lat;
    final lon = node.point.coordinates.lng;
    final gridKey = _getGridKey(lat.toDouble(), lon.toDouble());
    final gridX = int.parse(gridKey.split(':')[0]);
    final gridY = int.parse(gridKey.split(':')[1]);

    // Check surrounding cells
    for (var i = -1; i <= 1; i++) {
      for (var j = -1; j <= 1; j++) {
        final nearbyKey = '${gridX + i}:${gridY + j}';
        final nearbyCell = spatialGrid[nearbyKey];
        if (nearbyCell != null) {
          for (var nearbyNode in nearbyCell.nodes) {
            if (nearbyNode != node &&
                _isWithinRange(node.point, nearbyNode.point)) {
              node.neighbors.add(nearbyNode);
            }
          }
        }
      }
    }
  }

  static bool _isWithinRange(Point a, Point b) {
    // Adjust this threshold based on your needs
    const double maxDistance = 0.00004; // Approximately 20 meters
    final dx = a.coordinates.lng - b.coordinates.lng;
    final dy = a.coordinates.lat - b.coordinates.lat;
    return (dx * dx + dy * dy) < (maxDistance * maxDistance);
  }

  static List<Point> findShortestPath(
      Point start, Point end, List<Point> nodes) {
    // Initialize grid if empty or if nodes changed
    if (spatialGrid.isEmpty) {
      initializeGrid(nodes);
    }

    final startNode = _findNearestNode(start);
    final endNode = _findNearestNode(end);

    if (startNode == null || endNode == null) {
      return [];
    }

    final path = _astar(startNode, endNode);
    final result = path.map((node) => node.point).toList();

    return result;
  }

  static SpatialNode? _findNearestNode(Point point) {
    final gridKey = _getGridKey(
        point.coordinates.lat.toDouble(), point.coordinates.lng.toDouble());
    final gridX = int.parse(gridKey.split(':')[0]);
    final gridY = int.parse(gridKey.split(':')[1]);

    SpatialNode? nearest;
    double minDist = double.infinity;

    // Search in current and adjacent cells
    for (var i = -1; i <= 1; i++) {
      for (var j = -1; j <= 1; j++) {
        final nearbyKey = '${gridX + i}:${gridY + j}';
        final cell = spatialGrid[nearbyKey];
        if (cell != null) {
          for (var node in cell.nodes) {
            final dist = _calculateDistance(point, node.point);
            if (dist < minDist) {
              minDist = dist;
              nearest = node;
            }
          }
        }
      }
    }

    return nearest;
  }

  // Manhattan distance instead of Euclidean
  static double _calculateDistance(Point a, Point b) {
    return ((a.coordinates[0]! - b.coordinates[0]!).abs() +
            (a.coordinates[1]! - b.coordinates[1]!).abs())
        .toDouble();
  }

  static List<SpatialNode> _astar(SpatialNode start, SpatialNode goal) {
    final openSet = <SpatialNode>{start};
    final cameFrom = <String, String>{};
    final gScore = <String, double>{start.id: 0};
    final fScore = <String, double>{
      start.id: _calculateDistance(start.point, goal.point)
    };

    while (openSet.isNotEmpty) {
      SpatialNode current = openSet.reduce((a, b) =>
          (fScore[a.id] ?? double.infinity) < (fScore[b.id] ?? double.infinity)
              ? a
              : b);

      if (current == goal) {
        return _reconstructPath(cameFrom, current);
      }

      openSet.remove(current);

      for (var neighbor in current.neighbors) {
        final tentativeGScore = (gScore[current.id] ?? double.infinity) +
            _calculateDistance(current.point, neighbor.point);

        if (tentativeGScore < (gScore[neighbor.id] ?? double.infinity)) {
          cameFrom[neighbor.id] = current.id;
          gScore[neighbor.id] = tentativeGScore;
          fScore[neighbor.id] =
              tentativeGScore + _calculateDistance(neighbor.point, goal.point);
          openSet.add(neighbor);
        }
      }
    }

    return [];
  }

  static List<SpatialNode> _reconstructPath(
      Map<String, String> cameFrom, SpatialNode current) {
    final path = <SpatialNode>[current];
    while (cameFrom.containsKey(current.id)) {
      current = nodeMap[cameFrom[current.id]]!;
      path.insert(0, current);
    }
    return path;
  }
}
