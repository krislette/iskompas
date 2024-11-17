import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 16, 17, 16),
      // Adding a curved navigation bar at the bottom of the screen
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color.fromARGB(0, 16, 17, 16),
        color: const Color.fromARGB(255, 101, 27, 27),
        animationDuration: const Duration(milliseconds: 450),
        onTap: (index) {
          print(index);
        },
        items: [
          // Home icon
          const Icon(
            Icons.map, 
            size: 30, 
            color: Colors.white
            ), 
          // Saved item icon
          const Icon(
            Icons.bookmark, 
            size: 30, 
            color: Colors.white
            ), 
          // Images icon
          const Icon(
            Icons.image, 
            size: 30, 
            color: Colors.white
            ), 
        ]),
    );
  }
}
