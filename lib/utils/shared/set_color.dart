import 'package:flutter/material.dart';
import 'colors.dart';

Color setColor(int index, int selectedIndex) {
  return index == selectedIndex ? Iskolors.colorYellow : Iskolors.colorWhite;
}
