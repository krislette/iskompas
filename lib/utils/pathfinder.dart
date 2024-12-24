import 'package:latlong2/latlong.dart';

class Pathfinder {
  final Map<LatLng, List<LatLng>> adjacencyList;

  Pathfinder(this.adjacencyList);

  List<LatLng> findShortestPath(LatLng start, LatLng goal) {
    Map<LatLng, double> gScore = {start: 0.0};
    Map<LatLng, double> fScore = {start: _heuristic(start, goal)};
    Map<LatLng, LatLng?> cameFrom = {};
    List<LatLng> openSet = [start];

    while (openSet.isNotEmpty) {
      openSet.sort((a, b) => (fScore[a] ?? double.infinity)
          .compareTo(fScore[b] ?? double.infinity));
      LatLng current = openSet.removeAt(0);

      if (current == goal) {
        return _reconstructPath(cameFrom, current);
      }

      for (LatLng neighbor in adjacencyList[current] ?? []) {
        double tentativeGScore =
            gScore[current]! + _distance(current, neighbor);

        if (tentativeGScore < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] = tentativeGScore + _heuristic(neighbor, goal);

          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }

    return []; // Return empty if no path found
  }

  double _heuristic(LatLng a, LatLng b) {
    return _distance(a, b);
  }

  double _distance(LatLng a, LatLng b) {
    const Distance distance = Distance();
    return distance(a, b);
  }

  List<LatLng> _reconstructPath(Map<LatLng, LatLng?> cameFrom, LatLng current) {
    List<LatLng> path = [current];
    while (cameFrom[current] != null) {
      current = cameFrom[current]!;
      path.add(current);
    }
    return path.reversed.toList();
  }
}
