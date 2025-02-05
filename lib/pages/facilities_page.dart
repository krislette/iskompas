import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iskompas/utils/facilities/cache_manager.dart';
import 'package:iskompas/utils/shared/colors.dart';
import 'package:iskompas/widgets/search_bar.dart';
import 'package:iskompas/pages/facility_details_page.dart';
import 'package:iskompas/widgets/facility_row_skeleton.dart';

// Displays a page showing list of facilities with their details
class FacilitiesPage extends StatefulWidget {
  final List<dynamic> facilities;

  const FacilitiesPage({super.key, required this.facilities});

  @override
  FacilitiesPageState createState() => FacilitiesPageState();
}

// Manages state and functionality for the facilities page
class FacilitiesPageState extends State<FacilitiesPage> {
  // Declare/initialize all variables needed for the state
  static const int itemsPerPage = 10;

  late List<dynamic> facilities;
  late List<dynamic> filteredFacilities;

  bool isLoading = false;
  int currentPage = 0;
  bool hasMore = true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Initialize state and set up scroll listener
  @override
  void initState() {
    super.initState();
    facilities = widget.facilities;
    filteredFacilities = [];
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadInitialFacilities();
    });
  }

  // Triggers loading more facilities when user scrolls near bottom
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore) {
      loadMoreFacilities();
    }
  }

  // Loads first page of facilities
  Future<void> loadInitialFacilities() async {
    setState(() {
      isLoading = true;
    });

    try {
      setState(() {
        filteredFacilities = facilities.take(itemsPerPage).toList();
        currentPage = 1;
        hasMore = facilities.length > itemsPerPage;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Loads next page of facilities when scrolled
  Future<void> loadMoreFacilities() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final nextPageStart = currentPage * itemsPerPage;
      final nextPageFacilities =
          facilities.skip(nextPageStart).take(itemsPerPage).toList();

      setState(() {
        filteredFacilities.addAll(nextPageFacilities);
        currentPage++;
        hasMore = facilities.length > currentPage * itemsPerPage;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filters facilities list based on search query
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

  // Clears search input and resets filtered list
  void clearSearch() {
    _searchController.clear();
    filterFacilities('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Iskolors.colorBlack,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Iskolors.colorBlack,
        elevation: 0,
        toolbarHeight: 11,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GestureDetector(
          onTap: () {
            // Dismiss the keyboard when tapping outside the search bar
            FocusScope.of(context).unfocus();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomSearchBar(
                controller: _searchController,
                hintText: 'Search facilities...',
                onChanged: (value) {
                  filterFacilities(value);
                },
              ),
              const SizedBox(height: 15),
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
                    // Main list view displaying facilities with infinite scroll
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            filteredFacilities.length + (hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show loading skeleton at the bottom while fetching more items
                          if (index >= filteredFacilities.length) {
                            return hasMore && _searchController.text.isEmpty
                                ? const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16.0),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for displaying a single facility's information
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

// Manages the state and UI for individual facility row items
class FacilityRowState extends State<FacilityRow> {
  // Builds and configures image widget with caching based on image source type
  Widget _buildImage(String imagePath, {bool isLarge = false}) {
    if (imagePath.startsWith('http')) {
      // Handle network images with caching and placeholder
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
      // Handle local asset images
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        cacheHeight: isLarge ? 1024 : 200,
        cacheWidth: isLarge ? 1024 : 200,
        gaplessPlayback: true,
      );
    }
  }

  // Handles tap events on facility items, showing either a details page or dialog
  void _handleFacilityTap(BuildContext context) {
    // Main building gets a dedicated details page
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
      // Other facilities show details in a dialog
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
    // Builds a tappable facility row
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
