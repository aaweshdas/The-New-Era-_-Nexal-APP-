import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Background types supported
enum BackgroundType { defaultVideo, customVideo, customImage, assetVideo, assetImage }

class BackgroundItem {
  final String path;     // file path
  final BackgroundType type;
  final String name;
  final DateTime addedAt;

  const BackgroundItem({
    required this.path,
    required this.type,
    required this.name,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'type': type.name,
    'name': name,
    'addedAt': addedAt.toIso8601String(),
  };

  factory BackgroundItem.fromJson(Map<String, dynamic> j) => BackgroundItem(
    path: j['path'] as String,
    type: BackgroundType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => BackgroundType.customImage,
    ),
    name: j['name'] as String,
    addedAt: DateTime.parse(j['addedAt'] as String),
  );
}

class BackgroundProvider extends ChangeNotifier {
  static const String _activeKey   = 'bg_active_path';
  static const String _activeType  = 'bg_active_type';
  static const String _libraryKey  = 'bg_library';

  // Active background
  BackgroundType activeType   = BackgroundType.assetImage;
  String         activePath   = 'assets/backgrounds/11.png';

  // User's saved media library
  List<BackgroundItem> library = [];

  SharedPreferences? _prefs;
  bool _initialized = false;
  bool get initialized => _initialized;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> load() async {
    final prefs = await _getPrefs();

    final typeName = prefs.getString(_activeType);
    if (typeName != null) {
      activeType = BackgroundType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => BackgroundType.assetImage,
      );
    }
    activePath = prefs.getString(_activeKey) ?? 'assets/backgrounds/11.png';

    final raw = prefs.getStringList(_libraryKey);
    if (raw == null) {
      library = _getDefaultPreseededLibrary();
      await _saveLibrary();
    } else {
      library = raw
          .map((e) => BackgroundItem.fromJson(json.decode(e) as Map<String, dynamic>))
          .toList();
      
      final preseeded = _getDefaultPreseededLibrary();
      bool updated = false;
      for (final item in preseeded) {
        if (!library.any((e) => e.path == item.path)) {
          library.add(item);
          updated = true;
        }
      }
      if (updated) {
        await _saveLibrary();
      }
    }

    _initialized = true;
    notifyListeners();
  }

  List<BackgroundItem> _getDefaultPreseededLibrary() {
    final list = <BackgroundItem>[];
    
    list.add(BackgroundItem(
      path: 'assets/videos/startup.mp4',
      type: BackgroundType.assetVideo,
      name: 'Startup Cyberpunk',
      addedAt: DateTime(2026),
    ));
    list.add(BackgroundItem(
      path: 'assets/videos/map_startup.mp4',
      type: BackgroundType.assetVideo,
      name: 'Map Wireframe Grid',
      addedAt: DateTime(2026),
    ));

    // Base background wallpapers (1.png - 11.png)
    for (int i = 1; i <= 11; i++) {
      list.add(BackgroundItem(
        path: 'assets/backgrounds/$i.png',
        type: BackgroundType.assetImage,
        name: 'Neo-City Grid $i',
        addedAt: DateTime(2026),
      ));
    }

    // Extended wallpaper collection (12.jpg - 28.jpg)
    final customBgNames = <int, String>{
      12: 'Cosmic Pathway',
      13: 'Mosaico Abstract',
      14: 'Celestial Horizon',
      15: 'Cyber Glow 1',
      16: 'Cyber Glow 2',
      17: 'Cyber Glow 3',
      18: 'Cyber Glow 4',
      19: 'Cyber Glow 5',
      20: 'Cyber Glow 6',
      21: 'Cyber Glow 7',
      22: 'Cyber Glow 8',
      23: 'Cyber Glow 9',
      24: 'Cyber Glow 10',
      25: 'Cyber Glow 11',
      26: 'Cyber Glow 12',
      27: 'Neon Locomotive',
      28: 'Hypercar Synthwave',
    };

    for (int i = 12; i <= 28; i++) {
      list.add(BackgroundItem(
        path: 'assets/backgrounds/$i.jpg',
        type: BackgroundType.assetImage,
        name: customBgNames[i] ?? 'Cyber Wallpaper $i',
        addedAt: DateTime(2026),
      ));
    }
    
    return list;
  }

  Future<void> setBackground(BackgroundItem item) async {
    activeType = item.type;
    activePath = item.path;

    final prefs = await _getPrefs();
    await prefs.setString(_activeType, item.type.name);
    await prefs.setString(_activeKey, item.path);
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    activeType = BackgroundType.assetImage;
    activePath = 'assets/backgrounds/11.png';

    final prefs = await _getPrefs();
    await prefs.setString(_activeType, BackgroundType.assetImage.name);
    await prefs.setString(_activeKey, activePath);
    notifyListeners();
  }

  Future<void> addToLibrary(BackgroundItem item) async {
    // Avoid duplicates
    if (library.any((e) => e.path == item.path)) return;
    library = [item, ...library];
    await _saveLibrary();
    notifyListeners();
  }

  Future<void> removeFromLibrary(String path) async {
    library = library.where((e) => e.path != path).toList();
    // If the removed item was active, reset to default
    if (activePath == path) {
      await resetToDefault();
    } else {
      await _saveLibrary();
      notifyListeners();
    }
  }

  Future<void> _saveLibrary() async {
    final prefs = await _getPrefs();
    await prefs.setStringList(
      _libraryKey,
      library.map((e) => json.encode(e.toJson())).toList(),
    );
  }
}
