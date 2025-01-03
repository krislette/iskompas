import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/widgets/custom_search_bar.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  _FacilitiesPageState createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  late List<dynamic> facilities; // Original list of all facilities
  late List<dynamic> filteredFacilities; // Filtered list for search results
  late TextEditingController searchController; // Controller for search bar input

  @override
  void initState() {
    super.initState();
    facilities = [];
    filteredFacilities = []; // Initialize filtered list
    searchController = TextEditingController(); // Initialize search controller
    loadFacilities(); // Load the facilities
  }

  // Load the facilities from the JSON file
  Future<void> loadFacilities() async {
    // Load JSON data from assets
    final String response = await rootBundle.loadString('assets/facilities.json');
    final data = json.decode(response);

    // Set both the facilities and filtered list
    setState(() {
      facilities = data;
      filteredFacilities = data; 
    });
  }

  // Filter facilities based on search query
  void filterFacilities(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredFacilities = facilities; 
      });
    } else {
      setState(() {
        filteredFacilities = facilities
            .where((facility) =>
                facility['name'].toLowerCase().contains(query.toLowerCase()))
            .toList(); // Filter based on name
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading indicator if facilities are not yet loaded
    if (facilities.isEmpty) {
      return Scaffold(
        backgroundColor: Iskolors.colorBlack,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Iskolors.colorBlack,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Iskolors.colorBlack,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Iskolors.colorBlack,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom search bar to search through facilities
            CustomSearchBar(
              controller: searchController, 
              hintText: 'Search facilities...',
              onChanged: (value) {
                filterFacilities(value); 
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredFacilities.length,
                itemBuilder: (context, index) {
                  final facility = filteredFacilities[index];
                  return FacilityRow(
                    name: facility['name']!,
                    description: facility['description']!,
                    imagePath: facility['image']!,
                    isLast: index == filteredFacilities.length - 1,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FacilityRow extends StatelessWidget {
  final String name;
  final String description;
  final String imagePath;
  final bool isLast;

  const FacilityRow({
    super.key,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 0.5),
              bottom: isLast
                  ? BorderSide(color: Colors.white, width: 1)
                  : BorderSide(color: Colors.white, width: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imagePath.startsWith('http')
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, color: Colors.white),
                          )
                        : Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.yellow,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
