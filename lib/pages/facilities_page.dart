import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/widgets/custom_search_bar.dart';
import 'package:iskompas/pages/facility_details_page.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  FacilitiesPageState createState() => FacilitiesPageState();
}

class FacilitiesPageState extends State<FacilitiesPage> {
  static const int itemsPerPage = 10;

  late List<dynamic> facilities;
  late List<dynamic> filteredFacilities;
  late TextEditingController searchController;
  bool isLoading = false;
  int currentPage = 0;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    facilities = [];
    filteredFacilities = [];
    searchController = TextEditingController();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadInitialFacilities();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore) {
      loadMoreFacilities();
    }
  }

  Future<void> loadInitialFacilities() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String response =
          await rootBundle.loadString('assets/data/facilities.json');
      final allData = json.decode(response);

      setState(() {
        facilities = allData;
        filteredFacilities = allData.take(itemsPerPage).toList();
        currentPage = 1;
        hasMore = allData.length > itemsPerPage;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadMoreFacilities() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final startIndex = currentPage * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      if (startIndex < facilities.length) {
        final newItems = facilities.sublist(
          startIndex,
          endIndex > facilities.length ? facilities.length : endIndex,
        );

        setState(() {
          filteredFacilities.addAll(newItems);
          currentPage++;
          hasMore = endIndex < facilities.length;
          isLoading = false;
        });
      } else {
        setState(() {
          hasMore = false;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterFacilities(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFacilities =
            facilities.take(currentPage * itemsPerPage).toList();
        hasMore = facilities.length > currentPage * itemsPerPage;
      } else {
        filteredFacilities = facilities
            .where((facility) =>
                facility['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
        hasMore = false; // Prevent loading skeletons during filtering
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              child: filteredFacilities.isEmpty && !isLoading
                  ? const Align(
                      alignment: Alignment(0, -0.2),
                      child: Text(
                        'No matching facility found',
                        style: TextStyle(
                          color: Iskolors.colorGrey,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredFacilities.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= filteredFacilities.length) {
                          return hasMore
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(
                                    child: FacilityRowSkeleton(),
                                  ),
                                )
                              : const SizedBox();
                        }

                        final facility = filteredFacilities[index];
                        return FacilityRow(
                          name: facility['name']!,
                          description: facility['description']!,
                          location: facility['location']!,
                          imagePath: facility['image']!,
                          isLast: index == filteredFacilities.length - 1 &&
                              !hasMore,
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

class CustomCacheManager {
  static final customCacheManager = CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'facilities_cache'),
      fileService: HttpFileService(),
    ),
  );
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
  FacilityRowState createState() => FacilityRowState();
}

class FacilityRowState extends State<FacilityRow> {
  Widget _buildImage(String imagePath, {bool isLarge = false}) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Iskolors.colorDarkGrey,
          child: const Center(
            child:
                SizedBox(width: 20, height: 20, child: FacilityRowSkeleton()),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.broken_image,
          color: Iskolors.colorWhite,
        ),
        cacheManager: CustomCacheManager.customCacheManager,
        memCacheHeight: isLarge ? 1024 : 200,
        memCacheWidth: isLarge ? 1024 : 200,
        maxWidthDiskCache: isLarge ? 1024 : 200,
        maxHeightDiskCache: isLarge ? 1024 : 200,
        fadeOutDuration: const Duration(milliseconds: 0),
        fadeInDuration: const Duration(milliseconds: 0),
        cacheKey: '${imagePath}_${isLarge ? 'large' : 'small'}',
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        cacheHeight: isLarge ? 1024 : 200,
        cacheWidth: isLarge ? 1024 : 200,
        gaplessPlayback: true,
      );
    }
  }

  void _handleFacilityTap(BuildContext context) {
    if (widget.name.toLowerCase() == 'main building') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FacilityDetailsPage(
            name: widget.name,
            description: widget.description,
            location: widget.location,
            imagePath: widget.imagePath,
            isMainBuilding: true,
          ),
        ),
      );
    } else {
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 200.0,
                      child: _buildImage(widget.imagePath, isLarge: true),
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
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 128, 0, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 30.0),
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            color: Iskolors.colorWhite,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleFacilityTap(context),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: const BorderSide(color: Iskolors.colorWhite, width: 0.5),
                bottom: widget.isLast
                    ? const BorderSide(color: Iskolors.colorWhite, width: 1)
                    : const BorderSide(color: Iskolors.colorWhite, width: 0.5),
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
                      color: Iskolors.colorDarkGrey,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImage(widget.imagePath),
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
                            color: Iskolors.colorWhite,
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
                            color: Iskolors.colorGrey,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Iskolors.colorYellow,
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

class FacilityRowSkeleton extends StatelessWidget {
  const FacilityRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Iskolors.colorDarkGrey,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Iskolors.colorDarkGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: Iskolors.colorDarkGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
