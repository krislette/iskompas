import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/widgets/custom_search_bar.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'facility_details_page.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  _FacilitiesPageState createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  late List<dynamic> facilities;
  late List<dynamic> filteredFacilities;
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    facilities = [];
    filteredFacilities = [];
    searchController = TextEditingController();
    loadFacilities();
  }

  Future<void> loadFacilities() async {
    final String response = await rootBundle.loadString('assets/facilities.json');
    final data = json.decode(response);
    setState(() {
      facilities = data;
      filteredFacilities = data;
    });
  }

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
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) {
      return Scaffold(
        backgroundColor: Iskolors.colorBlack,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Iskolors.colorBlack,
          elevation: 0,
        ),
        body: const Center(
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
                    location: facility['location']!, // Include location
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
  final String location;
  final String imagePath;
  final bool isLast;

  const FacilityRow({
    super.key,
    required this.name,
    required this.description,
    required this.location,
    required this.imagePath,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FacilityDetailsPage(
              name: name,
              description: description,
              location: location, 
              imagePath: imagePath,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: const BorderSide(color: Colors.white, width: 0.5),
                bottom: isLast
                    ? const BorderSide(color: Colors.white, width: 1)
                    : const BorderSide(color: Colors.white, width: 0.5),
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
                                  const Icon(Icons.broken_image,
                                      color: Colors.white),
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
      ),
    );
  }
}

class FacilityDetailsPage extends StatelessWidget {
  final String name;
  final String description;
  final String location;
  final String imagePath;

  const FacilityDetailsPage({
    super.key,
    required this.name,
    required this.description,
    required this.location,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Load the image from the assets/facilities folder
            Image.asset('assets/$imagePath'),
            
            const SizedBox(height: 20),
         
            Center(
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            
            const SizedBox(height: 10),
            
            Text(
              description,
              style: const TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
            ),
            
            const SizedBox(height: 10),
            
            // Prevent overflow for location text
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis, 
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
