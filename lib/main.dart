import 'package:flutter/material.dart';

void main() => runApp(const KnobelfuchsApp());

/// Placeholder shell — Phase 2 builds the real UI on the fuchsbau theme.
/// Phase 1 is the pure engine in lib/domain/.
class KnobelfuchsApp extends StatelessWidget {
  const KnobelfuchsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knobelfuchs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEA7A24)),
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            '🦊 Knobelfuchs — Baustelle',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
