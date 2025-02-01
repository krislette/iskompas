import 'package:flutter/material.dart';
import 'package:iskompas/utils/shared/colors.dart';

// A popup dialog that appears when the GPS is turned off
class GpsOffPopup {
  // Displays a confirmation dialog informing the user that GPS is turned off
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      // Prevent closing by tapping outside the dialog
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Iskolors.colorWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'GPS Turned Off',
            style: TextStyle(
              color: Iskolors.colorDarkShade,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Please enable GPS to continue navigation.',
            style: TextStyle(
              color: Iskolors.colorDarkGrey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
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
                'OK',
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
