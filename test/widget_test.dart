import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/main.dart';

void main() {
  testWidgets('app shell boots', (tester) async {
    await tester.pumpWidget(const KnobelfuchsApp());
    expect(find.textContaining('Knobelfuchs'), findsOneWidget);
  });
}
