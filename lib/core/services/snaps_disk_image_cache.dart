import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Lightweight, zero-SQLite disk image cache backed by [path_provider] and [HttpClient].
/// Eliminates repeat Supabase Storage egress without the sqflite/flutter_cache_manager
/// hang seen on some Android builds.
class SnapsDiskImageCache {
  SnapsDiskImageCache._();
  static final SnapsDiskImageCache instance = SnapsDiskImageCache._();

  static const int _maxCachedFiles = 180;
  int _writesSinceLastPrune = 0;

  Directory? _cacheDir;
  final Map<String, File> _memIndex = {};
  final Map<String, Future<File?>> _inFlight = {};
  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12)
    ..idleTimeout = const Duration(seconds: 15)
    ..maxConnectionsPerHost = 10;

  /// Synchronous lookup for already-indexed local files (zero disk I/O on UI thread).
  File? getCachedFileSync(String url) => _memIndex[url];

  /// Evict a specific URL from both memory and disk (used by tap-to-reload).
  Future<void> evict(String url) async {
    final file = _memIndex.remove(url);
    try {
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Resolves [url] from disk cache if present, otherwise downloads once and caches to disk.
  Future<File?> getOrFetch(String url) async {
    final existing = getCachedFileSync(url);
    if (existing != null) return existing;

    final pending = _inFlight[url];
    if (pending != null) return pending;

    final future = _fetchInternal(url);
    _inFlight[url] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(url);
    }
  }

  Future<Directory> _ensureCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    Directory base;
    try {
      base = await getTemporaryDirectory();
    } catch (e) {
      debugPrint('getTemporaryDirectory fallback to systemTemp: $e');
      base = Directory.systemTemp;
    }
    final dir = Directory('${base.path}/snaps_img_cache_v3');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _hashUrl(String url) {
    // 64-bit FNV-1a hash — fast, deterministic, zero extra dependencies
    int hash = 0xcbf29ce484222325;
    for (int i = 0; i < url.length; i++) {
      hash ^= url.codeUnitAt(i);
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }

  Future<File?> _fetchInternal(String url) async {
    try {
      final dir = await _ensureCacheDir();
      final target = File('${dir.path}/${_hashUrl(url)}.img');

      if (await target.exists() && await target.length() > 0) {
        _memIndex[url] = target;
        return target;
      }

      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        return null;
      }

      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          final req = await _http.getUrl(uri);
          final resp = await req.close().timeout(const Duration(seconds: 15));
          if (resp.statusCode != 200) {
            await resp.drain<void>();
            return null;
          }

          final bytes = await consolidateHttpClientResponseBytes(resp);
          if (bytes.isEmpty) return null;

          final tmp = File('${target.path}.tmp');
          await tmp.writeAsBytes(bytes);
          await tmp.rename(target.path);

          _memIndex[url] = target;
          _maybePruneInBackground(dir);
          return target;
        } catch (e) {
          if (attempt == 1) rethrow;
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
      return null;
    } catch (e) {
      debugPrint('SnapsDiskImageCache fetch error for $url: $e');
      return null;
    }
  }

  void _maybePruneInBackground(Directory dir) {
    _writesSinceLastPrune++;
    if (_writesSinceLastPrune < 25) return;
    _writesSinceLastPrune = 0;

    Future<void>(() async {
      try {
        final entries = await dir
            .list()
            .where((e) => e is File && e.path.endsWith('.img'))
            .cast<File>()
            .toList();
        if (entries.length <= _maxCachedFiles) return;

        final withStats = await Future.wait(
          entries.map((f) async => MapEntry(f, (await f.stat()).modified)),
        );
        withStats.sort((a, b) => a.value.compareTo(b.value));

        final toDelete = withStats.length - _maxCachedFiles;
        for (int i = 0; i < toDelete; i++) {
          try {
            await withStats[i].key.delete();
          } catch (_) {}
        }
      } catch (_) {}
    });
  }
}
