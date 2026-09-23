/// JavaScript number semantics the port depends on.
///
/// The Node engine's arithmetic is IEEE-754 double arithmetic, which Dart
/// shares, but a few *library* functions differ. `Math.round` rounds halves
/// toward positive infinity where Dart's `roundToDouble` rounds them away from
/// zero, and `JSON.stringify` prints an integral double without a decimal
/// point. Both differences are observable in engine output, so both are
/// reproduced here rather than approximated.
library;

/// `Math.round`: halves go toward positive infinity.
double jsRound(double value) {
  if (value.isNaN || value.isInfinite) return value;
  return (value + 0.5).floorToDouble();
}

/// The engine's `mod`, which is always non-negative.
int jsMod(int x, int n) => ((x % n) + n) % n;

/// The engine's `mod` for doubles.
double jsModDouble(double x, double n) => ((x % n) + n) % n;

/// The engine's `clamp` to [-1, 1].
double clampUnit(double x) {
  if (x < -1) return -1;
  if (x > 1) return 1;
  return x;
}

/// The engine's `round`: ten decimal places, via `Math.round`.
double roundTen(double x) => jsRound(x * 1e10) / 1e10;

/// Renders a double the way `JSON.stringify` would type it: an integral value
/// becomes an `int` so the encoded JSON says `25200`, not `25200.0`.
///
/// This matters twice over — golden fixtures are compared field by field, and
/// the `readingKey` is a hash of a JSON encoding.
num jsNumber(double value) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', 'not representable in JSON');
  }
  if (value == value.roundToDouble() && value.abs() < 9007199254740992.0) {
    // `-0` encodes as `0` in JSON.stringify.
    if (value == 0) return 0;
    return value.toInt();
  }
  return value;
}
