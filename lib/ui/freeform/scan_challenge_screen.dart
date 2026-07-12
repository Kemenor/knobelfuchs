import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/challenge.dart';
import '../../domain/game.dart';
import '../../l10n/app_localizations.dart';

/// Scans a knobelfuchs:// challenge QR (§7). Pops with the decoded config —
/// the caller pre-fills the parameter sheet; a scan never auto-starts a game.
class ScanChallengeScreen extends StatefulWidget {
  const ScanChallengeScreen({super.key});

  @override
  State<ScanChallengeScreen> createState() => _ScanChallengeScreenState();
}

class _ScanChallengeScreenState extends State<ScanChallengeScreen> {
  bool _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final uri = Uri.tryParse(raw);
      if (uri == null) continue;
      final GameConfig? config = decodeChallenge(uri);
      if (config != null) {
        _done = true;
        Navigator.of(context).pop(config);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.scanChallenge)),
      body: MobileScanner(
        onDetect: _onDetect,
        // Never a dead black box: say what's wrong, calmly.
        errorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.no_photography_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? l.cameraDenied
                      : '${error.errorCode.name}: ${error.errorDetails?.message ?? ''}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
