import 'package:flutter/material.dart';
import 'package:iskompas/utils/shared/colors.dart';

// A reusable confirmation dialog popup for unsaving a location
class ConfirmationPopup {
  // Displays a confirmation dialog when the user attempts to unsave a location
  static Future<bool?> show(BuildContext context, String facilityName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Iskolors.colorWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Unsave Location',
            style: TextStyle(
              color: Iskolors.colorDarkShade,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'You\'re going to unsave "$facilityName" from your saved locations. Are you sure?',
            style: const TextStyle(
              color: Iskolors.colorDarkGrey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: Iskolors.colorDarkShade,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'No, keep it',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Iskolors.colorMaroon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Yes, unsave it',
                style: TextStyle(
                  fontSize: 16,
                  color: Iskolors.colorWhite,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
