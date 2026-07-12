/// QR challenge payload (§7): `knobelfuchs://c?v=1&s=<seed>&a=<adds>&h=<hints>&t=<target>`
/// No names, no messages — the target is the personal touch. Scanning
/// pre-fills the parameter sheet; it never auto-starts a game.
library;

import 'game.dart';

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
  final seed = q['s'];
  if (seed == null || seed.isEmpty) return null;

  int? parseBudget(String? raw) => raw == _inf ? null : int.tryParse(raw ?? '');
  final adds = parseBudget(q['a']);
  final hints = parseBudget(q['h']);
  if (q['a'] != _inf && adds == null) return null;
  if (q['h'] != _inf && hints == null) return null;

  final target = q['t'] == null ? null : int.tryParse(q['t']!);
  return GameConfig(seed: seed, adds: adds, hints: hints, target: target);
}
