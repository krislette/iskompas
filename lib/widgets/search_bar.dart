import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.controller,
    this.isDarkMode = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDarkMode ? Iskolors.colorWhite : Iskolors.colorDarkShade;
    final hintColor =
        isDarkMode ? Iskolors.colorLightGrey : Iskolors.colorDarkShade;
    final backgroundColor =
        isDarkMode ? Iskolors.colorDarkShade : Iskolors.colorPureWhite;
    final borderColor =
        isDarkMode ? Iskolors.colorGreyShade : Iskolors.colorLightBlack;
    final shadowColor =
        isDarkMode ? Iskolors.colorTransparent : Iskolors.colorLightShadow;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: IgnorePointer(
          // Ignore pointer events if onTap is provided
          ignoring: onTap != null,
          child: TextField(
            controller: controller,
            style: TextStyle(color: textColor),
            cursorColor: textColor,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor),
              border: InputBorder.none,
              icon: Icon(Icons.search, color: hintColor),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
