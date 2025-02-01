import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// Class for the custom listener on marker tap events
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
    // Called when a point annotation is clicked
    final customId = annotationIdMap[annotation.id];
    if (customId != null) {
      final metadata = annotationMetadata[customId];
      if (metadata != null) {
        // Retrieve title and description from metadata
        final title = metadata['title'] ?? 'No Title';
        final description = metadata['description'] ?? 'No Description';

        // Display the marker popup with geometry, title, and description
        showMarkerPopup(annotation.geometry, title, description);
      }
    }
  }
}
