import 'package:flutter/material.dart';
import 'widgets/navbar.dart';

void main() {
  runApp(const Iskompas());
}

class Iskompas extends StatelessWidget {
  const Iskompas({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Navbar(),
    );
  }
}
