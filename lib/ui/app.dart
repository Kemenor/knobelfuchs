import 'package:flutter/material.dart';
import 'package:fuchsbau/fuchsbau.dart';

import '../l10n/app_localizations.dart';
import 'home/home_screen.dart';

class KnobelfuchsApp extends StatelessWidget {
  const KnobelfuchsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: fuchsbauTheme(Brightness.light),
      darkTheme: fuchsbauTheme(Brightness.dark),
      themeMode: ThemeMode.system, // dark + light, always (ETHOS)
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
