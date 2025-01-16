import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import '../pages/map_page.dart';
import '../pages/saved_page.dart';
import '../pages/facilities_page.dart';
import '../utils/set_color.dart';
import '../utils/colors.dart';

class Navbar extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final List<dynamic> facilities;
  const Navbar({super.key, required this.mapData, required this.facilities});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MapPage(mapData: widget.mapData),
      SavedPage(facilities: widget.facilities),
      FacilitiesPage(facilities: widget.facilities),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Iskolors.colorTransparent,
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Iskolors.colorTransparent,
        color: Iskolors.colorMaroon,
        animationDuration: const Duration(milliseconds: 200),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}
