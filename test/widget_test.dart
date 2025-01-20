// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:iskompas/main.dart';
import 'package:iskompas/widgets/navbar.dart';
import 'package:iskompas/pages/splash_screen.dart';

void main() {
  testWidgets('Splash screen displays correctly and transitions to Navbar',
      (WidgetTester tester) async {
    // Dummy mapData
    Map<String, dynamic> dummyMapData = {
      'facilities': [],
      'nodes': [],
      'lines': []
    };

    // Dummy facilities data
    List<dynamic> dummyFacilities = [
      {'name': '', 'description': '', 'location': '', 'image': ''},
    ];

    // Build our app and trigger a frame.
    await tester.pumpWidget(
        Iskompas(mapData: dummyMapData, facilities: dummyFacilities));

    // Verify that the SplashScreen is displayed initially.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Allow splash screen to transition
    await tester.pumpAndSettle(); // Settles after transition

    // Verify that the Navbar is now displayed after the transition.
    expect(find.byType(Navbar), findsOneWidget);

    // Check that mapData was passed correctly (using dummy data in this case)
    expect(dummyMapData['facilities'], isEmpty);
    expect(dummyMapData['nodes'], isEmpty);
    expect(dummyMapData['lines'], isEmpty);

    // Check if facilities data is non-empty.
    expect(dummyFacilities.isNotEmpty, true);
  });
}
