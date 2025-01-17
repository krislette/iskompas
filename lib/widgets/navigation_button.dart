import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';

class NavigationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NavigationButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Iskolors.colorYellow,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.navigation_outlined,
              color: Iskolors.colorDarkShade,
            ),
            SizedBox(width: 8),
            Text(
              'Start Navigation',
              style: TextStyle(
                color: Iskolors.colorDarkShade,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
