import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/splash_screen.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:iskompas/utils/shared/geojson_parser.dart';
import 'package:provider/provider.dart';
import 'package:iskompas/utils/map/location_provider.dart';
import 'package:iskompas/utils/shared/theme_provider.dart';

// Main entry point of the app, responsible for initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  final accessToken = dotenv.env['ACCESS_TOKEN'];
  if (accessToken == null) {
    throw Exception('ACCESS_TOKEN is missing from the environment variables');
  }
  MapboxOptions.setAccessToken(accessToken);

  try {
    // Load and parse the nodes.geojson file for map data
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

    // Load and parse the facilities.json file
    final facilitiesJsonString =
        await rootBundle.loadString('assets/data/facilities.json');

    if (facilitiesJsonString.isEmpty) {
      throw Exception('Facilities JSON file is empty');
    }

    final facilities = json.decode(facilitiesJsonString) as List<dynamic>;

    // Run the app with the map and facilities data
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocationProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider())
        ],
        child: Iskompas(mapData: mapData, facilities: facilities),
      ),
    );
  } catch (e) {
    throw Exception('Error loading map or facilities data: $e');
  }
}

// Main app widget that holds the map data and facilities
class Iskompas extends StatelessWidget {
  final Map<String, dynamic> mapData;
  final List<dynamic> facilities;
  const Iskompas({super.key, required this.mapData, required this.facilities});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(mapData: mapData, facilities: facilities),
    );
  }
}
