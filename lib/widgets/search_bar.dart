import 'package:flutter/material.dart';
import 'package:iskompas/utils/shared/colors.dart';

// A customizable search bar widget with light and dark mode support
class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final bool isDarkMode;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onTap,
    this.onChanged,
    this.controller,
    this.isDarkMode = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    // Define colors based on theme mode
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
      // Trigger onTap callback when the search bar is tapped
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
            focusNode: focusNode,
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
