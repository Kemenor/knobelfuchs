/// Re-entrancy guard for async tap handlers: while one flight is running,
/// further calls are ignored. Kills the double-tap / second-row-during-await
/// class of bugs (two GameScreens pushed, a second run started behind the
/// first push) in ONE idiom — the guard wraps the whole handler, so the
/// side effects are suppressed too, not just the navigation.
///
/// One instance per screen, shared by all of that screen's start paths.
class SingleFlight {
  bool _busy = false;

  Future<void> run(Future<void> Function() body) async {
    if (_busy) return;
    _busy = true;
    try {
      await body();
    } finally {
      _busy = false;
    }
  }
}
