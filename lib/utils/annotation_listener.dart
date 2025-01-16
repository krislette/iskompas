import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class CustomPointAnnotationClickListener
    extends OnPointAnnotationClickListener {
  final Function(Point, String, String) showMarkerPopup;

  CustomPointAnnotationClickListener({
    required this.showMarkerPopup,
  });

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    // Access real parts from mapbox api later
    String title = 'Location';
    String description = "This is a sample description for ${annotation.id}";
    showMarkerPopup(annotation.geometry, title, description);
  }
}
