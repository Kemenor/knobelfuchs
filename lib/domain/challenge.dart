/// QR challenge payload (§7): `knobelfuchs://c?v=1&s=<seed>&a=<adds>&h=<hints>&t=<target>`
/// No names, no messages — the target is the personal touch. Scanning
/// pre-fills the parameter sheet; it never auto-starts a game.
library;

import 'constants.dart';
import 'game.dart';
import 'seed.dart';

const String kChallengeScheme = 'knobelfuchs';
const String kChallengeHost = 'c';
const int kChallengeVersion = 1;
const String _inf = 'inf';

Uri encodeChallenge(GameConfig config) => Uri(
      scheme: kChallengeScheme,
      host: kChallengeHost,
      queryParameters: {
        'v': '$kChallengeVersion',
        's': config.seed,
        'a': config.adds?.toString() ?? _inf,
        'h': config.hints?.toString() ?? _inf,
        if (config.target != null) 't': '${config.target}',
      },
    );

/// Returns null for anything that isn't a valid v1 challenge — including
/// codes from a future version (a v2 app keeps reading v1 codes; a v1 app
/// politely declines v2 ones).
GameConfig? decodeChallenge(Uri uri) {
  if (uri.scheme != kChallengeScheme || uri.host != kChallengeHost) return null;
  final q = uri.queryParameters;
  if (int.tryParse(q['v'] ?? '') != kChallengeVersion) return null;
  // The seed travels in normalized form (§7); normalizing again costs
  // nothing on our own codes and disarms hand-crafted ones (a raw ':' could
  // otherwise smuggle a daily:/level: namespace into the sheet).
  final seed = normalizeSeed(q['s'] ?? '');
  if (seed.isEmpty) return null;

  int? parseBudget(String? raw) => raw == _inf ? null : int.tryParse(raw ?? '');
  final adds = parseBudget(q['a']);
  final hints = parseBudget(q['h']);
  if (q['a'] != _inf && adds == null) return null;
  if (q['h'] != _inf && hints == null) return null;
  // §7: values the sheet itself can't produce are typos or hostile — a
  // negative add budget would even disable stuck detection downstream.
  if (adds != null && (adds < 0 || adds > kMaxBudget)) return null;
  if (hints != null && (hints < 0 || hints > kMaxBudget)) return null;

  final target = q['t'] == null ? null : int.tryParse(q['t']!);
  if (q['t'] != null && target == null) return null;
  if (target != null && (target < 1 || target > kMaxScore)) return null;
  return GameConfig(seed: seed, adds: adds, hints: hints, target: target);
}
