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
  bool _isGpsEnabled = false;

  LocationProvider() {
    checkLocationPermission();
    _checkGpsStatus();
  }

  @override
  void dispose() {
    // Cancel any ongoing location updates when disposed
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  // Add method to check GPS status
  Future<void> _checkGpsStatus() async {
    try {
      _isGpsEnabled = await location.serviceEnabled();
      notifyListeners();
    } catch (e) {
      _isGpsEnabled = false;
      notifyListeners();
    }
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
  void startPeriodicLocationUpdates() async {
    // Check GPS status before starting updates
    await _checkGpsStatus();

    if (!_isGpsEnabled || !isLocationPermissionGranted) {
      _locationUpdateTimer?.cancel();
      return;
    }

    // Stop any existing timer to prevent multiple timers
    _locationUpdateTimer?.cancel();

    // Update location every second to balance accuracy and battery life
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        // Check GPS status on each update
        final isEnabled = await location.serviceEnabled();
        if (!isEnabled) {
          _isGpsEnabled = false;
          notifyListeners();
          _locationUpdateTimer?.cancel();
          return;
        }

        final userLocation = await location.getLocation();
        currentLocation = Point(
          coordinates: Position(
            userLocation.longitude!,
            userLocation.latitude!,
          ),
        );
        notifyListeners();
      } catch (e) {
        currentLocation = null;
        notifyListeners();
      }
    });
  }

  // Add method to request GPS
  Future<bool> requestGps() async {
    try {
      final isEnabled = await location.requestService();
      _isGpsEnabled = isEnabled;
      notifyListeners();
      if (isEnabled) {
        startPeriodicLocationUpdates();
      }
      return isEnabled;
    } catch (e) {
      return false;
    }
  }

  bool get isGpsEnabled => _isGpsEnabled;
}
