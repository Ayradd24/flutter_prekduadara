import 'package:flutter_test/flutter_test.dart';
import 'package:prekduadara/main.dart';

void main() {
  testWidgets('LoginPage loads properly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that brand title exists.
    expect(find.text('PrekDuaDara'), findsOneWidget);
    expect(find.text('MULAI SHIFT'), findsOneWidget);
  });
}
