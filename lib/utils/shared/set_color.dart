import 'package:flutter/material.dart';
import 'colors.dart';

// Returns a color based on whether the current index matches the selected index.
Color setColor(int index, int selectedIndex) {
  return index == selectedIndex ? Iskolors.colorYellow : Iskolors.colorWhite;
}
