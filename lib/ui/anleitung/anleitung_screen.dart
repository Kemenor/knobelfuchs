import 'package:flutter/material.dart';

import '../../domain/constants.dart';
import '../../l10n/app_localizations.dart';

/// Static, illustrated rules (§11) — the scoring table fulfils §4's
/// "transparent, shown in-app" promise. No interactive tutorial; Adventure
/// level 1 is the soft on-ramp.
class AnleitungScreen extends StatelessWidget {
  const AnleitungScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.anleitungTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _Section(
                title: l.ruleGoalTitle,
                body: l.ruleGoalBody,
                child: null,
              ),
              _Section(
                title: l.rulePairTitle,
                body: l.rulePairBody,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _MiniPair('7', '7'),
                    SizedBox(width: 20),
                    _MiniPair('3', '7'),
                    SizedBox(width: 20),
                    _MiniPair('5', '5'),
                  ],
                ),
              ),
              _Section(
                title: l.ruleSightTitle,
                body: l.ruleSightBody,
                child: Column(
                  children: [
                    // Row with see-through ghosts.
                    _MiniRow(cells: const [
                      ('9', _MiniState.hint),
                      ('2', _MiniState.ghost),
                      ('4', _MiniState.ghost),
                      ('1', _MiniState.hint),
                      ('6', _MiniState.normal),
                    ]),
                    const SizedBox(height: 8),
                    // Diagonal on a 3×3.
                    for (final row in const [
                      [('7', _MiniState.hint), ('2', _MiniState.normal), ('8', _MiniState.normal)],
                      [('4', _MiniState.normal), ('5', _MiniState.ghost), ('9', _MiniState.normal)],
                      [('6', _MiniState.normal), ('1', _MiniState.normal), ('3', _MiniState.hint)],
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _MiniRow(cells: row),
                      ),
                  ],
                ),
              ),
              _Section(
                title: l.ruleActionsTitle,
                body: l.ruleActionsBody,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionGlyph(Icons.add_circle_outline, l.actionAdd),
                    const SizedBox(width: 18),
                    _ActionGlyph(Icons.lightbulb_outline, l.actionHint),
                    const SizedBox(width: 18),
                    _ActionGlyph(Icons.undo, l.actionUndo),
                  ],
                ),
              ),
              _Section(
                title: l.ruleScoreTitle,
                body: null,
                child: Column(
                  children: [
                    _ScoreRow(l.scorePair, '+$kPointsPerPair'),
                    _ScoreRow(l.scoreRow, '+$kPointsPerRow'),
                    _ScoreRow(l.scoreClear, '+$kPointsBoardCleared'),
                    _ScoreRow(l.scoreUnusedAdd, '+$kPointsPerUnusedAdd'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.footerOffline,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  final Widget? child;
  const _Section({required this.title, required this.body, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body!,
                style: TextStyle(height: 1.5, color: scheme.onSurfaceVariant)),
          ],
          if (child != null) ...[
            const SizedBox(height: 14),
            Center(child: child),
          ],
        ],
      ),
    );
  }
}

enum _MiniState { normal, ghost, hint }

class _MiniCell extends StatelessWidget {
  final String digit;
  final _MiniState state;
  const _MiniCell(this.digit, this.state);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, border, ink) = switch (state) {
      _MiniState.ghost => (
          Colors.transparent,
          scheme.outlineVariant,
          scheme.outline.withValues(alpha: .55)
        ),
      _MiniState.hint => (
          scheme.primaryContainer,
          scheme.primary,
          scheme.primary
        ),
      _MiniState.normal => (
          scheme.surface,
          scheme.outlineVariant,
          scheme.onSurface
        ),
    };
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: border, width: state == _MiniState.hint ? 2 : 1),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: ink,
          decoration:
              state == _MiniState.ghost ? TextDecoration.lineThrough : null,
          decorationColor: ink,
        ),
      ),
    );
  }
}

class _MiniPair extends StatelessWidget {
  final String a, b;
  const _MiniPair(this.a, this.b);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _MiniCell(a, _MiniState.hint),
      const SizedBox(width: 4),
      _MiniCell(b, _MiniState.hint),
    ]);
  }
}

class _MiniRow extends StatelessWidget {
  final List<(String, _MiniState)> cells;
  const _MiniRow({required this.cells});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _MiniCell(cells[i].$1, cells[i].$2),
        ],
      ],
    );
  }
}

class _ActionGlyph extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionGlyph(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: scheme.secondary),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String points;
  const _ScoreRow(this.label, this.points);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: TextStyle(color: scheme.onSurfaceVariant))),
          Text(
            points,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: scheme.tertiary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
