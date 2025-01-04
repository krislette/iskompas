import 'package:flutter/material.dart';

class FacilityDetailsPage extends StatelessWidget {
  const FacilityDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Details'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: const Center(
        child: Text(
          '', // Blank content
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
