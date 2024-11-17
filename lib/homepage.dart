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
      // Adding a curved navigation bar at the bottom of the screen
      bottomNavigationBar: CurvedNavigationBar(
        items: [
          // Navigation bar items will be added here
        ]),
    );
  }
}
