import 'package:flutter/material.dart' hide CarouselController;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/widgets/search_bar.dart';
import 'package:iskompas/models/facility_model.dart';
import 'package:iskompas/utils/saved_facilities_service.dart';

class SavedPage extends StatefulWidget {
  final List<dynamic> facilities;
  const SavedPage({super.key, required this.facilities});

  @override
  SavedPageState createState() => SavedPageState();
}

class SavedPageState extends State<SavedPage> {
  List<Facility> facilities = [];
  bool isLoading = true;

  Color unsaveButtonColor = Iskolors.colorMaroon;
  Color showLocationButtonColor = Iskolors.colorMaroon;

  @override
  void initState() {
    super.initState();
    loadFacilities();
  }

  Future<void> loadFacilities() async {
    setState(() {
      isLoading = true;
    });
    final savedFacilities = await SavedFacilitiesService.getSavedFacilities();

    if (savedFacilities.isEmpty) {
      print("No saved facilities found");
    }

    setState(() {
      facilities = savedFacilities
          .map((facility) => Facility.fromJson(facility))
          .toList();
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
            Expanded(
              child: facilities.isEmpty
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
                      items: facilities.map((facility) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              child: Card(
                                color: Iskolors.colorBlack,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Column(
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
                                                Expanded(
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
                                              bottom: 57.0),
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
                                                      loadFacilities(); // Reload the list
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
                                                    setState(() {
                                                      showLocationButtonColor =
                                                          showLocationButtonColor ==
                                                                  Iskolors
                                                                      .colorMaroon
                                                              ? Iskolors
                                                                  .colorDarkerMaroon
                                                              : Iskolors
                                                                  .colorMaroon;
                                                    });
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
                                    );
                                  },
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
    );
  }
}
