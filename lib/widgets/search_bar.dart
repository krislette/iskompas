import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool isDarkMode; // Add a theme toggle

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.controller,
    this.isDarkMode = true, 
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode
        ? const Color.fromARGB(255, 30, 30, 30)
        : Colors.white;
    final textColor = isDarkMode
        ? Iskolors.colorWhite
        : Colors.black;
    final hintColor = isDarkMode
        ? Iskolors.colorLightGrey
        : Colors.grey;
    final borderColor = isDarkMode
        ? Iskolors.colorGreyShade
        : Colors.black12;

    final shadowColor = isDarkMode
        ? Iskolors.colorShadow
        : Colors.black.withOpacity(0.1); 

    return Container(
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
    );
  }
}
