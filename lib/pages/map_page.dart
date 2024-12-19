import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController controller = MapController();
  LatLng latLng = const LatLng(14.598471756011477, 121.01140977477588);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: latLng,
        initialZoom: 18,
        // adaptiveBoundaries: false,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/gggaysapdv/cm4uvrqe2001501sv3uqzfdmy/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiZ2dnYXlzYXBkdiIsImEiOiJjbTN5OW9sYm8xczhmMmtvbjA2YXVleTdlIn0.BH20wdYmc54LOGLkLO6zBw',
          additionalOptions: const {
            'accessToken':
                'pk.eyJ1IjoiZ2dnYXlzYXBkdiIsImEiOiJjbTN5OW9sYm8xczhmMmtvbjA2YXVleTdlIn0.BH20wdYmc54LOGLkLO6zBw',
            'id': 'cm4uvrqe2001501sv3uqzfdmy'
          },
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: latLng,
              width: 60,
              height: 60,
              alignment: Alignment.topCenter,
              child: Icon(
                Icons.location_pin,
                color: Colors.red.shade700,
                size: 60,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
