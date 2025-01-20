import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';

class ThemeToggleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isNightMode;

  const ThemeToggleButton({
    super.key,
    required this.onPressed,
    required this.isNightMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 90,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isNightMode ? Iskolors.colorMaroon : Iskolors.colorWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(18),
        ),
        child: Icon(
          Icons.brightness_4,
          color: isNightMode ? Colors.white : Iskolors.colorMaroon,
          size: 24,
        ),
      ),
    );
  }
}
