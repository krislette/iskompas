import 'package:latlong2/latlong.dart';

class PathFinder {
  static List<LatLng> findShortestPath(
      LatLng start, LatLng goal, List<LatLng> nodes) {
    // Simplified A* algorithm for demonstration
    List<LatLng> openSet = [start];
    Map<LatLng, LatLng?> cameFrom = {};
    Map<LatLng, double> gScore = {start: 0};
    Map<LatLng, double> fScore = {start: _heuristic(start, goal)};

    while (openSet.isNotEmpty) {
      openSet.sort((a, b) => fScore[a]!.compareTo(fScore[b]!));
      LatLng current = openSet.first;

      if (current == goal) {
        return _reconstructPath(cameFrom, current);
      }

      openSet.remove(current);
      for (LatLng neighbor in _getNeighbors(current, nodes)) {
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

  static double _heuristic(LatLng a, LatLng b) {
    return _distance(a, b);
  }

  static double _distance(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Meter, a, b);
  }

  static List<LatLng> _getNeighbors(LatLng node, List<LatLng> nodes) {
    return nodes.where((n) => _distance(node, n) < 50).toList();
  }

  static List<LatLng> _reconstructPath(
      Map<LatLng, LatLng?> cameFrom, LatLng current) {
    List<LatLng> path = [current];
    while (cameFrom[current] != null) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }
    return path;
  }
}
