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
    final customId = annotationIdMap[annotation.id];
    if (customId != null) {
      final metadata = annotationMetadata[customId];
      if (metadata != null) {
        final title = metadata['title'] ?? 'No Title';
        final description = metadata['description'] ?? 'No Description';
        showMarkerPopup(annotation.geometry, title, description);
      }
    }
  }
}
