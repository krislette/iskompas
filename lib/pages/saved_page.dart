import 'dart:convert';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/widgets/search_bar.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});
  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  List<Facility> facilities = [];

  // State variable to control the button color
  Color unsaveButtonColor = const Color(0xFF5F1C1C);
  Color showLocationButtonColor = const Color(0xFF5F1C1C);

  @override
  void initState() {
    super.initState();
    loadFacilities();
  }

  Future<void> loadFacilities() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/facilities.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        facilities = jsonData.map((json) => Facility.fromJson(json)).toList();
      });
    } catch (e) {
      print('Error loading facilities: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Iskolors.colorBlack,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 16.0,
              ),
              child: CustomSearchBar(
                hintText: 'Search saved...',
                onChanged: (value) {
                  print('Searching for: $value');
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: CarouselSlider(
                options: CarouselOptions(
                  height: double.infinity, // Ensure it adapts
                  enlargeCenterPage: true,
                  autoPlay: false,
                  aspectRatio: 16 / 9,
                  enableInfiniteScroll: true,
                  viewportFraction: 0.8,
                ),
                items: facilities.map((facility) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: Iskolors.colorBlack,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                facility.imagePath,
                                width: MediaQuery.of(context).size.width, // Full width
                                height: 450, 
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    facility.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    facility.description,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.justify,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                // Change the button color when clicked
                                                unsaveButtonColor = unsaveButtonColor == const Color(0xFF5F1C1C)
                                                    ? const Color(0x77581818) 
                                                    : const Color(0xFF5F1C1C);
                                              });
                                              // Add unsave functionality here
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: unsaveButtonColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            child: const Text(
                                              'Unsave Location',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                // Change the button color when clicked
                                                showLocationButtonColor = showLocationButtonColor == const Color(0xFF5F1C1C)
                                                    ? const Color(0x77581818) 
                                                    : const Color(0xFF5F1C1C);
                                              });
                                              // Add show location functionality here
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: showLocationButtonColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            child: const Text(
                                              'Show Location',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Facility {
  final String name;
  final String description;
  final String location;
  final String imagePath;

  Facility({
    required this.name,
    required this.description,
    required this.location,
    required this.imagePath,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      name: json['name'],
      description: json['description'],
      location: json['location'],
      imagePath: json['image'],
    );
  }
}
