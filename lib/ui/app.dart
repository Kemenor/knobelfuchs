import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuchsbau/fuchsbau.dart';

import '../l10n/app_localizations.dart';
import 'home/home_screen.dart';
import 'settings/settings.dart';

class KnobelfuchsApp extends ConsumerWidget {
  const KnobelfuchsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: fuchsbauTheme(Brightness.light, font: settings.font),
      darkTheme: fuchsbauTheme(Brightness.dark, font: settings.font),
      themeMode: settings.themeMode, // dark + light, always (ETHOS)
      locale: settings.localeOverride != null
          ? Locale(settings.localeOverride!)
          : null, // null = follow the system (§10.3)
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
