import 'dart:io';

/// The font families the app actually ships, read out of `pubspec.yaml`.
///
/// Both the test engine's font registration and the glyph-coverage test read
/// their inventory from here, so neither can fall behind a change to the
/// bundle. A hand-maintained copy of this list is how `font_coverage_test`
/// came to be measuring Noto Sans while believing it was measuring the family
/// the app had switched to.
///
/// Returns family name to asset paths, in manifest order, with every weight
/// the family declares.
Map<String, List<String>> bundledFontFamilies({String pubspec = 'pubspec.yaml'}) {
  final lines = File(pubspec).readAsLinesSync();

  // `fonts:` appears under `flutter:`, indented two spaces. Anchor on that
  // rather than on the first match, so an unrelated `fonts:` key elsewhere in
  // the file cannot be picked up.
  var start = -1;
  var inFlutter = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('flutter:')) {
      inFlutter = true;
      continue;
    }
    if (inFlutter && line.isNotEmpty && !line.startsWith(' ')) {
      inFlutter = false;
    }
    if (inFlutter && RegExp(r'^  fonts:\s*$').hasMatch(line)) {
      start = i + 1;
      break;
    }
  }
  if (start < 0) {
    throw StateError('$pubspec declares no fonts: block under flutter:');
  }

  final families = <String, List<String>>{};
  String? family;
  for (var i = start; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    // Any key back at the `flutter:` child level ends the fonts block.
    if (!line.startsWith('    ')) break;

    final declared = RegExp(r'^    - family:\s*(\S.*?)\s*$').firstMatch(line);
    if (declared != null) {
      family = declared.group(1)!;
      families[family] = <String>[];
      continue;
    }
    final asset = RegExp(r'^\s+- asset:\s*(\S.*?)\s*$').firstMatch(line);
    if (asset != null) {
      if (family == null) {
        throw StateError('$pubspec lists an asset before any family');
      }
      families[family]!.add(asset.group(1)!);
    }
  }

  if (families.isEmpty) {
    throw StateError('$pubspec declares a fonts: block with no families');
  }
  for (final entry in families.entries) {
    if (entry.value.isEmpty) {
      throw StateError('${entry.key} is declared with no font files');
    }
  }
  return families;
}
