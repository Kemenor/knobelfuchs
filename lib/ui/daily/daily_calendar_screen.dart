import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/constants.dart';
import '../../domain/daily.dart';
import '../../l10n/app_localizations.dart';
import '../game/game_controller.dart';
import '../game/game_screen.dart';
import '../providers.dart';
import '../single_flight.dart';
import 'daily_providers.dart';

/// The calendar IS the mode's home (§6.2, mockup 06): every past day
/// playable/resumable, future locked against the device date, archive
/// bounded at the epoch. A missed day is never red — it just waits.
class DailyCalendarScreen extends ConsumerStatefulWidget {
  const DailyCalendarScreen({super.key});

  @override
  ConsumerState<DailyCalendarScreen> createState() =>
      _DailyCalendarScreenState();
}

class _DailyCalendarScreenState extends ConsumerState<DailyCalendarScreen> {
  late DateTime _month; // first of the shown month
  final _flight = SingleFlight(); // one day cell, one GameScreen

  @override
  void initState() {
    super.initState();
    // The injectable clock, same as the providers — a test-frozen or
    // otherwise overridden now must not disagree with the day states.
    final now = ref.read(nowProvider)();
    _month = DateTime(now.year, now.month, 1);
  }

  DateTime get _epochMonth => DateTime(kDailyEpoch.year, kDailyEpoch.month, 1);
  DateTime get _currentMonth {
    final now = ref.read(nowProvider)();
    return DateTime(now.year, now.month, 1);
  }

  bool get _canGoBack => _month.isAfter(_epochMonth);
  bool get _canGoForward => _month.isBefore(_currentMonth);

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  Future<void> _openDay(DayInfo day) => _flight.run(() async {
        final controller = ref.read(gameControllerProvider.notifier);
        final slot = dailySlot(day.date);
        final nav = Navigator.of(context);
        final now = ref.read(nowProvider);
        final dayBefore = DateUtils.dateOnly(now());
        final resumed = await controller.resumeSaved(slot: slot);
        if (!resumed) {
          controller.start(dailyConfig(day.date), slot: slot);
        }
        await nav.push(
            MaterialPageRoute(builder: (_) => const GameScreen()));
        // The screen can be gone by now (deep link popped the stack) — ref
        // on a disposed State throws. And only a crossed midnight needs the
        // recompute; the run's own persists already bump on every move.
        if (!mounted) return;
        if (DateUtils.dateOnly(now()) != dayBefore) {
          ref.read(dailyVersionProvider.notifier).bump();
        }
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final month = ref.watch(dailyMonthProvider(_month));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.modeDaily),
        leading: const BackButton(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _canGoBack ? () => _shiftMonth(-1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM(locale).format(_month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: _canGoForward ? () => _shiftMonth(1) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                _WeekdayHeader(locale: locale),
                const SizedBox(height: 6),
                Expanded(
                  child: month.when(
                    data: (info) => _MonthGrid(info: info, onTap: _openDay),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Center(child: Text('$e')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String locale;
  const _WeekdayHeader({required this.locale});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Monday-first (family convention); 2026-01-05 is a Monday. Calendar
    // arithmetic, not Duration: +24h breaks across DST switches (§6.2).
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Text(
              DateFormat.E(locale)
                  .format(DateTime(2026, 1, 5 + i))
                  .toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final MonthInfo info;
  final void Function(DayInfo) onTap;
  const _MonthGrid({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Monday-first offset: DateTime.weekday is 1 (Mon) … 7 (Sun).
    final leading = info.month.weekday - 1;
    final cells = leading + info.days.length;
    final rows = (cells + 6) ~/ 7;

    return GridView.builder(
      // Explicit padding disables the automatic safe-area inset — add the
      // system nav bar back ourselves.
      padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.viewPaddingOf(context).bottom),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, i) {
        final dayIndex = i - leading;
        if (dayIndex < 0 || dayIndex >= info.days.length) {
          return const SizedBox.shrink();
        }
        return _DayCell(day: info.days[dayIndex], onTap: onTap);
      },
    );
  }
}

class _DayCell extends ConsumerWidget {
  final DayInfo day;
  final void Function(DayInfo) onTap;
  const _DayCell({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(nowProvider)();
    final isToday = day.date.year == now.year &&
        day.date.month == now.month &&
        day.date.day == now.day;
    final locked = day.state == DayState.locked;

    Color border = scheme.outlineVariant;
    Color bg = scheme.surfaceContainerHighest;
    Widget? sub;
    switch (day.state) {
      case DayState.locked:
        bg = Colors.transparent;
        sub = Icon(Icons.lock_outline, size: 13, color: scheme.outline);
      case DayState.waiting:
        sub = null; // an empty day just waits — never red, never a reproach
      case DayState.inProgress:
        sub = _SubText('${day.score} …', scheme.secondary);
      case DayState.played:
        sub = _SubText('${day.score}', scheme.outline);
      case DayState.beaten:
        sub = Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 13, color: scheme.tertiary),
          const SizedBox(width: 2),
          _SubText('${day.score}', scheme.tertiary),
        ]);
    }
    if (isToday) {
      border = scheme.secondary;
      bg = scheme.secondaryContainer.withValues(alpha: .5);
    }

    return Semantics(
      button: !locked,
      label: '${day.date.day}.${day.date.month}.',
      child: Opacity(
        opacity: locked ? .5 : 1,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: locked ? null : () => onTap(day),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: border,
                  width: isToday ? 2 : 1,
                  style: locked ? BorderStyle.none : BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.date.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isToday
                          ? scheme.secondary
                          : locked
                              ? scheme.outline
                              : scheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(
                      height: 14,
                      child: sub ??
                          (isToday
                              ? _SubText(l.today, scheme.secondary)
                              : null)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubText extends StatelessWidget {
  final String text;
  final Color color;
  const _SubText(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
