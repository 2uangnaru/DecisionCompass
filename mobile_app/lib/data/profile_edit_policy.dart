/// How long Profile holds a birth field still after it has been changed.
///
/// These are *UX* cooldowns: they exist so a reader cannot sit on the Profile
/// screen nudging their birth hour until a reading comes out the way they
/// want, which would turn a symbolic reading into a slot machine. They are
/// stored in the same local file as the profile and are trivially clearable by
/// anyone who wants to; nothing downstream treats them as a guarantee, and no
/// calculation consults them.
///
/// Deliberately not in the engine. The engine is a pure function of a profile
/// and an instant, and it must stay able to replay any historical reading;
/// see section 10 of `CLAUDE.md`.
library;

/// The wait after a successful birth-time change.
const Duration birthTimeEditCooldown = Duration(hours: 2);

/// The wait after a successful birth-country change. Shorter than the birth
/// time's: the country moves the candidate timezone, which is a coarser input
/// than the hour, and getting it wrong is a likelier honest mistake.
const Duration birthCountryEditCooldown = Duration(hours: 1);

/// How much of [window] is left after a change made at [changedAtUtc], as of
/// [nowUtc]. `Duration.zero` means the field is editable.
///
/// A null [changedAtUtc] is the never-changed state, which is always
/// editable — that is what lets the first edit happen immediately.
///
/// The result is clamped to `[0, window]`. The upper clamp matters: a device
/// whose clock is moved backwards (or a record copied from a device in the
/// future) would otherwise compute a negative elapsed time and lock the field
/// for days. Clamping makes the worst case one ordinary window.
Duration remainingEditCooldown({
  required DateTime? changedAtUtc,
  required Duration window,
  required DateTime nowUtc,
}) {
  if (changedAtUtc == null) return Duration.zero;
  final elapsed = nowUtc.toUtc().difference(changedAtUtc.toUtc());
  if (elapsed >= window) return Duration.zero;
  if (elapsed.isNegative) return window;
  return window - elapsed;
}

/// Whether a field changed at [changedAtUtc] may be changed again now.
///
/// Exactly at the boundary the field is open: a reader told "2 hours" who
/// comes back at 2 hours should find it open, not one tick short.
bool canEditNow({
  required DateTime? changedAtUtc,
  required Duration window,
  required DateTime nowUtc,
}) =>
    remainingEditCooldown(
      changedAtUtc: changedAtUtc,
      window: window,
      nowUtc: nowUtc,
    ) ==
    Duration.zero;
