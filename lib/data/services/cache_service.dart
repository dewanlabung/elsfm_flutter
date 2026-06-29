import 'dart:convert';
import 'package:hive/hive.dart';

/// Read-through JSON cache backed by Hive [Box<String>].
///
/// Each cache domain (tracks, albums, playlists) gets its own named box that
/// must be opened before use — see [HiveService.init].
///
/// Keys are string representations of the resource ID, values are JSON strings.
/// TTL is enforced at read time by storing a `_cachedAt` timestamp inside the
/// JSON envelope.
class CacheService {
  final Box<String> _box;

  /// Default TTL: 30 minutes.
  final Duration ttl;

  CacheService(this._box, {this.ttl = const Duration(minutes: 30)});

  /// Store [data] under [key]. Wraps it in a `{_cachedAt, data}` envelope.
  Future<void> put(String key, Map<String, dynamic> data) async {
    final envelope = {
      '_cachedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    await _box.put(key, jsonEncode(envelope));
  }

  /// Return the cached [Map] for [key], or null if absent / expired.
  Map<String, dynamic>? get(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;

    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(envelope['_cachedAt'] as String? ?? '');
      if (cachedAt == null || DateTime.now().difference(cachedAt) > ttl) {
        _box.delete(key);
        return null;
      }
      return envelope['data'] as Map<String, dynamic>?;
    } catch (_) {
      _box.delete(key);
      return null;
    }
  }

  /// Store a list of items under [key].
  Future<void> putList(String key, List<Map<String, dynamic>> items) async {
    final envelope = {
      '_cachedAt': DateTime.now().toIso8601String(),
      'data': items,
    };
    await _box.put(key, jsonEncode(envelope));
  }

  /// Return the cached list for [key], or null if absent / expired.
  List<Map<String, dynamic>>? getList(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;

    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(envelope['_cachedAt'] as String? ?? '');
      if (cachedAt == null || DateTime.now().difference(cachedAt) > ttl) {
        _box.delete(key);
        return null;
      }
      return (envelope['data'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (_) {
      _box.delete(key);
      return null;
    }
  }

  /// Remove the cached value for [key].
  Future<void> invalidate(String key) => _box.delete(key);

  /// Remove all cached values whose keys start with [prefix].
  Future<void> invalidatePrefix(String prefix) async {
    final keysToDelete = _box.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    for (final k in keysToDelete) {
      await _box.delete(k);
    }
  }

  /// Clear the entire cache box.
  Future<void> clear() => _box.clear();
}
