import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/data/database.dart';
import 'package:knobelfuchs/ui/app.dart';
import 'package:knobelfuchs/ui/audio/audio_service.dart';
import 'package:knobelfuchs/ui/game/game_controller.dart';
import 'package:knobelfuchs/ui/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No platform audio channels in widget tests.
class _FakeAudio with WidgetsBindingObserver implements AudioService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  testWidgets('home shows the three modes', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues({'anleitung_seen': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPrefsProvider.overrideWithValue(prefs),
        audioServiceProvider.overrideWithValue(_FakeAudio()),
      ],
      child: const KnobelfuchsApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Knobelfuchs'), findsOneWidget);
    expect(find.text('Free Play'), findsOneWidget);
    expect(find.text('Daily Knobel'), findsOneWidget);
    expect(find.text('Adventure'), findsOneWidget);
  });

  testWidgets('first launch offers the Anleitung once', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPrefsProvider.overrideWithValue(prefs),
        audioServiceProvider.overrideWithValue(_FakeAudio()),
      ],
      child: const KnobelfuchsApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('First time here?'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('First time here?'), findsNothing);
    expect(prefs.getBool('anleitung_seen'), isTrue);
  });
}
