import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Define the selected index

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 16, 17, 16),
      // Adding a curved navigation bar at the bottom of the screen
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color.fromARGB(0, 16, 17, 16),
        color: const Color.fromARGB(255, 101, 27, 27),
        animationDuration: const Duration(milliseconds: 250),
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Update the selected index on tap
          });
        },
        items: [
          // Home icon
          Icon(
            Icons.map,
            size: 30,
            color: _selectedIndex == 0
                ? const Color.fromARGB(255, 250, 234, 89)
                : Colors.white,
          ),
          // Saved item icon
          Icon(
            Icons.bookmark,
            size: 30,
            color: _selectedIndex == 1
                ? const Color.fromARGB(255, 250, 234, 89)
                : Colors.white,
          ),
          // Images icon
          Icon(
            Icons.image,
            size: 30,
            color: _selectedIndex == 2
                ? const Color.fromARGB(255, 250, 234, 89)
                : Colors.white,
          ),
        ],
      ),
    );
  }
}
