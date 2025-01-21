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
      bottom: 170,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Iskolors.colorYellow,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(18),
        ),
        child: const Icon(
          Icons.navigation_outlined,
          color: Iskolors.colorDarkShade,
          size: 24,
        ),
      ),
    );
  }
}
