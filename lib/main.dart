import 'package:flutter/material.dart';
import 'homepage.dart';

void main() {
  runApp(const Iskompas());
}

class Iskompas extends StatelessWidget {
  const Iskompas({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
