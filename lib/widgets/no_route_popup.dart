import 'package:flutter/material.dart';
import 'package:iskompas/utils/shared/colors.dart';

// A popup dialog that informs the user when no route is found
class NoRoutePopup {
  // Displays a dialog when no route can be computed
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Iskolors.colorWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'No Route Found',
            style: TextStyle(
              color: Iskolors.colorDarkShade,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Iskompas is having a hard time finding a route for you. You might want to go near a road or outside a facility and try again.',
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
