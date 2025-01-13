import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/navbar.dart';
import 'pages/splash_screen.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const Iskompas());
}

class Iskompas extends StatelessWidget {
  const Iskompas({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), 
    );
  }
}
