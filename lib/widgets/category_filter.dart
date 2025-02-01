import 'package:flutter/material.dart';
import 'package:iskompas/utils/shared/colors.dart';

// A customizable filter widget for categories, displaying an icon and label with dynamic colors based on selection and theme
class CategoryFilter extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;

  const CategoryFilter({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on selection and theme
    final backgroundColor = isSelected
        ? Iskolors.colorMaroon
        : (isDarkMode ? Iskolors.colorDarkShade : Iskolors.colorWhite);
    final iconColor = isSelected
        ? Iskolors.colorWhite
        : (isDarkMode ? Iskolors.colorGrey : Iskolors.colorMaroon);
    final textColor = isSelected
        ? Iskolors.colorWhite
        : (isDarkMode ? Iskolors.colorGrey : Iskolors.colorMaroon);

    // GestureDetector to handle taps and trigger the onTap callback
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
