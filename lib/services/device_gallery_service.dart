import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class DevicePhotoItem {
  final String id;
  final String year;
  final String title;
  final String description;
  final String category;
  final DateTime dateTime;
  final AssetEntity asset;
  File? file;
  Uint8List? thumbnailBytes;

  DevicePhotoItem({
    required this.id,
    required this.year,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.asset,
    this.file,
    this.thumbnailBytes,
  });
}

class DeviceGalleryService {
  DeviceGalleryService._();
  static final DeviceGalleryService instance = DeviceGalleryService._();

  bool _isFetching = false;
  List<DevicePhotoItem> _cachedPhotos = [];

  List<DevicePhotoItem> get cachedPhotos => _cachedPhotos;

  /// Fetch all images from device gallery, sorted newest first
  Future<List<DevicePhotoItem>> loadDevicePhotos({bool forceRefresh = false}) async {
    if (_cachedPhotos.isNotEmpty && !forceRefresh) {
      return _cachedPhotos;
    }

    if (_isFetching) {
      return _cachedPhotos;
    }

    _isFetching = true;

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth && !ps.hasAccess) {
        debugPrint('[DeviceGalleryService] Permission denied for gallery');
        _isFetching = false;
        return [];
      }

      // Fetch albums containing image assets
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isEmpty) {
        debugPrint('[DeviceGalleryService] No photo albums found on device');
        _isFetching = false;
        return [];
      }

      final AssetPathEntity recentAlbum = albums.first;
      final int totalCount = await recentAlbum.assetCountAsync;

      // Limit initial fetch to top 100 recent photos for speed & low memory footprint
      final List<AssetEntity> assetList = await recentAlbum.getAssetListRange(
        start: 0,
        end: totalCount > 100 ? 100 : totalCount,
      );

      final List<DevicePhotoItem> items = [];

      for (int i = 0; i < assetList.length; i++) {
        final asset = assetList[i];
        final dt = asset.createDateTime;
        final year = dt.year.toString();

        final category = _determineCategory(asset, dt, i);
        final title = _generateTitle(dt, i, category);
        final description = _generateDescription(dt, category);

        items.add(DevicePhotoItem(
          id: asset.id,
          year: year,
          title: title,
          description: description,
          category: category,
          dateTime: dt,
          asset: asset,
        ));
      }

      _cachedPhotos = items;
      _isFetching = false;
      return _cachedPhotos;
    } catch (e) {
      debugPrint('[DeviceGalleryService] Exception fetching device photos: $e');
      _isFetching = false;
      return [];
    }
  }

  /// Get thumbnail bytes for a photo item
  Future<Uint8List?> getThumbnail(AssetEntity asset) async {
    try {
      return await asset.thumbnailDataWithSize(const ThumbnailSize(600, 600));
    } catch (e) {
      debugPrint('[DeviceGalleryService] Thumbnail error: $e');
      return null;
    }
  }

  /// Get full resolution file for a photo item
  Future<File?> getFile(AssetEntity asset) async {
    try {
      return await asset.file;
    } catch (e) {
      debugPrint('[DeviceGalleryService] File error: $e');
      return null;
    }
  }

  String _determineCategory(AssetEntity asset, DateTime dt, int index) {
    const categories = ['Space & Tech', 'AI & Future', 'Culture & Web3', 'Science & Nature'];
    return categories[index % categories.length];
  }

  String _generateTitle(DateTime dt, int index, String category) {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = monthNames[dt.month - 1];

    switch (category) {
      case 'Space & Tech':
        return 'Captured $month ${dt.day} — Memory ${index + 1}';
      case 'AI & Future':
        return 'Digital Snap $month ${dt.year}';
      case 'Culture & Web3':
        return 'Life Moment # ${index + 1}';
      case 'Science & Nature':
        return 'Horizon View ($month ${dt.day})';
      default:
        return 'Gallery Photo ${index + 1}';
    }
  }

  String _generateDescription(DateTime dt, String category) {
    final formattedDate = '${dt.day}/${dt.month}/${dt.year}';
    return 'Imported directly from your device gallery ($formattedDate). High definition media memory.';
  }
}
