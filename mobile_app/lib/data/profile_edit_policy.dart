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

/// How long a brand-new profile holds its birth date still.
///
/// Shorter than the cooldown after an edit, because the likeliest reason to
/// change a birth date soon after onboarding is that it was typed wrong — and
/// a reader who cannot fix it has a compass built for somebody else.
const Duration birthDateFirstEditDelay = Duration(hours: 2);

/// The wait after a successful birth-date change.
///
/// The longest of the three. Every cycle a reading is built from is anchored
/// to this date, so changing it is the nearest thing the app has to becoming
/// a different person; it should not be something a reader can do twice in an
/// afternoon while looking for a better answer.
const Duration birthDateEditCooldown = Duration(hours: 4);

/// How long before the birth date may be changed, as of [nowUtc].
///
/// Three states, in order:
///
/// * Changed before — [birthDateEditCooldown] from that change.
/// * Never changed, but the profile knows when it was created —
///   [birthDateFirstEditDelay] from then.
/// * Neither — a profile saved by a build that did not record `createdAt`, or
///   one whose stamp was unreadable. Open. Refusing instead would lock those
///   readers out permanently with nothing they could do about it, and the
///   first edit they make starts the normal four-hour wait like anyone's.
///
/// [createdAt] is whatever the profile recorded, which for a profile written
/// by this build is a *local* time. It is converted here, which is right on
/// the device that wrote it; a phone carried across a time-zone boundary
/// inside its first two hours has the gate shift by the offset difference.
/// That is a two-hour UX delay reading slightly short or long, not a
/// correctness problem, and it is not worth rewriting a stored field over.
Duration remainingBirthDateWait({
  required DateTime? createdAt,
  required DateTime? changedAtUtc,
  required DateTime nowUtc,
}) {
  if (changedAtUtc != null) {
    return remainingEditCooldown(
      changedAtUtc: changedAtUtc,
      window: birthDateEditCooldown,
      nowUtc: nowUtc,
    );
  }
  if (createdAt == null) return Duration.zero;
  return remainingEditCooldown(
    changedAtUtc: createdAt,
    window: birthDateFirstEditDelay,
    nowUtc: nowUtc,
  );
}

/// Whether two birth dates name the same day.
///
/// Compared by calendar fields, never by instant: the picker answers with a
/// local midnight, and a stored date read back in another zone can land on a
/// different instant while still being the same birthday. Comparing the
/// `DateTime`s would then read as an edit and start a four-hour wait for a
/// date nobody touched.
bool isSameBirthDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
