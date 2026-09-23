/// Offline IANA time zone database.
///
/// This is a faithful Dart re-implementation of the small part of
/// `moment-timezone` that the Node calculation engine actually uses: unpacking
/// the bundled zone records, resolving links, looking a UTC offset up for an
/// instant, and mapping countries to zones. The packed strings in
/// [tzdb_data.dart] are copied verbatim from the same
/// `moment-timezone/data/packed/latest.json` the Node engine loads, so both
/// engines see identical transitions and report the same
/// [tzdbVersion].
///
/// Only the read paths the engine needs are implemented. Wall-clock parsing
/// with moment's `moveAmbiguousForward` / `moveInvalidForward` policies is
/// deliberately absent: the engine never relies on them, it enumerates
/// candidate offsets explicitly instead (see `local_time.dart`).
library;

import 'tzdb_data.dart';

export 'tzdb_data.dart' show tzdbVersion;

/// One unpacked IANA zone: a list of UTC offsets and the instants at which
/// each one stops applying.
class TzZone {
  TzZone._(this.name, this.abbrs, this.offsets, this.untils, this.population);

  final String name;
  final List<String> abbrs;

  /// Offsets in **minutes to add to local time to get UTC** — moment's sign
  /// convention, i.e. the negation of the usual UTC offset. Entry `i` applies
  /// until `untils[i]`.
  final List<double> offsets;

  /// Exclusive upper bound instants in milliseconds since the epoch. The last
  /// entry is always [double.infinity].
  final List<double> untils;

  final int population;

  /// Index of the offset in force at [ms], or null when [ms] is past the end
  /// of the table (which cannot happen while the last until is infinite).
  int? indexFor(num ms) {
    final index = _closest(ms.toDouble(), untils);
    return index >= 0 ? index : null;
  }

  /// moment's raw offset value for [ms], in its own sign convention.
  double rawOffsetMinutesAt(num ms) => offsets[indexFor(ms)!];

  /// The real UTC offset at [ms] in minutes, positive east of Greenwich.
  ///
  /// This reproduces moment-timezone's `updateOffset` round trip, including
  /// its legacy "an offset smaller than 16 must have been given in hours"
  /// heuristic, which is observable for pre-1900s LMT offsets.
  double utcOffsetMinutesAt(num ms) {
    var offset = rawOffsetMinutesAt(ms);
    if (offset.abs() < 16) offset = offset / 60;
    var input = -offset;
    if (input.abs() < 16) input = input * 60;
    return input;
  }
}

/// Mirrors moment-timezone's `closest`: the index of the interval containing
/// [target], or -1 when it is beyond the final until.
int _closest(double target, List<double> untils) {
  final length = untils.length;
  if (target < untils[0]) return 0;
  if (length > 1 &&
      untils[length - 1].isInfinite &&
      target >= untils[length - 2]) {
    return length - 1;
  }
  if (target >= untils[length - 1]) return -1;

  var lo = 0;
  var hi = length - 1;
  while (hi - lo > 1) {
    final mid = (lo + hi) ~/ 2;
    if (untils[mid] <= target) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return hi;
}

int _charCodeToInt(int charCode) {
  if (charCode > 96) return charCode - 87;
  if (charCode > 64) return charCode - 29;
  return charCode - 48;
}

/// moment's base-60 packing, which allows a fractional part after a `.`.
double _unpackBase60(String value) {
  if (value.isEmpty) return 0;
  var sign = 1.0;
  var start = 0;
  if (value.codeUnitAt(0) == 45) {
    start = 1;
    sign = -1.0;
  }
  final dot = value.indexOf('.');
  final whole = dot < 0 ? value : value.substring(0, dot);
  final fractional = dot < 0 ? '' : value.substring(dot + 1);

  var out = 0.0;
  for (var i = start; i < whole.length; i++) {
    out = 60 * out + _charCodeToInt(whole.codeUnitAt(i));
  }
  var multiplier = 1.0;
  for (var i = 0; i < fractional.length; i++) {
    multiplier = multiplier / 60;
    out += _charCodeToInt(fractional.codeUnitAt(i)) * multiplier;
  }
  return out * sign;
}

TzZone _unpack(String packed) {
  final data = packed.split('|');
  final abbrNames = data[1].split(' ');
  final offsetValues = data[2].split(' ').map(_unpackBase60).toList();
  final indices = data[3]
      .split('')
      .map((c) => _unpackBase60(c).toInt())
      .toList();
  final untilValues = data[4].split(' ').map(_unpackBase60).toList();

  // `intToUntil`: differences in minutes become absolute milliseconds, and the
  // final entry becomes infinite.
  final untils = List<double>.filled(indices.length, 0);
  for (var i = 0; i < indices.length; i++) {
    final previous = i == 0 ? 0.0 : untils[i - 1];
    // A trailing until is omitted from the packed string; it is replaced by
    // infinity below, exactly as moment's `intToUntil` does.
    final delta = i < untilValues.length ? untilValues[i] : 0.0;
    untils[i] = (previous + delta * 60000).roundToDouble();
  }
  untils[indices.length - 1] = double.infinity;

  return TzZone._(
    data[0],
    <String>[for (final index in indices) abbrNames[index]],
    <double>[for (final index in indices) offsetValues[index]],
    untils,
    data.length > 5 ? ((double.tryParse(data[5]) ?? 0).toInt()) : 0,
  );
}

final Map<String, String> _linkTargets = () {
  final map = <String, String>{};
  for (final link in tzdbPackedLinks) {
    final parts = link.split('|');
    map[_normalizeName(parts[1])] = parts[0];
  }
  return map;
}();

/// Canonical spelling for each normalized id, so a link keeps its own name.
final Map<String, String> _displayNames = () {
  final map = <String, String>{};
  for (final packed in tzdbPackedZones) {
    final name = packed.substring(0, packed.indexOf('|'));
    map[_normalizeName(name)] = name;
  }
  for (final link in tzdbPackedLinks) {
    final alias = link.split('|')[1];
    map[_normalizeName(alias)] = alias;
  }
  return map;
}();

final Map<String, String> _packedByName = () {
  final map = <String, String>{};
  for (final packed in tzdbPackedZones) {
    map[_normalizeName(packed.substring(0, packed.indexOf('|')))] = packed;
  }
  return map;
}();

/// Country code to zone ids, in the order the packed database lists them.
final Map<String, List<String>> _countryZones = () {
  final map = <String, List<String>>{};
  for (final entry in tzdbPackedCountries) {
    final parts = entry.split('|');
    map[parts[0].toUpperCase()] = parts[1].split(' ');
  }
  return map;
}();

final List<String> _countryNames = List<String>.unmodifiable(
  _countryZones.keys,
);

final Map<String, TzZone> _zoneCache = <String, TzZone>{};

String _normalizeName(String name) => name.toLowerCase().replaceAll('/', '_');

/// Resolves an IANA zone id (including links such as `Asia/Saigon`), or null
/// when the id is unknown.
///
/// Mirrors moment's `getZone`, which follows a link exactly one level deep and
/// keeps the alias's own display name.
TzZone? lookupZone(String? name) {
  if (name == null) return null;
  final key = _normalizeName(name);
  final cached = _zoneCache[key];
  if (cached != null) return cached;

  final packed = _packedByName[key];
  if (packed != null) {
    final zone = _unpack(packed);
    _zoneCache[key] = zone;
    return zone;
  }

  final target = _linkTargets[key];
  if (target == null) return null;
  final linked = lookupZone(target);
  if (linked == null) return null;
  final alias = TzZone._(
    _displayNames[key] ?? target,
    linked.abbrs,
    linked.offsets,
    linked.untils,
    linked.population,
  );
  _zoneCache[key] = alias;
  return alias;
}

/// True when [name] names a zone the bundled database knows.
bool isValidZone(String? name) => lookupZone(name) != null;

/// Every ISO country code the database maps to at least one zone, in the
/// database's own order — matching `moment.tz.countries()`.
List<String> tzdbCountries() => _countryNames;

/// Zones for a country code, sorted lexicographically, matching
/// `moment.tz.zonesForCountry()`. Null when the code is unknown.
List<String>? zonesForCountry(String code) {
  final zones = _countryZones[code];
  if (zones == null) return null;
  return List<String>.of(zones)..sort();
}
