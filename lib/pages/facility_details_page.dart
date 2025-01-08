import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';

class FacilityDetailsPage extends StatefulWidget {
  final String name;
  final String description;
  final String location;
  final String imagePath;
  final bool isMainBuilding;

  const FacilityDetailsPage({
    super.key,
    required this.name,
    required this.description,
    required this.location,
    required this.imagePath,
    required this.isMainBuilding,
  });

  @override
  State<FacilityDetailsPage> createState() => _FacilityDetailsPageState();
}

class _FacilityDetailsPageState extends State<FacilityDetailsPage> {
  int selectedFloor = 1;
  final int maxFloors = 6;

  Widget _buildRegularFacilityContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              height: 200.0,
              child: Image.asset(
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
                color: Iskolors.colorWhite,
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
              color: Iskolors.colorGrey,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Iskolors.colorWhite),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.location,
                  style: const TextStyle(
                    color: Iskolors.colorWhite,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainBuildingContent() {
    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: maxFloors,
            itemBuilder: (context, index) {
              final floor = index + 1;
              final isSelected = floor == selectedFloor;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedFloor = floor;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected 
                        ? const Color.fromARGB(255, 128, 0, 0)
                        : Iskolors.colorDarkGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Floor $floor',
                    style: TextStyle(
                      color: isSelected 
                          ? Iskolors.colorWhite
                          : Iskolors.colorGrey,
                      fontWeight: isSelected 
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Iskolors.colorWhite, width: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/floor_plans/floor_$selectedFloor.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_not_supported,
                            color: Iskolors.colorGrey,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Floor $selectedFloor plan not available',
                            style: const TextStyle(
                              color: Iskolors.colorGrey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Iskolors.colorBlack,
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(color: Iskolors.colorWhite),
        ),
        backgroundColor: Iskolors.colorBlack,
        iconTheme: const IconThemeData(color: Iskolors.colorWhite),
        elevation: 0,
      ),
      body: widget.isMainBuilding
          ? _buildMainBuildingContent()
          : _buildRegularFacilityContent(),
    );
  }
}