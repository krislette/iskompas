import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iskompas/widgets/confirmation_popup.dart';

// Manage saving, retriving and removing facility details to/from local storage
class SavedFacilitiesService {
  static const String _storageKey = 'saved_facilities';

  // Fetch saved facilities from local storage
  static Future<List<Map<String, dynamic>>> getSavedFacilities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedJson = prefs.getString(_storageKey);

    if (savedJson == null) return [];

    List<dynamic> decoded = jsonDecode(savedJson);
    return decoded.cast<Map<String, dynamic>>();
  }

  // Save a facility to local storage
  static Future<bool> saveFacility(Map<String, dynamic> facilityDetails) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get currently saved facilities
      List<Map<String, dynamic>> savedFacilities = await getSavedFacilities();

      // Check if facility is already saved
      bool alreadySaved = savedFacilities
          .any((facility) => facility['name'] == facilityDetails['name']);

      if (alreadySaved) return false;

      // Combine relevant data
      Map<String, dynamic> facilityToSave = {
        'name': facilityDetails['name'],
        'description': facilityDetails['description'],
        'location': facilityDetails['location'],
        'image': facilityDetails['image'],
      };

      // Add to saved facilities
      savedFacilities.add(facilityToSave);

      // Save to local storage
      await prefs.setString(_storageKey, jsonEncode(savedFacilities));
      return true;
    } catch (e) {
      throw ('Error saving facility: $e');
    }
  }

  // Remove a facility
  static Future<bool> removeFacility(
      BuildContext context, String facilityName) async {
    try {
      // Show confirmation popup before deletion
      final shouldDelete = await ConfirmationPopup.show(context, facilityName);
      if (shouldDelete == true) {
        final prefs = await SharedPreferences.getInstance();

        // Get saved facilities and remove the specified one
        List<Map<String, dynamic>> savedFacilities = await getSavedFacilities();
        savedFacilities
            .removeWhere((facility) => facility['name'] == facilityName);

        // Save updated list to local storage
        await prefs.setString(_storageKey, jsonEncode(savedFacilities));
        return true;
      }
      return false;
    } catch (e) {
      throw ('Error removing facility: $e');
    }
  }

  // Check if a facility is saved
  static Future<bool> isFacilitySaved(String facilityName) async {
    List<Map<String, dynamic>> savedFacilities = await getSavedFacilities();
    return savedFacilities.any((facility) => facility['name'] == facilityName);
  }
}
