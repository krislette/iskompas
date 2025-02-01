import 'package:flutter/material.dart';

// Adds utility methods to the `Color` class for converting colors to integers.
extension ColorExtension on Color {
  int toInt() {
    final alpha = (a * 255).toInt();
    final red = (r * 255).toInt();
    final green = (g * 255).toInt();
    final blue = (b * 255).toInt();

    // Combine the components into a single int using bit shifting
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }
}
