/// Port of `boundedCache` in `calculation-engine/src/core.js`.
///
/// Insertion-ordered with a hard cap: once full, the oldest key is dropped
/// before a new one is added. Dart's `Map` preserves insertion order, so the
/// eviction order matches the Node engine's exactly.
class BoundedCache<K, V> {
  BoundedCache(this.max);

  final int max;
  final Map<K, V> _map = <K, V>{};

  V? get(K key) => _map[key];

  /// Distinguishes "cached as null" from "not cached", which the v9.1 scoring
  /// needs: a date with no anchor is a real, reusable answer.
  bool containsKey(K key) => _map.containsKey(key);

  V set(K key, V value) {
    if (_map.length >= max && !_map.containsKey(key)) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
    return value;
  }
}
