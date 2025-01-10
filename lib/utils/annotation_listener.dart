import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class CustomPointAnnotationClickListener
    extends OnPointAnnotationClickListener {
  final Function(Point, String) showMarkerPopup;

  CustomPointAnnotationClickListener({
    required this.showMarkerPopup,
  });

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    // Customize the popup description as needed
    String description = "This is a sample description for ${annotation.id}";
    showMarkerPopup(annotation.geometry, description);
  }
}
