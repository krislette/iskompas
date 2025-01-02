import 'package:flutter/material.dart';
import 'package:iskompas/utils/colors.dart';
import 'package:iskompas/widgets/custom_search_bar.dart'; 

class FacilitiesPage extends StatelessWidget {
  const FacilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Iskolors.colorBlack, 
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Iskolors.colorBlack, 
        elevation: 0, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSearchBar(
              hintText: 'Search facilities...',
              onChanged: (value) {
                print('Search query: $value');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
