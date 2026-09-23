/// Port of lunar-javascript's `ShouXingUtil` (寿星天文历).
///
/// Produces solar-term and new-moon instants as Julian days relative to J2000,
/// in the UTC+08 reference meridian the Chinese civil calendar uses. Upstream
/// is MIT licensed, © 6tail; the numeric series live in
/// [calendar_data.dart] and are copied verbatim from the pinned package.
///
/// Only the entry points the calculation engine reaches are implemented:
/// [calcQi], [calcShuo] and [qiAccurate2], plus everything they call.
library;

import 'dart:math' as math;

import 'calendar_data.dart';

const double _piTimes2 = 2 * math.pi;
const double _oneThird = 1.0 / 3;
const double _secondPerDay = 86400;
const double _secondPerRad = 648000 / math.pi;

double _nutationLon2(double t) {
  var a = -1.742 * t;
  final t2 = t * t;
  var dl = 0.0;
  for (var i = 0; i < nutB.length; i += 5) {
    dl +=
        (nutB[i + 3] + a) *
        math.sin(nutB[i] + nutB[i + 1] * t + nutB[i + 2] * t2);
    a = 0;
  }
  return dl / 100 / _secondPerRad;
}

double _eLon(double t, int n) {
  t /= 10;
  var v = 0.0;
  var tn = 1.0;
  const pn = 1;
  final m0 = xl0[pn + 1] - xl0[pn];
  for (var i = 0; i < 6; i++, tn *= t) {
    final n1 = xl0[pn + i].floor();
    final n2 = xl0[pn + 1 + i].floor();
    final n0 = n2 - n1;
    if (n0 == 0) continue;
    int m;
    if (n < 0) {
      m = n2;
    } else {
      m = (3 * n * n0 / m0 + 0.5).floor() + n1;
      if (i != 0) m += 3;
      if (m > n2) m = n2;
    }
    var c = 0.0;
    for (var j = n1; j < m; j += 3) {
      c += xl0[j] * math.cos(xl0[j + 1] + t * xl0[j + 2]);
    }
    v += c * tn;
  }
  v /= xl0[0];
  final t2 = t * t;
  v += (-0.0728 - 2.7702 * t - 1.1019 * t2 - 0.0996 * t2 * t) / _secondPerRad;
  return v;
}

double _mLon(double t, int n) {
  final ob = xl1;
  final obl = ob[0].length;
  var tn = 1.0;
  var v = 0.0;
  var t2 = t * t;
  var t3 = t2 * t;
  var t4 = t3 * t;
  final t5 = t4 * t;
  final tx = t - 10;

  v +=
      (3.81034409 +
          8399.684730072 * t -
          3.319e-05 * t2 +
          3.11e-08 * t3 -
          2.033e-10 * t4) *
      _secondPerRad;
  v +=
      5028.792262 * t +
      1.1124406 * t2 +
      0.00007699 * t3 -
      0.000023479 * t4 -
      0.0000000178 * t5;
  if (tx > 0) v += -0.866 + 1.43 * tx + 0.054 * tx * tx;

  t2 /= 1e4;
  t3 /= 1e8;
  t4 /= 1e8;

  var terms = n * 6;
  if (terms < 0) terms = obl;

  for (var i = 0; i < ob.length; i++, tn *= t) {
    final f = ob[i];
    final l = f.length;
    var m = (terms * l / obl + 0.5).floor();
    if (i > 0) m += 6;
    if (m >= l) m = l;
    var c = 0.0;
    for (var j = 0; j < m; j += 6) {
      c +=
          f[j] *
          math.cos(
            f[j + 1] +
                t * f[j + 2] +
                t2 * f[j + 3] +
                t3 * f[j + 4] +
                t4 * f[j + 5],
          );
    }
    v += c * tn;
  }
  return v / _secondPerRad;
}

double _gxcSunLon(double t) {
  final t2 = t * t;
  final v = -0.043126 + 628.301955 * t - 0.000002732 * t2;
  final e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t2;
  return -20.49552 * (1 + e * math.cos(v)) / _secondPerRad;
}

double _ev(double t) {
  final f = 628.307585 * t;
  return 628.332 +
      21 * math.sin(1.527 + f) +
      0.44 * math.sin(1.48 + f * 2) +
      0.129 * math.sin(5.82 + f) * t +
      0.00055 * math.sin(4.21 + f) * t * t;
}

double _saLon(double t, int n) =>
    _eLon(t, n) + _nutationLon2(t) + _gxcSunLon(t) + math.pi;

double _dtExt(double y, double jsd) {
  final dy = (y - 1820) / 100;
  return -20 + jsd * dy * dy;
}

double _dtCalc(double y) {
  final size = dtAt.length;
  final y0 = dtAt[size - 2];
  final t0 = dtAt[size - 1];
  if (y >= y0) {
    const jsd = 31.0;
    if (y > y0 + 100) return _dtExt(y, jsd);
    return _dtExt(y, jsd) - (_dtExt(y0, jsd) - t0) * (y0 + 100 - y) / 100;
  }
  var i = 0;
  for (; i < size; i += 5) {
    if (y < dtAt[i + 5]) break;
  }
  final t1 = (y - dtAt[i]) / (dtAt[i + 5] - dtAt[i]) * 10;
  final t2 = t1 * t1;
  final t3 = t2 * t1;
  return dtAt[i + 1] + dtAt[i + 2] * t1 + dtAt[i + 3] * t2 + dtAt[i + 4] * t3;
}

double _dtT(double t) => _dtCalc(t / 365.2425 + 2000) / _secondPerDay;

double _mv(double t) {
  var v =
      8399.71 - 914 * math.sin(0.7848 + 8328.691425 * t + 0.0001523 * t * t);
  v -=
      179 * math.sin(2.543 + 15542.7543 * t) +
      160 * math.sin(0.1874 + 7214.0629 * t) +
      62 * math.sin(3.14 + 16657.3828 * t) +
      34 * math.sin(4.827 + 16866.9323 * t) +
      22 * math.sin(4.9 + 23871.4457 * t) +
      12 * math.sin(2.59 + 14914.4523 * t) +
      7 * math.sin(0.23 + 6585.7609 * t) +
      5 * math.sin(0.9 + 25195.624 * t) +
      5 * math.sin(2.32 - 7700.3895 * t) +
      5 * math.sin(3.88 + 8956.9934 * t) +
      5 * math.sin(0.49 + 7771.3771 * t);
  return v;
}

double _saLonT(double w) {
  var v = 628.3319653318;
  var t = (w - 1.75347 - math.pi) / v;
  v = _ev(t);
  t += (w - _saLon(t, 10)) / v;
  v = _ev(t);
  t += (w - _saLon(t, -1)) / v;
  return t;
}

double _msaLon(double t, int mn, int sn) =>
    _mLon(t, mn) + (-3.4E-6) - (_eLon(t, sn) + _gxcSunLon(t) + math.pi);

double _msaLonT(double w) {
  var v = 7771.37714500204;
  var t = (w + 1.08472) / v;
  t += (w - _msaLon(t, 3, 3)) / v;
  v = _mv(t) - _ev(t);
  t += (w - _msaLon(t, 20, 10)) / v;
  t += (w - _msaLon(t, -1, 60)) / v;
  return t;
}

double _saLonT2(double w) {
  const v = 628.3319653318;
  var t = (w - 1.75347 - math.pi) / v;
  t -=
      (0.000005297 * t * t +
          0.0334166 * math.cos(4.669257 + 628.307585 * t) +
          0.0002061 * math.cos(2.67823 + 628.307585 * t) * t) /
      v;
  t +=
      (w -
          _eLon(t, 8) -
          math.pi +
          (20.5 + 17.2 * math.sin(2.1824 - 33.75705 * t)) / _secondPerRad) /
      v;
  return t;
}

double _msaLonT2(double w) {
  var v = 7771.37714500204;
  var t = (w + 1.08472) / v;
  var t2 = t * t;
  t -=
      (-0.00003309 * t2 +
          0.10976 * math.cos(0.784758 + 8328.6914246 * t + 0.000152292 * t2) +
          0.02224 * math.cos(0.18740 + 7214.0628654 * t - 0.00021848 * t2) -
          0.03342 * math.cos(4.669257 + 628.307585 * t)) /
      v;
  t2 = t * t;
  final l =
      _mLon(t, 20) -
      (4.8950632 +
          628.3319653318 * t +
          0.000005297 * t2 +
          0.0334166 * math.cos(4.669257 + 628.307585 * t) +
          0.0002061 * math.cos(2.67823 + 628.307585 * t) * t +
          0.000349 * math.cos(4.6261 + 1256.61517 * t) -
          20.5 / _secondPerRad);
  v =
      7771.38 -
      914 * math.sin(0.7848 + 8328.691425 * t + 0.0001523 * t2) -
      179 * math.sin(2.543 + 15542.7543 * t) -
      160 * math.sin(0.1874 + 7214.0629 * t);
  t += (w - l) / v;
  return t;
}

double _qiHigh(double w) {
  var t = _saLonT2(w) * 36525;
  t = t - _dtT(t) + _oneThird;
  final v = ((t + 0.5) % 1) * _secondPerDay;
  if (v < 1200 || v > _secondPerDay - 1200) {
    t = _saLonT(w) * 36525 - _dtT(t) + _oneThird;
  }
  return t;
}

double _shuoHigh(double w) {
  var t = _msaLonT2(w) * 36525;
  t = t - _dtT(t) + _oneThird;
  final v = ((t + 0.5) % 1) * _secondPerDay;
  if (v < 1800 || v > _secondPerDay - 1800) {
    t = _msaLonT(w) * 36525 - _dtT(t) + _oneThird;
  }
  return t;
}

double _qiLow(double w) {
  const v = 628.3319653318;
  var t = (w - 4.895062166) / v;
  t -=
      (53 * t * t +
          334116 * math.cos(4.67 + 628.307585 * t) +
          2061 * math.cos(2.678 + 628.3076 * t) * t) /
      v /
      10000000;
  final n =
      48950621.66 +
      6283319653.318 * t +
      53 * t * t +
      334166 * math.cos(4.669257 + 628.307585 * t) +
      3489 * math.cos(4.6261 + 1256.61517 * t) +
      2060.6 * math.cos(2.67823 + 628.307585 * t) * t -
      994 -
      834 * math.sin(2.1824 - 33.75705 * t);
  t -=
      (n / 10000000 - w) / 628.332 +
      (32 * (t + 1.8) * (t + 1.8) - 20) / _secondPerDay / 36525;
  return t * 36525 + _oneThird;
}

double _shuoLow(double w) {
  const v = 7771.37714500204;
  var t = (w + 1.08472) / v;
  t -=
      (-0.0000331 * t * t +
              0.10976 * math.cos(0.785 + 8328.6914 * t) +
              0.02224 * math.cos(0.187 + 7214.0629 * t) -
              0.03342 * math.cos(4.669 + 628.3076 * t)) /
          v +
      (32 * (t + 1.8) * (t + 1.8) - 20) / _secondPerDay / 36525;
  return t * 36525 + _oneThird;
}

/// New-moon instant nearest [jd], in J2000-relative Julian days.
double calcShuo(double jd) {
  final size = shuoKb.length;
  var d = 0.0;
  const pc = 14;
  final target = jd + solarJ2000;
  final f1 = shuoKb[0] - pc;
  final f2 = shuoKb[size - 1] - pc;
  const f3 = 2436935.0;

  if (target < f1 || target >= f3) {
    d =
        (_shuoHigh(
                  ((target + pc - 2451551) / 29.5306).floorToDouble() *
                      math.pi *
                      2,
                ) +
                0.5)
            .floorToDouble();
  } else if (target >= f1 && target < f2) {
    var i = 0;
    for (; i < size; i += 2) {
      if (target + pc < shuoKb[i + 2]) break;
    }
    d =
        shuoKb[i] +
        shuoKb[i + 1] *
            ((target + pc - shuoKb[i]) / shuoKb[i + 1]).floorToDouble();
    d = (d + 0.5).floorToDouble();
    if (d == 1683460) d++;
    d -= solarJ2000;
  } else if (target >= f2 && target < f3) {
    d =
        (_shuoLow(
                  ((target + pc - 2451551) / 29.5306).floorToDouble() *
                      math.pi *
                      2,
                ) +
                0.5)
            .floorToDouble();
    final from = ((target - f2) / 29.5306).floor();
    final n = _charAt(shuoCorrections, from);
    if (n == '1') {
      d += 1;
    } else if (n == '2') {
      d -= 1;
    }
  }
  return d;
}

/// Solar-term instant nearest [jd], in J2000-relative Julian days.
double calcQi(double jd) {
  final size = qiKb.length;
  var d = 0.0;
  const pc = 7;
  final target = jd + solarJ2000;
  final f1 = qiKb[0] - pc;
  final f2 = qiKb[size - 1] - pc;
  const f3 = 2436935.0;

  if (target < f1 || target >= f3) {
    d =
        (_qiHigh(
                  ((target + pc - 2451259) / 365.2422 * 24).floorToDouble() *
                      math.pi /
                      12,
                ) +
                0.5)
            .floorToDouble();
  } else if (target >= f1 && target < f2) {
    var i = 0;
    for (; i < size; i += 2) {
      if (target + pc < qiKb[i + 2]) break;
    }
    d =
        qiKb[i] +
        qiKb[i + 1] * ((target + pc - qiKb[i]) / qiKb[i + 1]).floorToDouble();
    d = (d + 0.5).floorToDouble();
    if (d == 1683460) d++;
    d -= solarJ2000;
  } else if (target >= f2 && target < f3) {
    d =
        (_qiLow(
                  ((target + pc - 2451259) / 365.2422 * 24).floorToDouble() *
                      math.pi /
                      12,
                ) +
                0.5)
            .floorToDouble();
    final from = ((target - f2) / 365.2422 * 24).floor();
    final n = _charAt(qiCorrections, from);
    if (n == '1') {
      d += 1;
    } else if (n == '2') {
      d -= 1;
    }
  }
  return d;
}

/// JavaScript `String.prototype.substring(i, i + 1)`: out of range yields ''.
String _charAt(String value, int index) {
  if (index < 0 || index >= value.length) return '';
  return value[index];
}

double _qiAccurate(double w) {
  final t = _saLonT(w) * 36525;
  return t - _dtT(t) + _oneThird;
}

/// Refines a solar-term estimate to its exact instant.
double qiAccurate2(double jd) {
  final d = math.pi / 12;
  final w = ((jd + 293) / 365.2422 * 24).floorToDouble() * d;
  final a = _qiAccurate(w);
  if (a - jd > 5) return _qiAccurate(w - d);
  if (a - jd < -5) return _qiAccurate(w + d);
  return a;
}

/// Exposed for the parity tests; `2 * pi` in the upstream's own spelling.
const double piTimes2 = _piTimes2;
