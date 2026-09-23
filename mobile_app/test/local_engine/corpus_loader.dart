import 'dart:convert';
import 'dart:io';

/// Loads a parity corpus written by `calculation-engine/scripts/port/`.
///
/// These files are real Node engine output, not hand-written expectations, so a
/// Dart value that disagrees with one is a port defect by definition.
Map<String, dynamic> loadCorpus(String name) {
  final file = File('test/local_engine/$name');
  if (!file.existsSync()) {
    throw StateError(
      'Missing parity corpus "$name". Regenerate it from the engine repo:\n'
      '  node scripts/port/gen_${name.replaceAll('.json', '')}.mjs',
    );
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

List<Map<String, dynamic>> rows(Map<String, dynamic> corpus, String key) =>
    (corpus[key] as List<dynamic>).cast<Map<String, dynamic>>();

double asDouble(Object? value) => (value as num).toDouble();

List<double> asDoubles(Object? value) =>
    (value as List<dynamic>).map((v) => (v as num).toDouble()).toList();

List<String> asStrings(Object? value) =>
    (value as List<dynamic>).map((v) => v as String).toList();
