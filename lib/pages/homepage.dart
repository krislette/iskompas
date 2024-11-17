import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // User-selected index
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 16, 17, 16),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color.fromARGB(0, 16, 17, 16),
        color: const Color.fromARGB(255, 101, 27, 27),
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
              color:
                  _selectedIndex == 0 ? const Color(0xFFFFDE00) : Colors.white,
            ),
            label: 'Map',
            labelStyle: TextStyle(
              color:
                  _selectedIndex == 0 ? const Color(0xFFFFDE00) : Colors.white,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.bookmark,
              size: 30,
              color:
                  _selectedIndex == 1 ? const Color(0xFFFFDE00) : Colors.white,
            ),
            label: 'Saved',
            labelStyle: TextStyle(
              color:
                  _selectedIndex == 1 ? const Color(0xFFFFDE00) : Colors.white,
            ),
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.image,
              size: 30,
              color:
                  _selectedIndex == 2 ? const Color(0xFFFFDE00) : Colors.white,
            ),
            label: 'Facilities',
            labelStyle: TextStyle(
              color:
                  _selectedIndex == 2 ? const Color(0xFFFFDE00) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
