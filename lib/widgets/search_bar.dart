import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 30, 30),
        border: Border.all(color: Iskolors.colorGreyShade),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Iskolors.colorShadow,
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Iskolors.colorWhite),
        cursorColor: Iskolors.colorWhite,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Iskolors.colorLightGrey),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Iskolors.colorLightGrey),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
