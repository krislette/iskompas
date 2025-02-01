import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:iskompas/utils/shared/colors.dart';
import 'package:iskompas/utils/map/location_provider.dart';
import 'package:iskompas/utils/saved/saved_facilities_service.dart';
import 'package:iskompas/widgets/loc_error_popup.dart';

// A popup widget that appears when a user taps on a map marker, displaying facility details and actions
class MarkerPopup extends StatefulWidget {
  final Point geometry;
  final String title;
  final String description;
  final List<dynamic> facilities;
  final Function(Point, Point) onNavigate;

  const MarkerPopup({
    super.key,
    required this.geometry,
    required this.title,
    required this.description,
    required this.facilities,
    required this.onNavigate,
  });

  @override
  State<MarkerPopup> createState() => _MarkerPopupState();
}

class _MarkerPopupState extends State<MarkerPopup> {
  // Tracks if the facility is saved
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  // Checks if the facility is saved and updates the UI accordingly
  Future<void> _checkIfSaved() async {
    isSaved = await SavedFacilitiesService.isFacilitySaved(widget.title);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Stack(
          clipBehavior: Clip.none,
          // Allows positioning elements outside the main container
          children: [
            // Main content of the popup
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: SizedBox(
                height: 160,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Iskolors.colorDarkShade,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    const Spacer(),
                    // Buttons row
                    Row(
                      children: [
                        // Save button
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Iskolors.colorDarkShade,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () async {
                              final Map<String, dynamic> matchingFacility =
                                  widget.facilities.firstWhere(
                                (facility) =>
                                    (facility['name']?.toLowerCase() ?? '') ==
                                    widget.title.toLowerCase().trim(),
                                orElse: () => <String, dynamic>{},
                              );

                              if (matchingFacility.isEmpty) {
                                return;
                              }

                              // Toggle save/unsave status
                              if (isSaved) {
                                final shouldDelete =
                                    await SavedFacilitiesService.removeFacility(
                                        context, widget.title);
                                if (shouldDelete) {
                                  setModalState(() {
                                    isSaved = false;
                                  });
                                }
                              } else {
                                await SavedFacilitiesService.saveFacility(
                                    matchingFacility);
                                setModalState(() {
                                  isSaved = true;
                                });
                              }
                            },
                            icon: const Icon(Icons.bookmark),
                            color: isSaved
                                ? Iskolors.colorYellow
                                : Iskolors.colorPureWhite,
                            iconSize: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Navigate button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final locationProvider =
                                  Provider.of<LocationProvider>(context,
                                      listen: false);
                              // Check if location is available, if not, request permission
                              if (locationProvider.currentLocation == null) {
                                await locationProvider
                                    .checkLocationPermission();
                                if (locationProvider.currentLocation != null) {
                                  widget.onNavigate(
                                      locationProvider.currentLocation!,
                                      widget.geometry);
                                } else {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      LocationErrorPopup.show(context);
                                    }
                                  });
                                }
                              } else {
                                widget.onNavigate(
                                    locationProvider.currentLocation!,
                                    widget.geometry);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              backgroundColor: Iskolors.colorMaroon,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Navigate",
                              style: TextStyle(
                                color: Iskolors.colorPureWhite,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Floating location icon positioned at the top of the popup
            Positioned(
              top: -30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Iskolors.colorPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pin_drop,
                    color: Iskolors.colorPureWhite,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
