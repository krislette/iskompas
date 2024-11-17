import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import '../pages/map_page.dart';
import '../pages/saved_page.dart';
import '../pages/facilities_page.dart';
import '../utils/set_color.dart';
import '../utils/colors.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  // User-selected index
  int _selectedIndex = 0;

  // List of pages to display based on selected index
  final List<Widget> _pages = [
    const MapPage(),
    const SavedPage(),
    const FacilitiesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Iskolors.colorBlack,
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Iskolors.colorBlack,
        color: Iskolors.colorMaroon,
        animationDuration: const Duration(milliseconds: 200),
        onTap: (index) {
          // Update the selected index on tap
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
      body: _pages[_selectedIndex],
    );
  }
}
