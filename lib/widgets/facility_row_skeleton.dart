import 'package:flutter/material.dart';
import 'package:iskompas/utils/shared/colors.dart';

// A skeleton loading placeholder for facility rows, mimicking the structure of the actual content
class FacilityRowSkeleton extends StatelessWidget {
  const FacilityRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Placeholder for the facility image or icon
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Iskolors.colorDarkGrey,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Iskolors.colorDarkGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: Iskolors.colorDarkGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
