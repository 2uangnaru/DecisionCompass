@Tags(['fonts'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/theme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bundled_fonts.dart';

/// Proves the bundled fonts actually contain the characters the app ships.
///
/// This is glyph coverage read out of each font's own `cmap` table, not an
/// assumption about what a device happens to have installed. It is the one
/// part of font QA that can be established without a screen: it cannot tell
/// you whether a Thai tone mark *looks* right at 1.5 text scale, only that a
/// glyph exists for it and the reader will not see a tofu box.
void main() {
  final fonts = <String, Set<int>>{};

  setUpAll(() {
    // The inventory is the shipped manifest, not a copy of it. When the app
    // switched its Latin family from Noto Sans to Montserrat, a hand-written
    // copy here went on measuring Noto Sans under the new family's name, and
    // the family that had actually started drawing English, Vietnamese and
    // Spanish was never checked at all.
    for (final entry in bundledFontFamilies().entries) {
      // Every weight, intersected: a character the Bold lacks would fall
      // through to another family mid-sentence and change shape.
      Set<int>? shared;
      for (final path in entry.value) {
        final covered = _coverage(File(path));
        shared = shared == null ? covered : shared.intersection(covered);
      }
      fonts[entry.key] = shared!;
    }
  });

  test('every family the app asks for is a family it bundles', () {
    // The check that would have caught the switch: a stack naming a family
    // that pubspec does not declare renders in the platform's own font, and
    // nothing else in the suite would say so.
    final declared = fonts.keys.toSet();
    final asked = <String>{
      for (final locale in AppLocale.values) ...[
        ...CompassFonts.fallbackFor(locale),
        ...CompassFonts.displayFallbackFor(locale),
      ],
    };
    expect(
      asked.difference(declared),
      isEmpty,
      reason: 'the theme asks for families pubspec.yaml does not bundle',
    );
  });

  test('every bundled family parses and carries a real repertoire', () {
    for (final entry in fonts.entries) {
      // Script-only Noto faces are small by design — NotoSansThai carries
      // Thai and little else — so this only catches a file that failed to
      // parse rather than one that is narrow on purpose.
      expect(
        entry.value.length,
        greaterThan(80),
        reason: '${entry.key} produced a suspiciously small cmap',
      );
      // ignore: avoid_print
      print('${entry.key}: ${entry.value.length} codepoints');
    }
    // A sanity check that the files are not all the same font under different
    // names: each script font has to carry its own script.
    expect(fonts[CompassFonts.thai], contains(0x0E01)); // ก
    expect(fonts[CompassFonts.devanagari], contains(0x0915)); // क
    expect(fonts[CompassFonts.japanese], contains(0x3042)); // あ
    expect(fonts[CompassFonts.simplifiedChinese], contains(0x4E2D)); // 中
    expect(fonts[CompassFonts.korean], contains(0xAC00)); // 가
    // Both Latin faces: the lead one draws Vietnamese, the fallback catches
    // whatever it misses, so each has to carry the stacked diacritics.
    expect(fonts[CompassFonts.latin], contains(0x1EC7)); // ệ
    expect(fonts[CompassFonts.latinFallback], contains(0x1EC7)); // ệ
  });

  for (final locale in AppLocale.values) {
    test('${locale.tag} renders with the fonts the app bundles for it', () {
      final stack = CompassFonts.fallbackFor(locale);
      final covered = stack
          .map(
            (family) =>
                fonts[family] ??
                fail('$family is in the ${locale.tag} stack but is not '
                    'bundled'),
          )
          .reduce((a, b) => a.union(b));

      final missing = <int>{};
      for (final value in _arbStrings(locale)) {
        for (final rune in value.runes) {
          // Control characters, spaces and emojis (which are rendered by
          // the system emoji font rather than text fonts) are skipped.
          if (rune < 0x20 ||
              rune == 0x00A0 ||
              rune == 0x202F ||
              rune == 0x2728 ||
              (rune >= 0x1F300 && rune <= 0x1FAFF)) {
            continue;
          }
          if (!covered.contains(rune)) missing.add(rune);
        }
      }

      expect(
        missing,
        isEmpty,
        reason:
            'no bundled font covers '
            '${missing.map((r) => 'U+${r.toRadixString(16).toUpperCase()} '
                '(${String.fromCharCode(r)})').join(', ')} '
            'for ${locale.tag}; the stack was $stack',
      );
    });

    test('${locale.tag} leads with a font that carries its own script', () {
      // Not just "something in the stack has it": the lead family has to
      // carry the language's own script, or every line would be drawn by a
      // fallback and Han characters could come out in the wrong regional
      // shapes.
      //
      // The shared Latin run — the brand name, the digits, the bullet — is
      // excluded: the script-only Noto faces (Thai, Devanagari) deliberately
      // do not carry Latin, and `fontFamilyFallback` is what covers it.
      final leadFamily = CompassFonts.fallbackFor(locale).first;
      final lead = fonts[leadFamily]!;
      // The Latin run is whatever either Latin face can draw. There are two
      // of them now — the geometric one that leads, and Noto Sans behind it —
      // and `fontFamilyFallback` reaches both.
      const latinFamilies = [CompassFonts.latin, CompassFonts.latinFallback];
      final latin = latinFamilies
          .map((family) => fonts[family]!)
          .reduce((a, b) => a.union(b));
      final ownScript = <int>{};
      for (final value in _arbStrings(locale)) {
        for (final rune in value.runes) {
          if (rune < 0x20 ||
              rune == 0x00A0 ||
              rune == 0x202F ||
              rune == 0x2728 ||
              (rune >= 0x1F300 && rune <= 0x1FAFF)) {
            continue;
          }
          if (latin.contains(rune) && !latinFamilies.contains(leadFamily)) {
            continue;
          }
          ownScript.add(rune);
        }
      }
      final gaps = ownScript.difference(lead);
      expect(
        gaps,
        isEmpty,
        reason:
            '$leadFamily does not cover '
            '${gaps.take(12).map((r) => String.fromCharCode(r)).join()} '
            'for ${locale.tag}',
      );
      // ignore: avoid_print
      print(
        '${locale.tag}: ${ownScript.length} script codepoints '
        'led by $leadFamily',
      );
    });
  }
}

/// Every translated value in one locale's ARB file.
Iterable<String> _arbStrings(AppLocale locale) sync* {
  final name = locale.tag.replaceAll('-', '_');
  final raw = File('lib/l10n/app_$name.arb').readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  for (final entry in decoded.entries) {
    if (entry.key.startsWith('@')) continue;
    yield entry.value as String;
  }
}

/// The set of Unicode codepoints a font file has a glyph for.
///
/// Reads the `cmap` table out of the sfnt directly. Both `.ttf` and `.otf`
/// carry it in the same place, so one reader covers every bundled family.
Set<int> _coverage(File file) {
  expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
  final bytes = ByteData.sublistView(file.readAsBytesSync());

  final tableCount = bytes.getUint16(4);
  var cmapOffset = -1;
  for (var i = 0; i < tableCount; i++) {
    final record = 12 + i * 16;
    final tag = String.fromCharCodes([
      for (var b = 0; b < 4; b++) bytes.getUint8(record + b),
    ]);
    if (tag == 'cmap') {
      cmapOffset = bytes.getUint32(record + 8);
      break;
    }
  }
  expect(cmapOffset, greaterThan(0), reason: '${file.path} has no cmap');

  // Prefer a full Unicode subtable (format 12) over the BMP-only format 4,
  // so characters above U+FFFF are not silently reported as missing.
  var best = -1;
  var bestRank = -1;
  final subtableCount = bytes.getUint16(cmapOffset + 2);
  for (var i = 0; i < subtableCount; i++) {
    final record = cmapOffset + 4 + i * 8;
    final platform = bytes.getUint16(record);
    final encoding = bytes.getUint16(record + 2);
    final offset = cmapOffset + bytes.getUint32(record + 4);
    final rank = switch ((platform, encoding)) {
      (3, 10) || (0, 4) || (0, 6) => 3, // full Unicode
      (3, 1) || (0, 3) => 2, // BMP
      (0, _) => 1,
      _ => 0,
    };
    if (rank > bestRank) {
      bestRank = rank;
      best = offset;
    }
  }
  expect(best, greaterThan(0), reason: '${file.path} has no usable cmap');

  final format = bytes.getUint16(best);
  return switch (format) {
    4 => _format4(bytes, best),
    12 => _format12(bytes, best),
    _ => fail('${file.path} uses unsupported cmap format $format'),
  };
}

Set<int> _format4(ByteData bytes, int offset) {
  final segCount = bytes.getUint16(offset + 6) ~/ 2;
  final endCodes = offset + 14;
  final startCodes = endCodes + segCount * 2 + 2;
  final idDeltas = startCodes + segCount * 2;
  final idRangeOffsets = idDeltas + segCount * 2;

  final covered = <int>{};
  for (var segment = 0; segment < segCount; segment++) {
    final end = bytes.getUint16(endCodes + segment * 2);
    final start = bytes.getUint16(startCodes + segment * 2);
    if (start > end) continue;
    final delta = bytes.getUint16(idDeltas + segment * 2);
    final rangeOffsetAt = idRangeOffsets + segment * 2;
    final rangeOffset = bytes.getUint16(rangeOffsetAt);
    for (var code = start; code <= end; code++) {
      // 0xFFFF is the required terminating segment, not a character.
      if (code == 0xFFFF) continue;
      int glyph;
      if (rangeOffset == 0) {
        glyph = (code + delta) & 0xFFFF;
      } else {
        final at = rangeOffsetAt + rangeOffset + (code - start) * 2;
        if (at + 1 >= bytes.lengthInBytes) continue;
        glyph = bytes.getUint16(at);
        if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
      }
      if (glyph != 0) covered.add(code);
    }
  }
  return covered;
}

Set<int> _format12(ByteData bytes, int offset) {
  final groups = bytes.getUint32(offset + 12);
  final covered = <int>{};
  for (var group = 0; group < groups; group++) {
    final at = offset + 16 + group * 12;
    final start = bytes.getUint32(at);
    final end = bytes.getUint32(at + 4);
    // Guards a hand-edited or truncated font from spinning here.
    if (end < start || end - start > 0x110000) continue;
    for (var code = start; code <= end; code++) {
      covered.add(code);
    }
  }
  return covered;
}
