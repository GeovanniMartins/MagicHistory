import 'package:flutter_test/flutter_test.dart';
import 'package:soundkid/main.dart';

void main() {
  testWidgets('SoundKid smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SoundKidApp());
    expect(find.byType(SoundKidApp), findsOneWidget);
  });
}
