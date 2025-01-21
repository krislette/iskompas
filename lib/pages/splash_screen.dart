import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';
import 'dart:async';
import 'package:iskompas/widgets/navbar.dart';
import 'package:simple_animations/simple_animations.dart';

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final List<dynamic> facilities;
  const SplashScreen(
      {super.key, required this.mapData, required this.facilities});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final string1 = 'Find your way,';
  final string2 = 'the';
  final string3 = 'isko';
  final string4 = 'way';

  bool showSecondText = false;
  bool showThirdText = false;
  bool showFourthText = false;
  bool showPin = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 2400), () {
      setState(() {
        showSecondText = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 2800), () {
      setState(() {
        showThirdText = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 3200), () {
      setState(() {
        showFourthText = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 4200), () {
      setState(() {
        showPin = true;
      });
    });

    Timer(const Duration(milliseconds: 5000), () {
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
    final MovieTween iskotween = MovieTween()
      ..scene(
              begin: const Duration(milliseconds: 0),
              duration: const Duration(milliseconds: 400))
          .tween('typewriter', IntTween(begin: 0, end: string3.length))
      ..scene(
              begin: const Duration(milliseconds: 700),
              duration: const Duration(milliseconds: 2500))
          .tween(
              'color',
              ColorTween(
                  begin: Iskolors.colorWhite, end: Iskolors.colorYellow));

    final MovieTween linetween = MovieTween()
      ..scene(
              begin: const Duration(milliseconds: 0),
              duration: const Duration(milliseconds: 1700))
          .tween('animation', Tween<double>(begin: 1, end: 280))
      ..scene(
              begin: const Duration(milliseconds: 1700),
              duration: const Duration(milliseconds: 2500))
          .tween(
              'color',
              ColorTween(
                  begin: Iskolors.colorWhite, end: Iskolors.colorYellow));

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/splash/splash_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // First text
          Positioned(
            top: 150,
            left: 10,
            child: TweenAnimationBuilder<int>(
              builder: (BuildContext context, int value, Widget? child) {
                return Text(
                  string1.substring(0, value),
                  style: TextStyle(
                    fontSize: 40.0,
                    fontFamily: 'Coolvetica',
                    color: Iskolors.colorWhite,
                  ),
                );
              },
              duration: Duration(milliseconds: 1200),
              tween: IntTween(begin: 0, end: string1.length),
            ),
          ),

          // Second text
          Positioned(
            top: 215,
            left: 10,
            child: showSecondText
                ? TweenAnimationBuilder<int>(
                    builder: (BuildContext context, int value, Widget? child) {
                      return Text(
                        string2.substring(0, value),
                        style: TextStyle(
                          fontSize: 40.0,
                          fontFamily: 'Coolvetica',
                          color: Iskolors.colorWhite,
                        ),
                      );
                    },
                    duration: Duration(milliseconds: 400),
                    tween: IntTween(begin: 0, end: string2.length),
                  )
                : SizedBox.shrink(),
          ),

          // Third text
          Positioned(
            top: 215,
            left: 80,
            child: showThirdText
                ? PlayAnimationBuilder<Movie>(
                    tween: iskotween,
                    duration: iskotween.duration,
                    builder: (context, value, child) {
                      return Text(
                        string3.substring(0, value.get<int>('typewriter')),
                        style: TextStyle(
                          fontSize: 40.0,
                          fontFamily: 'Coolvetica',
                          color: value.get<Color>('color'),
                        ),
                      );
                    },
                  )
                : SizedBox.shrink(),
          ),

          // Fourth text
          Positioned(
            top: 215,
            left: 155,
            child: showFourthText
                ? TweenAnimationBuilder<int>(
                    builder: (BuildContext context, int value, Widget? child) {
                      return Text(
                        string4.substring(0, value),
                        style: TextStyle(
                          fontSize: 40.0,
                          fontFamily: 'Coolvetica',
                          color: Iskolors.colorWhite,
                        ),
                      );
                    },
                    duration: Duration(milliseconds: 400),
                    tween: IntTween(begin: 0, end: string4.length),
                  )
                : SizedBox.shrink(),
          ),

          // Line
          Positioned(
            top: 213,
            left: 0,
            child: PlayAnimationBuilder<Movie>(
              tween: linetween,
              duration: linetween.duration,
              builder: (context, value, child) {
                return Container(
                  width: value.get<double>('animation'),
                  height: 4,
                  color: value.get<Color>('color'),
                );
              },
            ),
          ),

          // Location Pin
          Positioned(
            top: 176,
            left: 258,
            child: AnimatedScale(
              scale: showPin ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 2500),
              curve: Curves.elasticOut,
              child: Image.asset(
                'assets/splash/location_pin.png',
                width: 40,
                height: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
