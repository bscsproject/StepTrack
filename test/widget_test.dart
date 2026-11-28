import 'package:flutter_test/flutter_test.dart';
import 'package:step_track/main.dart';

void main() {
  testWidgets('startup error screen displays the startup failure', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupErrorApp(error: 'Test failure'));

    expect(
      find.text('StepTrack could not start.\n\nTest failure'),
      findsOneWidget,
    );
  });
}
