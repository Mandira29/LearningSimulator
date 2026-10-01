import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:netvisual_academy/main.dart';

void main() {
  testWidgets('NetVisual Academy Startup Smoke Test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Set desktop resolution for test window
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const NetVisualAcademyApp());
    await tester.pump();

    // Verify that the dashboard loads by checking for the branding title.
    expect(find.textContaining('NetVisual'), findsAtLeast(1));

    // Clear repeating animation timers
    await tester.pumpWidget(const SizedBox());
  });
}
