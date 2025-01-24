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

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final string1 = 'Find your way,';
  final string2 = 'the';
  final string3 = 'isko';
  final string4 = 'way';

  bool showSecondText = false;
  bool showThirdText = false;
  bool showFourthText = false;
  bool showPin = false;
  bool showCompass = false;

  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 4200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut)
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        showCompass = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      setState(() {
        showSecondText = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 3600), () {
      setState(() {
        showThirdText = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 4200), () {
      setState(() {
        showFourthText = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 5000), () {
      setState(() {
        showPin = true;
      });
    });

    _rotationController.forward();

    Timer(const Duration(milliseconds: 6600), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                Navbar(mapData: widget.mapData, facilities: widget.facilities)),
      );
    });
  }


  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MovieTween iskotween = MovieTween()
      ..scene(
              begin: const Duration(milliseconds: 0),
              duration: const Duration(milliseconds: 600))
          .tween('typewriter', IntTween(begin: 0, end: string3.length))
      ..scene(
              begin: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 2500))
          .tween(
              'color',
              ColorTween(
                  begin: Iskolors.colorWhite, end: Iskolors.colorYellow));

    final MovieTween linetween = MovieTween()
      ..scene(
              begin: const Duration(milliseconds: 0),
              duration: const Duration(milliseconds: 3000))
          .tween('animation', Tween<double>(begin: 1, end: 280))
      ..scene(
              begin: const Duration(milliseconds: 2900),
              duration: const Duration(milliseconds: 1500))
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
              duration: Duration(milliseconds: 1600),
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
                    duration: Duration(milliseconds: 600),
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
                    duration: Duration(milliseconds: 600),
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

          // compass logo
          Positioned(
            bottom: 116,
            right: -109,
            child: AnimatedScale(
              scale: showCompass ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOut,
              child: AnimatedBuilder(
              animation: _rotationAnimation,
              child: Image.asset(
                'assets/splash/iskompas_logo.png',
                width: 339,
                height: 339,
              ),
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.141592653589793,
                  child: child,
                );
              },
              ),
            ),
            ),
        ],
      ),
    );
  }
}
