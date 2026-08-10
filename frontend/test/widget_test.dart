import 'package:flutter_test/flutter_test.dart';
import 'package:netvisual_academy/main.dart';

void main() {
  testWidgets('NetVisual Academy Startup Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NetVisualAcademyApp());

    // Verify that the dashboard loads by checking for the branding title.
    expect(find.text('NetVisual Academy'), findsOneWidget);
  });
}
