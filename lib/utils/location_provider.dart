import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider extends ChangeNotifier {
  final Location location = Location();
  Point? currentLocation;
  bool isLocationPermissionGranted = false;

  LocationProvider() {
    checkLocationPermission();
  }

  Future<void> checkLocationPermission() async {
    final permissionStatus = await Permission.locationWhenInUse.request();
    isLocationPermissionGranted = permissionStatus.isGranted;

    if (isLocationPermissionGranted) {
      await getUserLocation();
    }
    notifyListeners();
  }

  Future<void> getUserLocation() async {
    try {
      // final userLocation = await location.getLocation();
      // currentLocation = Point(
      //   coordinates: Position(
      //     userLocation.longitude!,
      //     userLocation.latitude!,
      //   ),
      // );
      currentLocation = Point(
        coordinates: Position(
          121.01053859578796,
          14.59647159542187,
        ),
      );
      notifyListeners();
    } catch (e) {
      throw ('Error getting location: $e');
    }
  }

  // Optional: Method to start listening to location updates (to be optimized)
  Future<void> startLocationUpdates() async {
    if (!isLocationPermissionGranted) return;

    location.onLocationChanged.listen((LocationData locationData) {
      currentLocation = Point(
        coordinates: Position(
          locationData.longitude!,
          locationData.latitude!,
        ),
      );
      notifyListeners();
    });
  }
}
