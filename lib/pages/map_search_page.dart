import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iskompas/utils/shared/theme_provider.dart';
import 'package:iskompas/widgets/search_bar.dart';
import 'package:iskompas/utils/shared/colors.dart';

class SearchPage extends StatefulWidget {
  final List<dynamic> facilities;

  const SearchPage({super.key, required this.facilities});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  List<dynamic> filteredFacilities = [];
  TextEditingController searchController = TextEditingController();
  final int _displayLimit = 9;
  FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    filteredFacilities = widget.facilities;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // Always unfocus and clear the keyboard when leaving the page
    searchFocusNode.unfocus();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredFacilities = widget.facilities;
      });
      return;
    }

    setState(() {
      filteredFacilities = widget.facilities
          .where((facility) =>
              facility['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isNightMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isNightMode ? Iskolors.colorBlack : Iskolors.colorWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 11.0, horizontal: 16.0),
              child: Row(
                children: [
                  // Custom Search Bar (full width)
                  Expanded(
                    child: CustomSearchBar(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onChanged: filterSearchResults,
                      hintText: 'Search location...',
                      isDarkMode: isNightMode,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredFacilities.isEmpty
                  ? Center(
                      child: Text(
                        'No matching facility found',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: isNightMode
                              ? Iskolors.colorWhite
                              : Iskolors.colorDarkShade,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredFacilities.length > _displayLimit
                          ? _displayLimit
                          : filteredFacilities.length,
                      itemBuilder: (context, index) {
                        final facility = filteredFacilities[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Iskolors.colorYellow,
                            child: Icon(
                              Icons.location_on,
                              color: Iskolors.colorWhite,
                            ),
                          ),
                          title: Text(
                            facility['name'],
                            style: TextStyle(
                              color: isNightMode
                                  ? Iskolors.colorWhite
                                  : Iskolors.colorDarkShade,
                            ),
                          ),
                          subtitle: Text(
                            facility['location'] ??
                                'No location description available',
                            style: const TextStyle(
                              color: Iskolors.colorGrey,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context, facility);
                          },
                        );
                      },
                    ),
            )
          ],
        ),
      ),
      // Bottom capsule-like back button
      // Inside the SearchPage's build method
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Iskolors.colorMaroon,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: const Text(
            'Back',
            style: TextStyle(
              color: Iskolors.colorWhite,
              fontSize: 16.0,
            ),
          ),
        ),
      ),
    );
  }
}
