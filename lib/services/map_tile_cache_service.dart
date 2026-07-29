import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MapTileCacheService {
  MapTileCacheService._();
  static final MapTileCacheService instance = MapTileCacheService._();

  Directory? _cacheDir;
  final http.Client _client = http.Client();

  /// Initialize local map tile directory
  Future<void> init() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${docDir.path}/map_tiles');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      debugPrint('[MapTileCache] Initialized tile store: ${_cacheDir!.path}');
    } catch (e) {
      debugPrint('[MapTileCache] Init error: $e');
    }
  }

  /// Get local file path for a map tile (x, y, z) or download if missing
  Future<String?> getOrFetchTile(int z, int x, int y) async {
    if (_cacheDir == null) await init();
    if (_cacheDir == null) return null;

    final tileFile = File('${_cacheDir!.path}/${z}_${x}_$y.png');

    if (await tileFile.exists()) {
      return tileFile.path;
    }

    // Fetch from OpenStreetMap tile server
    final tileUrl = 'https://tile.openstreetmap.org/$z/$x/$y.png';
    try {
      final response = await _client.get(
        Uri.parse(tileUrl),
        headers: {'User-Agent': 'NexalApp/1.0 (Mobile Navigation Engine)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        await tileFile.writeAsBytes(response.bodyBytes);
        return tileFile.path;
      }
    } catch (e) {
      debugPrint('[MapTileCache] Tile download failed: $e');
    }
    return null;
  }

  /// Clear offline cached map tiles
  Future<void> clearCache() async {
    if (_cacheDir != null && await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await init();
    }
  }
}
