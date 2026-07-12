import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/ui/app.dart';

void main() {
  testWidgets('home shows the three modes', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KnobelfuchsApp()));
    await tester.pumpAndSettle();
    expect(find.text('Knobelfuchs'), findsOneWidget);
    expect(find.text('Free Play'), findsOneWidget);
    expect(find.text('Daily Knobel'), findsOneWidget);
    expect(find.text('Adventure'), findsOneWidget);
  });
}
