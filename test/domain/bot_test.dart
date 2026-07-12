import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/domain/bot.dart';
import 'package:knobelfuchs/domain/game.dart';

void main() {
  group('baseline bot', () {
    test('is deterministic', () {
      const config = GameConfig(seed: 'bot-test', adds: 5, hints: 5);
      expect(botScore(config), botScore(config));
    });

    test('scores something on any seed', () {
      // The fairness gate guarantees an opening with pairs — the greedy bot
      // always finds at least those.
      for (var i = 0; i < 25; i++) {
        final config = GameConfig(seed: 'bot$i', adds: 5, hints: 5);
        expect(botScore(config), greaterThan(0), reason: 'bot$i');
      }
    });

    test('terminates with a zero add budget too', () {
      const config = GameConfig(seed: 'bot-test', adds: 0, hints: 5);
      expect(botScore(config), greaterThan(0));
    });
  });

  group('targets', () {
    test('round10 rounds to the nearest ten', () {
      expect(round10(94), 90);
      expect(round10(95), 100);
      expect(round10(1840), 1840);
      expect(round10(0), 0);
    });

    test('target = round10(bot × factor)', () {
      const config = GameConfig(seed: 'bot-test', adds: 5, hints: 5);
      final bot = botScore(config);
      expect(targetScore(config, 0.9), round10(bot * 0.9));
      expect(targetScore(config, 1.0), round10(bot));
    });
  });
}
