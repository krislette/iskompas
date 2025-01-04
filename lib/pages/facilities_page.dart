import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/widgets/custom_search_bar.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:ui';

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
    final String response =
        await rootBundle.loadString('assets/data/facilities.json');
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

class FacilityRow extends StatefulWidget {
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
  _FacilityRowState createState() => _FacilityRowState();
}

class _FacilityRowState extends State<FacilityRow> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 21, 21, 21),
              contentPadding: const EdgeInsets.all(16.0),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed-size Facility image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 200.0,
                        child: widget.imagePath.startsWith('http')
                            ? Image.network(
                                widget.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image,
                                        color: Colors.white),
                              )
                            : Image.asset(
                                widget.imagePath,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        widget.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.description,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Location text without truncation
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 128, 0, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 30.0),
                          ),
                          child: const Text(
                            "Close",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: const BorderSide(color: Colors.white, width: 0.5),
                bottom: widget.isLast
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
                      child: widget.imagePath.startsWith('http')
                          ? Image.network(
                              widget.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image,
                                      color: Colors.white),
                            )
                          : Image.asset(
                              widget.imagePath,
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
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          textAlign: TextAlign.justify,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
