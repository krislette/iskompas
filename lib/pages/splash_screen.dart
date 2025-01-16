import 'package:flutter/material.dart';
import 'dart:async';
import 'package:iskompas/widgets/navbar.dart';

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final List<dynamic> facilities;
  const SplashScreen(
      {super.key, required this.mapData, required this.facilities});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                Navbar(mapData: widget.mapData, facilities: widget.facilities)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/splash/splash.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
