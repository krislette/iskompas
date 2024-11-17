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
      backgroundColor: Color(222222),
      // Adding a curved navigation bar at the bottom of the screen
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Color(222222),
        color: Color.fromARGB(255, 101, 27, 27),
        animationDuration: Duration(milliseconds: 450),
        onTap: (index) {
          print(index);
        },
        items: [
          // Home icon
          Icon(
            Icons.map, 
            size: 30, 
            color: Colors.white
            ), 
          // Saved item icon
          Icon(
            Icons.bookmark, 
            size: 30, 
            color: Colors.white
            ), 
          // Images icon
          Icon(
            Icons.image, 
            size: 30, 
            color: Colors.white
            ), 
        ]),
    );
  }
}
