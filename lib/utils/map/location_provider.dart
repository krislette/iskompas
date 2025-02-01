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
    // Cancel any ongoing location updates when disposed
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  // Method to check location permission
  Future<void> checkLocationPermission() async {
    final permissionStatus = await Permission.locationWhenInUse.request();
    isLocationPermissionGranted = permissionStatus.isGranted;

    // Get user location if permission is granted and start updates
    if (isLocationPermissionGranted) {
      await getUserLocation();
      startPeriodicLocationUpdates();
    }

    // Notify listeners abotu the permission status change
    notifyListeners();
  }

  // Method to fetch the user's current location
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

  // Method to start periodic updates of the user's location every second
  void startPeriodicLocationUpdates() {
    // Stop any existing timer to prevent multiple timers
    _locationUpdateTimer?.cancel();

    // Update location every second to balance accuracy and battery life
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 1), (_) async {
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
