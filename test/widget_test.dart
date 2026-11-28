// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:step_track/main.dart';

void main() {
  testWidgets('StartupErrorApp renders error message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StartupErrorApp(error: 'Test error'));

    expect(find.textContaining('StepTrack could not start.'), findsOneWidget);
    expect(find.textContaining('Test error'), findsOneWidget);
  });
}
