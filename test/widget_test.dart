import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/data/database.dart';
import 'package:knobelfuchs/ui/app.dart';
import 'package:knobelfuchs/ui/game/game_controller.dart';

void main() {
  testWidgets('home shows the three modes', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const KnobelfuchsApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Knobelfuchs'), findsOneWidget);
    expect(find.text('Free Play'), findsOneWidget);
    expect(find.text('Daily Knobel'), findsOneWidget);
    expect(find.text('Adventure'), findsOneWidget);
  });
}
