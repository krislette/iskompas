import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/widgets/custom_search_bar.dart';

class FacilitiesPage extends StatelessWidget {
  const FacilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for facilities
    final facilities = [
      {
        'name': 'South Wing',
        'description': 'The south wing of the main building',
      },
      {
        'name': 'West Wing',
        'description': 'The west wing of the main building',
      },
      {
        'name': 'East Wing',
        'description': 'The east wing of the main building',
      },
    ];

    return Scaffold(
      backgroundColor: Iskolors.colorBlack,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Iskolors.colorBlack,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSearchBar(
              hintText: 'Search facilities...',
              onChanged: (value) {
                print('Search query: $value');
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: facilities.length,
                itemBuilder: (context, index) {
                  final facility = facilities[index];
                  return FacilityRow(
                    name: facility['name']!,
                    description: facility['description']!,
                    isLast: index == facilities.length - 1,
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

// Custom widget for each row
class FacilityRow extends StatelessWidget {
  final String name;
  final String description;
  final bool isLast; // Check if it's the last row to omit the bottom border

  const FacilityRow({
    super.key,
    required this.name,
    required this.description,
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
                  color: Colors.grey, // Placeholder for image
                  child: const Icon(
                    Icons.image,
                    color: Colors.white,
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
                          fontStyle: FontStyle.italic
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
