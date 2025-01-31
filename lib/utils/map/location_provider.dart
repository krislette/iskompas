import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider extends ChangeNotifier {
  final Location location = Location();
  Point? currentLocation;
  bool isLocationPermissionGranted = false;
  Timer? _locationUpdateTimer;

  LocationProvider() {
    checkLocationPermission();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> checkLocationPermission() async {
    final permissionStatus = await Permission.locationWhenInUse.request();
    isLocationPermissionGranted = permissionStatus.isGranted;

    if (isLocationPermissionGranted) {
      await getUserLocation();
      startPeriodicLocationUpdates();
    }
    notifyListeners();
  }

  Future<void> getUserLocation() async {
    try {
      final userLocation = await location.getLocation();
      currentLocation = Point(
        coordinates: Position(
          userLocation.longitude!,
          userLocation.latitude!,
        ),
      );
      notifyListeners();
    } catch (e) {
      throw ('Error getting location: $e');
    }
  }

  void startPeriodicLocationUpdates() {
    // Stop any existing timer to prevent multiple timers
    _locationUpdateTimer?.cancel();

    // Update location every 3 seconds to balance accuracy and battery life
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final userLocation = await location.getLocation();
        currentLocation = Point(
          coordinates: Position(
            userLocation.longitude!,
            userLocation.latitude!,
          ),
        );
        notifyListeners();
      } catch (e) {
        throw ('Error updating location: $e');
      }
    });
  }
}
