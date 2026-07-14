import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drift/drift.dart' show Value;
import 'package:knobelfuchs/data/database.dart';
import 'package:knobelfuchs/domain/adventure.dart';
import 'package:knobelfuchs/domain/daily.dart';
import 'package:knobelfuchs/domain/game.dart';
import 'package:knobelfuchs/l10n/app_localizations.dart';
import 'package:knobelfuchs/ui/app.dart';
import 'package:knobelfuchs/ui/game/game_controller.dart';
import 'package:knobelfuchs/ui/home/home_screen.dart';
import 'package:knobelfuchs/ui/providers.dart';
import 'package:knobelfuchs/ui/settings/settings.dart';

/// Store screenshots, one locale per run (knabberfuchs pattern — the single
/// shot list). Pass the locale with `--dart-define=LOCALE=en|de|fr|it`:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshots_test.dart \
///     --dart-define=LOCALE=de -d DEVICE
///
/// Screenshots land in `screenshots/<locale>/NN_name.png`. Run against a
/// FRESH install (tool/screenshots.sh uninstalls first) — the harness seeds
/// its own marketing state and existing data would bleed into the shots.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const loc = String.fromEnvironment('LOCALE', defaultValue: 'en');

  Future<void> settle(WidgetTester t) async {
    try {
      await t.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 8),
      );
    } catch (_) {
      await t.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('store screenshots', (tester) async {
    tester.platformDispatcher.localeTestValue = Locale(loc);

    // Quiet, primed prefs BEFORE the app builds: no music mid-capture, no
    // first-launch dialog, the target locale pinned in-app.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_on', false);
    await prefs.setDouble('fx_vol', 0);
    await prefs.setBool('anleitung_seen', true);
    await prefs.setString('locale', loc);

    final container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const KnobelfuchsApp(),
    ));
    await settle(tester);

    // ---- seed marketing state ------------------------------------------
    final db = container.read(databaseProvider);
    final now = DateTime.now();

    Future<void> result(String slot, String seed, int score,
        {required bool beaten, int? target}) {
      return db.into(db.runResults).insert(RunResultsCompanion.insert(
            slot: slot,
            seed: seed,
            adds: const Value(5),
            hints: const Value(5),
            target: Value(target),
            score: score,
            cleared: beaten,
            targetBeaten: beaten,
            pairs: 22,
            rows: 3,
            addsUsed: 2,
            hintsUsed: 1,
            durationMs: 8 * 60 * 1000,
            scoring: const Value('originalsOnly'),
            startedAt: now.subtract(const Duration(minutes: 9)),
            endedAt: now,
          ));
    }

    // Daily history: a friendly-looking month — beaten and played days mixed.
    final dailyScores = <int, (int, bool)>{
      // daysAgo: (score, beaten)
      1: (640, true),
      2: (580, true),
      4: (450, false),
      5: (610, true),
      7: (525, false),
      8: (660, true),
    };
    for (final e in dailyScores.entries) {
      final date = now.subtract(Duration(days: e.key));
      await result(dailySeedKey(date), dailySeedKey(date), e.value.$1,
          beaten: e.value.$2, target: 600);
    }

    // Adventure: chapter 1 beaten through level 7 — level 8 is the indigo
    // "next" in the shot.
    for (var level = 1; level <= 7; level++) {
      await result(adventureSlot(level), adventureSeedKey(level),
          kAdventureTargets[level - 1] + 40,
          beaten: true, target: kAdventureTargets[level - 1]);
    }
    container.read(dailyVersionProvider.notifier).bump();
    container.read(adventureVersionProvider.notifier).bump();

    // A free game mid-play: real engine moves mirrored locally so we know the
    // cell ids to tap; ends with a sticky hint (orange) and a selection
    // (indigo) — the three cell states in one frame.
    const config = GameConfig(seed: 'fuchs', adds: 5, hints: 5, target: 610);
    final controller = container.read(gameControllerProvider.notifier);
    controller.start(config);
    final mirror = GameState.fresh(config);
    for (var i = 0; i < 7; i++) {
      final pair = mirror.board.firstPair();
      if (pair == null) break;
      final a = mirror.board.cells[pair.$1].id;
      final b = mirror.board.cells[pair.$2].id;
      controller.tapCell(a);
      controller.tapCell(b);
      mirror.match(a, b);
    }
    controller.requestHint();
    mirror.requestHint();
    final hint = mirror.activeHint;
    final survivor = mirror.board.cells.firstWhere((c) =>
        !c.cleared && c.id != hint?.aId && c.id != hint?.bId);
    controller.tapCell(survivor.id);
    await settle(tester);

    // ---- capture helpers ------------------------------------------------
    await binding.convertFlutterSurfaceToImage();

    Element homeCtx() =>
        tester.element(find.byType(HomeScreen, skipOffstage: false).first);
    AppLocalizations l10n() => AppLocalizations.of(homeCtx())!;

    Future<void> shot(String name) async {
      await settle(tester);
      await binding.takeScreenshot('$loc/$name');
    }

    Future<void> popToHome() async {
      Navigator.of(homeCtx()).popUntil((r) => r.isFirst);
      await settle(tester);
    }

    Future<bool> tapText(String text) async {
      final f = find.text(text);
      if (f.evaluate().isEmpty) return false;
      await tester.ensureVisible(f.first);
      await settle(tester);
      await tester.tap(f.first);
      await settle(tester);
      return true;
    }

    // ---- the shot list (Play cap: 8) -------------------------------------

    // 1. Home — the three modes wearing the triad.
    await popToHome();
    await shot('01_home');

    // 2. The board mid-game: ghosts, orange hint pair, indigo selection.
    try {
      await popToHome();
      if (await tapText(l10n().modeFree)) await shot('02_board');
    } catch (_) {}

    // 3. Daily calendar with history.
    try {
      await popToHome();
      if (await tapText(l10n().modeDaily)) await shot('03_daily');
    } catch (_) {}

    // 4. Adventure level list — emerald chapter, indigo next level.
    try {
      await popToHome();
      if (await tapText(l10n().modeStory)) await shot('04_adventure');
    } catch (_) {}

    // 5. The board in dark mode — first-class dark theme.
    try {
      await popToHome();
      container.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
      await settle(tester);
      if (await tapText(l10n().modeFree)) await shot('05_dark');
      await popToHome();
      container.read(settingsProvider.notifier).setThemeMode(ThemeMode.system);
      await settle(tester);
    } catch (_) {}

    // 6. Settings with the jukebox open — the player owns the music.
    try {
      await popToHome();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await settle(tester);
      await tapText(l10n().jukeboxLabel);
      await shot('06_settings');
    } catch (_) {}
  });
}
