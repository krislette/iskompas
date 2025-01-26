import 'package:flutter/material.dart' hide CarouselController;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/widgets/search_bar.dart';
import 'package:iskompas/models/facility_model.dart';
import 'package:iskompas/utils/saved_facilities_service.dart';
import 'package:iskompas/widgets/navbar.dart';

class SavedPage extends StatefulWidget {
  final List<dynamic> facilities;
  final Map<String, dynamic> mapData;

  const SavedPage({
    super.key,
    required this.facilities,
    required this.mapData,
  });

  @override
  SavedPageState createState() => SavedPageState();
}

class SavedPageState extends State<SavedPage> {
  List<Facility> facilities = [];
  List<Facility> filteredFacilities = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  Color unsaveButtonColor = Iskolors.colorMaroon;
  Color showLocationButtonColor = Iskolors.colorMaroon;

  @override
  void initState() {
    super.initState();
    loadFacilities();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    filterFacilities(_searchController.text);
  }

  void filterFacilities(String query) {
    setState(() {
      filteredFacilities = facilities
          .where((facility) =>
              facility.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> loadFacilities() async {
    setState(() {
      isLoading = true;
    });
    final savedFacilities = await SavedFacilitiesService.getSavedFacilities();

    setState(() {
      facilities = savedFacilities
          .map((facility) => Facility.fromJson(facility))
          .toList();
      filteredFacilities = List.from(facilities);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double searchBarHeight = 80.0;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double availableHeight =
        screenHeight - searchBarHeight - bottomPadding;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Iskolors.colorBlack,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                    horizontal: 16.0,
                  ),
                  child: CustomSearchBar(
                    hintText: 'Search saved...',
                    controller: _searchController,
                    onChanged: (value) {
                      filterFacilities(value);
                    },
                  ),
                ),
                SizedBox(
                  height: availableHeight - 50,
                  child: filteredFacilities.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 80,
                                color: Iskolors.colorGrey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No saved locations yet',
                                style: TextStyle(
                                  color: Iskolors.colorGrey,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : CarouselSlider(
                          options: CarouselOptions(
                            height: availableHeight - 50,
                            enlargeCenterPage: true,
                            autoPlay: false,
                            enableInfiniteScroll: false,
                            viewportFraction: 0.8,
                          ),
                          items: filteredFacilities.map((facility) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: Card(
                                    color: Iskolors.colorBlack,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(10),
                                          ),
                                          child: Image.asset(
                                            facility.imagePath,
                                            width: double.infinity,
                                            height: 380,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  facility.name,
                                                  style: const TextStyle(
                                                    color: Iskolors.colorWhite,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  facility.location,
                                                  style: const TextStyle(
                                                    color: Iskolors
                                                        .colorDirtierWhite,
                                                    fontSize: 15,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                Flexible(
                                                  child: SingleChildScrollView(
                                                    child: Text(
                                                      facility.description,
                                                      style: const TextStyle(
                                                        color: Iskolors
                                                            .colorDirtyWhite,
                                                        fontSize: 15,
                                                      ),
                                                      textAlign:
                                                          TextAlign.justify,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 16.0,
                                              right: 16.0,
                                              top: 3.0,
                                              bottom: 40.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    final removed =
                                                        await SavedFacilitiesService
                                                            .removeFacility(
                                                                context,
                                                                facility.name);
                                                    if (removed) {
                                                      loadFacilities();
                                                    }
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        unsaveButtonColor,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                  ),
                                                  child: const Text(
                                                    'Unsave Location',
                                                    style: TextStyle(
                                                      color:
                                                          Iskolors.colorWhite,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => Navbar(
                                                            mapData:
                                                                widget.mapData,
                                                            facilities: widget
                                                                .facilities,
                                                            initialPageIndex: 0,
                                                            focusFacilityName:
                                                                facility.name),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        showLocationButtonColor,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                  ),
                                                  child: const Text(
                                                    'Show Location',
                                                    style: TextStyle(
                                                      color:
                                                          Iskolors.colorWhite,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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
        ),
      ),
    );
  }
}
