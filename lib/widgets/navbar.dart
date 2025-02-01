import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:iskompas/pages/map_page.dart';
import 'package:iskompas/pages/saved_page.dart';
import 'package:iskompas/pages/facilities_page.dart';
import 'package:iskompas/utils/shared/set_color.dart';
import 'package:iskompas/utils/shared/colors.dart';

// A bottom navigation bar widget that allows switching between Map, Saved, and Facilities pages
class Navbar extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final List<dynamic> facilities;
  final int initialPageIndex;
  final String? focusFacilityName;

  const Navbar({
    super.key,
    required this.mapData,
    required this.facilities,
    this.initialPageIndex = 0,
    this.focusFacilityName,
  });

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _selectedIndex = 0;
  late final MapPage _mapPage;
  late final FacilitiesPage _facilitiesPage;

  final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();
  final GlobalKey<SavedPageState> _savedPageKey = GlobalKey<SavedPageState>();
  final GlobalKey<FacilitiesPageState> _facilitiesPageKey =
      GlobalKey<FacilitiesPageState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPageIndex;
    // Initialize MapPage with provided data
    _mapPage = MapPage(
      mapData: widget.mapData,
      facilities: widget.facilities,
      focusFacilityName: widget.focusFacilityName,
    );
    // Initialize FacilitiesPage with provided facilities list
    _facilitiesPage = FacilitiesPage(
      key: _facilitiesPageKey,
      facilities: widget.facilities,
    );
  }

  // Clears the search fields on all pages when switching tabs
  void _clearSearchFields() {
    _mapPageKey.currentState?.clearSearch();
    _savedPageKey.currentState?.clearSearch();
    _facilitiesPageKey.currentState?.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Iskolors.colorTransparent,
      // Bottom navigation bar for navigating between pages
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Iskolors.colorTransparent,
        color: Iskolors.colorMaroon,
        animationDuration: const Duration(milliseconds: 200),
        onTap: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          _clearSearchFields();
          setState(() {
            _selectedIndex = index;
            // If the Saved tab is selected, reload the saved facilities list
            if (_selectedIndex == 1) {
              _savedPageKey.currentState?.loadFacilities();
            }
          });
        },
        items: [
          CurvedNavigationBarItem(
            child: Icon(
              Icons.map,
              size: 30,
              color: setColor(0, _selectedIndex),
            ),
            label: 'Map',
            labelStyle: TextStyle(
              color: setColor(0, _selectedIndex),
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.bookmark,
              size: 30,
              color: setColor(1, _selectedIndex),
            ),
            label: 'Saved',
            labelStyle: TextStyle(
              color: setColor(1, _selectedIndex),
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.image,
              size: 30,
              color: setColor(2, _selectedIndex),
            ),
            label: 'Facilities',
            labelStyle: TextStyle(
              color: setColor(2, _selectedIndex),
            ),
          ),
        ],
      ),
      // IndexedStack keeps the state of each page while switching tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _mapPage,
          SavedPage(
            key: _savedPageKey,
            facilities: widget.facilities,
            mapData: widget.mapData,
          ),
          _facilitiesPage,
        ],
      ),
    );
  }
}
