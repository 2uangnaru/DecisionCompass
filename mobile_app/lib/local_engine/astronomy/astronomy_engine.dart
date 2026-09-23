/// The slice of Astronomy Engine 2.1.19 that the calculation engine uses.
///
/// Astronomy Engine is MIT licensed, © Don Cross; see
/// `mobile_app/lib/local_engine/LICENSES.md`. This is a direct port of the
/// call chain behind `Ecliptic(GeoVector(body, date, true)).elon`:
///
///   * Terrestrial Time from Universal Time (Espenak/Meeus ΔT).
///   * VSOP87 truncated series for the six bodies the engine reads.
///   * The Montenbruck/Pfleger lunar series (`CalcMoon`).
///   * IAU 2000B nutation, mean obliquity and IAU 2006 precession.
///   * Light-travel-time and aberration correction.
///
/// Everything else in the upstream library — rise/set searches, eclipses,
/// Pluto's numerical integration, observers on the Earth's surface — is
/// deliberately absent, because the reading path never calls it.
library;

import 'dart:math' as math;

import 'astronomy_data.dart';

const double _pi2 = 2 * math.pi;
const double _arc = 3600 * (180 / math.pi); // arcseconds per radian
const double _asec2rad = 4.848136811095359935899141e-6;
const double _asec360 = 2 * (180 * 60 * 60);
const double degToRad = 0.017453292519943296;
const double radToDeg = 57.295779513082321;
const double kmPerAu = 1.4959787069098932e+8;
const double cAuDay = 173.1446326846693;
const double _earthEquatorialRadiusKm = 6378.1366;
const double _earthEquatorialRadiusAu = _earthEquatorialRadiusKm / kmPerAu;
const double _daysPerTropicalYear = 365.24217;
const double _daysPerMillennium = 365250;

/// Milliseconds from the Unix epoch to the J2000 epoch (2000-01-01T12:00:00Z).
const double _j2000Ms = 946728000000;
const double _millisPerDay = 86400000;

double _frac(double x) => x - x.floorToDouble();

/// Espenak/Meeus ΔT, in seconds, for a Universal Time in J2000 days.
double deltaTEspenakMeeus(double ut) {
  final y = 2000 + ((ut - 14) / _daysPerTropicalYear);
  double u;
  if (y < -500) {
    u = (y - 1820) / 100;
    return -20 + (32 * u * u);
  }
  if (y < 500) {
    u = y / 100;
    final u2 = u * u;
    final u3 = u * u2;
    final u4 = u2 * u2;
    final u5 = u2 * u3;
    final u6 = u3 * u3;
    return 10583.6 -
        1014.41 * u +
        33.78311 * u2 -
        5.952053 * u3 -
        0.1798452 * u4 +
        0.022174192 * u5 +
        0.0090316521 * u6;
  }
  if (y < 1600) {
    u = (y - 1000) / 100;
    final u2 = u * u;
    final u3 = u * u2;
    final u4 = u2 * u2;
    final u5 = u2 * u3;
    final u6 = u3 * u3;
    return 1574.2 -
        556.01 * u +
        71.23472 * u2 +
        0.319781 * u3 -
        0.8503463 * u4 -
        0.005050998 * u5 +
        0.0083572073 * u6;
  }
  if (y < 1700) {
    u = y - 1600;
    final u2 = u * u;
    final u3 = u * u2;
    return 120 - 0.9808 * u - 0.01532 * u2 + u3 / 7129.0;
  }
  if (y < 1800) {
    u = y - 1700;
    final u2 = u * u;
    final u3 = u * u2;
    final u4 = u2 * u2;
    return 8.83 + 0.1603 * u - 0.0059285 * u2 + 0.00013336 * u3 - u4 / 1174000;
  }
  if (y < 1860) {
    u = y - 1800;
    final u2 = u * u;
    final u3 = u * u2;
    final u4 = u2 * u2;
    final u5 = u2 * u3;
    final u6 = u3 * u3;
    final u7 = u3 * u4;
    return 13.72 -
        0.332447 * u +
        0.0068612 * u2 +
        0.0041116 * u3 -
        0.00037436 * u4 +
        0.0000121272 * u5 -
        0.0000001699 * u6 +
        0.000000000875 * u7;
  }
  if (y < 1900) {
    u = y - 1860;
    final u2 = u * u;
    final u3 = u * u2;
    final u4 = u2 * u2;
    final u5 = u2 * u3;
    return 7.62 +
        0.5737 * u -
        0.251754 * u2 +
        0.01680668 * u3 -
        0.0004473624 * u4 +
        u5 / 233174;
  }
  if (y < 1920) {
    u = y - 1900;
    final u2 = u * u;
    final u3 = u * u2;
    final u4 = u2 * u2;
    return -2.79 +
        1.494119 * u -
        0.0598939 * u2 +
        0.0061966 * u3 -
        0.000197 * u4;
  }
  if (y < 1941) {
    u = y - 1920;
    final u2 = u * u;
    final u3 = u * u2;
    return 21.20 + 0.84493 * u - 0.076100 * u2 + 0.0020936 * u3;
  }
  if (y < 1961) {
    u = y - 1950;
    final u2 = u * u;
    final u3 = u * u2;
    return 29.07 + 0.407 * u - u2 / 233 + u3 / 2547;
  }
  if (y < 1986) {
    u = y - 1975;
    final u2 = u * u;
    final u3 = u * u2;
    return 45.45 + 1.067 * u - u2 / 260 - u3 / 718;
  }
  if (y < 2005) {
    u = y - 2000;
    final u2 = u * u;
    final u3 = u * u2;
    final u4 = u2 * u2;
    final u5 = u2 * u3;
    return 63.86 +
        0.3345 * u -
        0.060374 * u2 +
        0.0017275 * u3 +
        0.000651814 * u4 +
        0.00002373599 * u5;
  }
  if (y < 2050) {
    u = y - 2000;
    return 62.92 + 0.32217 * u + 0.005589 * u * u;
  }
  if (y < 2150) {
    u = (y - 1820) / 100;
    return -20 + 32 * u * u - 0.5628 * (2150 - y);
  }
  u = (y - 1820) / 100;
  return -20 + (32 * u * u);
}

double _terrestrialTime(double ut) => ut + deltaTEspenakMeeus(ut) / 86400;

/// An instant, carrying both Universal and Terrestrial Time in J2000 days.
class AstroTime {
  AstroTime(this.ut) : tt = _terrestrialTime(ut);

  /// From milliseconds since the Unix epoch, matching `MakeTime(new Date(ms))`.
  factory AstroTime.fromUnixMs(double ms) =>
      AstroTime((ms - _j2000Ms) / _millisPerDay);

  final double ut;
  final double tt;

  AstroTime addDays(double days) => AstroTime(ut + days);
}

/// A cartesian position in astronomical units.
class AstroVector {
  const AstroVector(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  double length() => _hypot3(x, y, z);
}

// `Math.hypot` is specified to avoid intermediate overflow/underflow, and its
// result can differ from a naive sqrt in the last bits. Dart has no built-in
// three-argument hypot, so the scaling is reproduced here.
double _hypot3(double x, double y, double z) {
  final ax = x.abs();
  final ay = y.abs();
  final az = z.abs();
  final max = math.max(ax, math.max(ay, az));
  if (max == 0) return 0;
  if (max.isInfinite) return double.infinity;
  final rx = ax / max;
  final ry = ay / max;
  final rz = az / max;
  return max * math.sqrt(rx * rx + ry * ry + rz * rz);
}

/// Nutation and obliquity angles for an instant.
class _EarthTilt {
  const _EarthTilt(this.dpsi, this.deps, this.mobl, this.tobl);

  final double dpsi;
  final double deps;
  final double mobl;
  final double tobl;
}

_EarthTilt? _cachedTilt;
double _cachedTiltTt = double.nan;

_EarthTilt _eTilt(AstroTime time) {
  final cached = _cachedTilt;
  if (cached != null && (_cachedTiltTt - time.tt).abs() <= 1.0e-6)
    return cached;
  final nut = _iau2000b(time);
  final meanOb = _meanObliquity(time);
  final tilt = _EarthTilt(nut.$1, nut.$2, meanOb, meanOb + (nut.$2 / 3600));
  _cachedTilt = tilt;
  _cachedTiltTt = time.tt;
  return tilt;
}

/// IAU 2000B nutation, returning `(dpsi, deps)` in arcseconds.
(double, double) _iau2000b(AstroTime time) {
  double mod(double x) => (x % _asec360) * _asec2rad;
  final t = time.tt / 36525;
  final elp = mod(1287104.79305 + t * 129596581.0481);
  final f = mod(335779.526232 + t * 1739527262.8478);
  final d = mod(1072260.70369 + t * 1602961601.2090);
  final om = mod(450160.398036 - t * 6962890.5431);

  var sarg = math.sin(om);
  var carg = math.cos(om);
  var dp = (-172064161.0 - 174666.0 * t) * sarg + 33386.0 * carg;
  var de = (92052331.0 + 9086.0 * t) * carg + 15377.0 * sarg;

  var arg = 2.0 * (f - d + om);
  sarg = math.sin(arg);
  carg = math.cos(arg);
  dp += (-13170906.0 - 1675.0 * t) * sarg - 13696.0 * carg;
  de += (5730336.0 - 3015.0 * t) * carg - 4587.0 * sarg;

  arg = 2.0 * (f + om);
  sarg = math.sin(arg);
  carg = math.cos(arg);
  dp += (-2276413.0 - 234.0 * t) * sarg + 2796.0 * carg;
  de += (978459.0 - 485.0 * t) * carg + 1374.0 * sarg;

  arg = 2.0 * om;
  sarg = math.sin(arg);
  carg = math.cos(arg);
  dp += (2074554.0 + 207.0 * t) * sarg - 698.0 * carg;
  de += (-897492.0 + 470.0 * t) * carg - 291.0 * sarg;

  sarg = math.sin(elp);
  carg = math.cos(elp);
  dp += (1475877.0 - 3633.0 * t) * sarg + 11817.0 * carg;
  de += (73871.0 - 184.0 * t) * carg - 1924.0 * sarg;

  return (-0.000135 + (dp * 1.0e-7), 0.000388 + (de * 1.0e-7));
}

double _meanObliquity(AstroTime time) {
  final t = time.tt / 36525;
  final asec =
      (((((-0.0000000434 * t - 0.000000576) * t + 0.00200340) * t - 0.0001831) *
                  t -
              46.836769) *
          t +
      84381.406);
  return asec / 3600.0;
}

List<double> _oblEclToEquVector(double oblDegrees, List<double> pos) {
  final obl = oblDegrees * degToRad;
  final cosObl = math.cos(obl);
  final sinObl = math.sin(obl);
  return <double>[
    pos[0],
    pos[1] * cosObl - pos[2] * sinObl,
    pos[1] * sinObl + pos[2] * cosObl,
  ];
}

typedef _Matrix = List<List<double>>;

List<double> _rotate(_Matrix rot, List<double> vec) => <double>[
  rot[0][0] * vec[0] + rot[1][0] * vec[1] + rot[2][0] * vec[2],
  rot[0][1] * vec[0] + rot[1][1] * vec[1] + rot[2][1] * vec[2],
  rot[0][2] * vec[0] + rot[1][2] * vec[1] + rot[2][2] * vec[2],
];

/// Which way a frame conversion runs.
enum PrecessDirection { into2000, from2000 }

_Matrix _precessionRot(AstroTime time, PrecessDirection dir) {
  final t = time.tt / 36525;
  var eps0 = 84381.406;
  var psia =
      (((((-0.0000000951 * t + 0.000132851) * t - 0.00114045) * t - 1.0790069) *
              t +
          5038.481507) *
      t);
  var omegaa =
      (((((0.0000003337 * t - 0.000000467) * t - 0.00772503) * t + 0.0512623) *
                  t -
              0.025754) *
          t +
      eps0);
  var chia =
      (((((-0.0000000560 * t + 0.000170663) * t - 0.00121197) * t - 2.3814292) *
              t +
          10.556403) *
      t);

  eps0 *= _asec2rad;
  psia *= _asec2rad;
  omegaa *= _asec2rad;
  chia *= _asec2rad;

  final sa = math.sin(eps0);
  final ca = math.cos(eps0);
  final sb = math.sin(-psia);
  final cb = math.cos(-psia);
  final sc = math.sin(-omegaa);
  final cc = math.cos(-omegaa);
  final sd = math.sin(chia);
  final cd = math.cos(chia);

  final xx = cd * cb - sb * sd * cc;
  final yx = cd * sb * ca + sd * cc * cb * ca - sa * sd * sc;
  final zx = cd * sb * sa + sd * cc * cb * sa + ca * sd * sc;
  final xy = -sd * cb - sb * cd * cc;
  final yy = -sd * sb * ca + cd * cc * cb * ca - sa * cd * sc;
  final zy = -sd * sb * sa + cd * cc * cb * sa + ca * cd * sc;
  final xz = sb * sc;
  final yz = -sc * cb * ca - sa * cc;
  final zz = -sc * cb * sa + cc * ca;

  if (dir == PrecessDirection.into2000) {
    return <List<double>>[
      <double>[xx, yx, zx],
      <double>[xy, yy, zy],
      <double>[xz, yz, zz],
    ];
  }
  return <List<double>>[
    <double>[xx, xy, xz],
    <double>[yx, yy, yz],
    <double>[zx, zy, zz],
  ];
}

List<double> _precession(
  List<double> pos,
  AstroTime time,
  PrecessDirection dir,
) => _rotate(_precessionRot(time, dir), pos);

_Matrix _nutationRot(AstroTime time, PrecessDirection dir) {
  final tilt = _eTilt(time);
  final oblm = tilt.mobl * degToRad;
  final oblt = tilt.tobl * degToRad;
  final psi = tilt.dpsi * _asec2rad;
  final cobm = math.cos(oblm);
  final sobm = math.sin(oblm);
  final cobt = math.cos(oblt);
  final sobt = math.sin(oblt);
  final cpsi = math.cos(psi);
  final spsi = math.sin(psi);

  final xx = cpsi;
  final yx = -spsi * cobm;
  final zx = -spsi * sobm;
  final xy = spsi * cobt;
  final yy = cpsi * cobm * cobt + sobm * sobt;
  final zy = cpsi * sobm * cobt - cobm * sobt;
  final xz = spsi * sobt;
  final yz = cpsi * cobm * sobt - sobm * cobt;
  final zz = cpsi * sobm * sobt + cobm * cobt;

  if (dir == PrecessDirection.from2000) {
    return <List<double>>[
      <double>[xx, xy, xz],
      <double>[yx, yy, yz],
      <double>[zx, zy, zz],
    ];
  }
  return <List<double>>[
    <double>[xx, yx, zx],
    <double>[xy, yy, zy],
    <double>[xz, yz, zz],
  ];
}

List<double> _nutation(
  List<double> pos,
  AstroTime time,
  PrecessDirection dir,
) => _rotate(_nutationRot(time, dir), pos);

// --- VSOP -------------------------------------------------------------------

double _vsopFormula(
  List<List<List<double>>> formula,
  double t,
  bool clampAngle,
) {
  var tpower = 1.0;
  var coord = 0.0;
  for (final series in formula) {
    var sum = 0.0;
    for (final term in series) {
      sum += term[0] * math.cos(term[1] + (t * term[2]));
    }
    var incr = tpower * sum;
    // Longitudes can be hundreds of radians; folding them keeps precision.
    if (clampAngle) incr %= _pi2;
    coord += incr;
    tpower *= t;
  }
  return coord;
}

List<double> _vsopSphereToRect(double lon, double lat, double radius) {
  final rCosLat = radius * math.cos(lat);
  return <double>[
    rCosLat * math.cos(lon),
    rCosLat * math.sin(lon),
    radius * math.sin(lat),
  ];
}

AstroVector _vsopRotate(List<double> eclip) => AstroVector(
  eclip[0] + 0.000000440360 * eclip[1] - 0.000000190919 * eclip[2],
  -0.000000479966 * eclip[0] +
      0.917482137087 * eclip[1] -
      0.397776982902 * eclip[2],
  0.397776982902 * eclip[1] + 0.917482137087 * eclip[2],
);

AstroVector _calcVsop(List<List<List<List<double>>>> model, AstroTime time) {
  final t = time.tt / _daysPerMillennium;
  final lon = _vsopFormula(model[0], t, true);
  final lat = _vsopFormula(model[1], t, false);
  final rad = _vsopFormula(model[2], t, false);
  return _vsopRotate(_vsopSphereToRect(lon, lat, rad));
}

// --- Moon -------------------------------------------------------------------

class _MoonResult {
  const _MoonResult(this.geoEclipLon, this.geoEclipLat, this.distanceAu);

  final double geoEclipLon;
  final double geoEclipLat;
  final double distanceAu;
}

_MoonResult _calcMoon(AstroTime time) {
  final t = time.tt / 36525;
  double sine(double phi) => math.sin(_pi2 * phi);

  final t2 = t * t;
  var dlam = 0.0;
  var ds = 0.0;
  var gam1c = 0.0;
  var sinpi = 3422.7000;

  final s1 = sine(0.19833 + 0.05611 * t);
  final s2 = sine(0.27869 + 0.04508 * t);
  final s3 = sine(0.16827 - 0.36903 * t);
  final s4 = sine(0.34734 - 5.37261 * t);
  final s5 = sine(0.10498 - 5.37899 * t);
  final s6 = sine(0.42681 - 0.41855 * t);
  final s7 = sine(0.14943 - 5.37511 * t);

  final dl0 =
      0.84 * s1 + 0.31 * s2 + 14.27 * s3 + 7.26 * s4 + 0.28 * s5 + 0.24 * s6;
  final dl =
      2.94 * s1 + 0.31 * s2 + 14.27 * s3 + 9.34 * s4 + 1.12 * s5 + 0.83 * s6;
  final dls = -6.40 * s1 - 1.89 * s6;
  final df =
      0.21 * s1 +
      0.31 * s2 +
      14.27 * s3 -
      88.70 * s4 -
      15.30 * s5 +
      0.24 * s6 -
      1.86 * s7;
  final dd = dl0 - dls;
  final dgam =
      (-3332E-9 * sine(0.59734 - 5.37261 * t) -
      539E-9 * sine(0.35498 - 5.37899 * t) -
      64E-9 * sine(0.39943 - 5.37511 * t));

  final l0 =
      _pi2 * _frac(0.60643382 + 1336.85522467 * t - 0.00000313 * t2) +
      dl0 / _arc;
  final l =
      _pi2 * _frac(0.37489701 + 1325.55240982 * t + 0.00002565 * t2) +
      dl / _arc;
  final ls =
      _pi2 * _frac(0.99312619 + 99.99735956 * t - 0.00000044 * t2) + dls / _arc;
  final f =
      _pi2 * _frac(0.25909118 + 1342.22782980 * t - 0.00000892 * t2) +
      df / _arc;
  final d =
      _pi2 * _frac(0.82736186 + 1236.85308708 * t - 0.00000397 * t2) +
      dd / _arc;

  // co[j + 6][i - 1] / si[j + 6][i - 1], mirroring the upstream -6..6 by 1..4
  // arrays.
  final co = List<List<double>>.generate(13, (_) => List<double>.filled(4, 0));
  final si = List<List<double>>.generate(13, (_) => List<double>.filled(4, 0));

  for (var i = 1; i <= 4; i++) {
    final double arg;
    final int max;
    final double fac;
    switch (i) {
      case 1:
        arg = l;
        max = 4;
        fac = 1.000002208;
      case 2:
        arg = ls;
        max = 3;
        fac = 0.997504612 - 0.002495388 * t;
      case 3:
        arg = f;
        max = 4;
        fac = 1.000002708 + 139.978 * dgam;
      default:
        arg = d;
        max = 6;
        fac = 1.0;
    }
    co[0 + 6][i - 1] = 1;
    co[1 + 6][i - 1] = math.cos(arg) * fac;
    si[0 + 6][i - 1] = 0;
    si[1 + 6][i - 1] = math.sin(arg) * fac;
    for (var j = 2; j <= max; j++) {
      final c1 = co[j - 1 + 6][i - 1];
      final s1v = si[j - 1 + 6][i - 1];
      final c2 = co[1 + 6][i - 1];
      final s2v = si[1 + 6][i - 1];
      co[j + 6][i - 1] = c1 * c2 - s1v * s2v;
      si[j + 6][i - 1] = s1v * c2 + c1 * s2v;
    }
    for (var j = 1; j <= max; j++) {
      co[-j + 6][i - 1] = co[j + 6][i - 1];
      si[-j + 6][i - 1] = -si[j + 6][i - 1];
    }
  }

  (double, double) term(int p, int q, int r, int s) {
    var x = 1.0;
    var y = 0.0;
    final indices = <int>[p, q, r, s];
    for (var k = 1; k <= 4; k++) {
      final index = indices[k - 1];
      if (index != 0) {
        final c2 = co[index + 6][k - 1];
        final s2v = si[index + 6][k - 1];
        final nx = x * c2 - y * s2v;
        final ny = y * c2 + x * s2v;
        x = nx;
        y = ny;
      }
    }
    return (x, y);
  }

  for (final row in moonAddSol) {
    final result = term(
      row[4].toInt(),
      row[5].toInt(),
      row[6].toInt(),
      row[7].toInt(),
    );
    dlam += row[0].toDouble() * result.$2;
    ds += row[1].toDouble() * result.$2;
    gam1c += row[2].toDouble() * result.$1;
    sinpi += row[3].toDouble() * result.$1;
  }

  var n = 0.0;
  for (final row in moonAddN) {
    n +=
        row[0].toDouble() *
        term(row[1].toInt(), row[2].toInt(), row[3].toInt(), row[4].toInt()).$2;
  }

  dlam +=
      (0.82 * sine(0.7736 - 62.5512 * t) +
      0.31 * sine(0.0466 - 125.1025 * t) +
      0.35 * sine(0.5785 - 25.1042 * t) +
      0.66 * sine(0.4591 + 1335.8075 * t) +
      0.64 * sine(0.3130 - 91.5680 * t) +
      1.14 * sine(0.1480 + 1331.2898 * t) +
      0.21 * sine(0.5918 + 1056.5859 * t) +
      0.44 * sine(0.5784 + 1322.8595 * t) +
      0.24 * sine(0.2275 - 5.7374 * t) +
      0.28 * sine(0.2965 + 2.6929 * t) +
      0.33 * sine(0.3132 + 6.3368 * t));

  final s = f + ds / _arc;
  final latSeconds =
      (1.000002708 + 139.978 * dgam) *
          (18518.511 + 1.189 + gam1c) *
          math.sin(s) -
      6.24 * math.sin(3 * s) +
      n;

  return _MoonResult(
    _pi2 * _frac((l0 + dlam / _arc) / _pi2),
    (math.pi / (180 * 3600)) * latSeconds,
    (_arc * _earthEquatorialRadiusAu) / (0.999953253 * sinpi),
  );
}

/// Geocentric equatorial J2000 position of the Moon.
AstroVector geoMoon(AstroTime time) {
  final moon = _calcMoon(time);
  final distCosLat = moon.distanceAu * math.cos(moon.geoEclipLat);
  final gepos = <double>[
    distCosLat * math.cos(moon.geoEclipLon),
    distCosLat * math.sin(moon.geoEclipLon),
    moon.distanceAu * math.sin(moon.geoEclipLat),
  ];
  final mpos1 = _oblEclToEquVector(_meanObliquity(time), gepos);
  final mpos2 = _precession(mpos1, time, PrecessDirection.into2000);
  return AstroVector(mpos2[0], mpos2[1], mpos2[2]);
}

/// Heliocentric equatorial J2000 position, for the bodies the engine reads.
AstroVector helioVector(String body, AstroTime time) {
  final model = vsopModels[body];
  if (model != null) return _calcVsop(model, time);
  if (body == 'Sun') return const AstroVector(0, 0, 0);
  if (body == 'Moon') {
    final e = _calcVsop(vsopModels['Earth']!, time);
    final m = geoMoon(time);
    return AstroVector(e.x + m.x, e.y + m.y, e.z + m.z);
  }
  throw ArgumentError.value(body, 'body', 'unsupported in the offline engine');
}

/// Light-travel-time solver, with aberration approximated by back-dating the
/// observer as well as the target.
AstroVector _backdatePosition(
  AstroTime time,
  String observerBody,
  String targetBody,
) {
  var ltime = time;
  for (var iter = 0; iter < 10; iter++) {
    final observerPos = helioVector(observerBody, ltime);
    final targetPos = helioVector(targetBody, ltime);
    final pos = AstroVector(
      targetPos.x - observerPos.x,
      targetPos.y - observerPos.y,
      targetPos.z - observerPos.z,
    );
    final lt = pos.length() / cAuDay;
    if (lt > 1.0) {
      throw StateError('light-travel solver: object is too distant');
    }
    final ltime2 = time.addDays(-lt);
    final dt = (ltime2.tt - ltime.tt).abs();
    if (dt < 1.0e-9) return pos;
    ltime = ltime2;
  }
  throw StateError('light-travel solver did not converge');
}

/// Geocentric equatorial J2000 position, corrected for light travel time and
/// aberration — `GeoVector(body, date, true)`.
AstroVector geoVector(String body, AstroTime time) {
  if (body == 'Earth') return const AstroVector(0, 0, 0);
  if (body == 'Moon') return geoMoon(time);
  return _backdatePosition(time, 'Earth', body);
}

/// True ecliptic longitude of date, in degrees — the `elon` of `Ecliptic()`.
double eclipticLongitude(AstroVector eqj, AstroTime time) {
  final tilt = _eTilt(time);
  final meanPos = _precession(
    <double>[eqj.x, eqj.y, eqj.z],
    time,
    PrecessDirection.from2000,
  );
  final eqd = _nutation(meanPos, time, PrecessDirection.from2000);
  final tobl = tilt.tobl * degToRad;
  final cosOb = math.cos(tobl);
  final sinOb = math.sin(tobl);

  final ex = eqd[0];
  final ey = eqd[1] * cosOb + eqd[2] * sinOb;
  final xyproj = _hypot2(ex, ey);
  var elon = 0.0;
  if (xyproj > 0) {
    elon = radToDeg * math.atan2(ey, ex);
    if (elon < 0) elon += 360;
  }
  return elon;
}

double _hypot2(double x, double y) {
  final ax = x.abs();
  final ay = y.abs();
  final max = math.max(ax, ay);
  if (max == 0) return 0;
  if (max.isInfinite) return double.infinity;
  final rx = ax / max;
  final ry = ay / max;
  return max * math.sqrt(rx * rx + ry * ry);
}
