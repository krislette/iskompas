import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/navbar.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:iskompas/utils/geojson_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final accessToken = dotenv.env['ACCESS_TOKEN'];
  if (accessToken == null) {
    throw Exception('ACCESS_TOKEN is missing from the environment variables');
  }
  MapboxOptions.setAccessToken(accessToken);

  // Load GeoJSON data globally
  try {
    final geoJsonString =
        await rootBundle.loadString('assets/data/nodes.geojson');

    if (geoJsonString.isEmpty) {
      throw Exception('GeoJSON file is empty');
    }

    final mapData = parseGeoJson(geoJsonString);

    if (mapData['facilities'] == null ||
        mapData['nodes'] == null ||
        mapData['lines'] == null) {
      throw Exception('Missing required data in parsed GeoJSON');
    }

    runApp(Iskompas(mapData: mapData));
  } catch (e) {
    throw Exception('Error loading map data: $e');
  }
}

class Iskompas extends StatelessWidget {
  final Map<String, dynamic> mapData;
  const Iskompas({super.key, required this.mapData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Navbar(mapData: mapData),
    );
  }
}
