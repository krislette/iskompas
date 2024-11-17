import 'package:flutter/material.dart';

Color setColor(int index, int selectedIndex) {
  return index == selectedIndex ? const Color(0xFFFFDE00) : Colors.white;
}
