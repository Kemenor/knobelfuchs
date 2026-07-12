/// Compact move-log codec for persistence: `m:aId:bId` per match, `a` per
/// add, `;`-separated. The log + seed is the entire game — the board itself
/// is never stored, it replays deterministically (§3.6).
library;

import '../domain/game.dart';

String encodeActions(List<GameAction> actions) => actions
    .map((action) => switch (action) {
          MatchAction(:final aId, :final bId) => 'm:$aId:$bId',
          AddAction() => 'a',
        })
    .join(';');

List<GameAction> decodeActions(String encoded) {
  if (encoded.isEmpty) return [];
  final out = <GameAction>[];
  for (final token in encoded.split(';')) {
    if (token == 'a') {
      out.add(AddAction());
      continue;
    }
    final parts = token.split(':');
    if (parts.length == 3 && parts[0] == 'm') {
      final a = int.tryParse(parts[1]);
      final b = int.tryParse(parts[2]);
      if (a != null && b != null) out.add(MatchAction(a, b));
    }
    // Unknown tokens are dropped — replay skips invalid actions anyway.
  }
  return out;
}
