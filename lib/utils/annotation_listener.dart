import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class CustomPointAnnotationClickListener
    extends OnPointAnnotationClickListener {
  final Function(Point, String, String) showMarkerPopup;
  final Map<String, Map<String, String>> annotationMetadata;
  final Map<String, String> annotationIdMap;

  CustomPointAnnotationClickListener({
    required this.showMarkerPopup,
    required this.annotationMetadata,
    required this.annotationIdMap,
  });

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    // Retrieve the custom ID mapped to the annotation ID
    final customId = annotationIdMap[annotation.id];

    if (customId != null) {
      // Retrieve metadata associated with the custom ID
      final metadata = annotationMetadata[customId];

      if (metadata != null) {
        // Show the popup with metadata
        showMarkerPopup(
          annotation.geometry,
          metadata['title'] ?? 'Unknown Location',
          metadata['description'] ?? 'No description available',
        );
      } else {
        // Metadata not found for custom ID
        showMarkerPopup(
          annotation.geometry,
          'Unknown Location',
          'No description available',
        );
      }
    } else {
      // Custom ID not found for the annotation
      showMarkerPopup(
        annotation.geometry,
        'Unknown Location',
        'No description available',
      );
    }
  }
}
