import 'package:flutter/material.dart';
import 'package:iskompas/widgets/category_filter.dart';

// A horizontal list of category filters for selecting and displaying specific categories
class CategoryFiltersList extends StatelessWidget {
  final String? selectedCategory;
  final bool isDarkMode;
  final Function(String?) onCategorySelected;
  final VoidCallback clearPolylines;

  const CategoryFiltersList({
    super.key,
    required this.selectedCategory,
    required this.isDarkMode,
    required this.onCategorySelected,
    required this.clearPolylines,
  });

  // Handles tap events on a category filter, clear polylines and update the selected catgory
  void _handleCategoryTap(String category) {
    clearPolylines();
    onCategorySelected(selectedCategory == category ? null : category);
  }

  @override
  Widget build(BuildContext context) {
    // List of categories with their icons, labels, and values
    final categories = [
      {
        'icon': Icons.image,
        'label': 'Facilities',
        'value': 'facility',
      },
      {
        'icon': Icons.work,
        'label': 'Offices',
        'value': 'faculty',
      },
      {
        'icon': Icons.sports,
        'label': 'Sports',
        'value': 'sports',
      },
      {
        'icon': Icons.nature_people,
        'label': 'Parks',
        'value': 'hangout',
      },
      {
        'icon': Icons.flag,
        'label': 'Landmarks',
        'value': 'landmark',
      },
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: categories.map((category) {
          return CategoryFilter(
            icon: category['icon'] as IconData,
            label: category['label'] as String,
            isSelected: selectedCategory == category['value'],
            onTap: () => _handleCategoryTap(category['value'] as String),
            isDarkMode: isDarkMode,
          );
        }).toList(),
      ),
    );
  }
}
