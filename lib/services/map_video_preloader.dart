import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Singleton that pre-initialises the map loading background video
/// so it plays immediately with zero delay when MapView opens.
///
/// Usage:
///   • Call [preload()] early (e.g. HomeScreen.initState).
///   • In MapView, call [play()] and read [controller] directly.
///   • On MapView.dispose, call [reset()] so the next open is instant too.
class MapVideoPreloader {
  MapVideoPreloader._();
  static final MapVideoPreloader instance = MapVideoPreloader._();

  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _loading = false;

  // -- Preload ----------------------------------------------------------------
  /// Initialises the codec in the background. Safe to call multiple times.
  Future<void> preload() async {
    if (_initialized || _loading) return;
    _loading = true;
    try {
      _ctrl = VideoPlayerController.asset('assets/videos/map_startup.mp4');
      await _ctrl!.initialize();
      await _ctrl!.setVolume(0);           // muted — background visual only
      await _ctrl!.setPlaybackSpeed(2.0);  // 2x speed as requested
      await _ctrl!.setLooping(true);
      _initialized = true;
    } catch (e) {
      debugPrint('[MapVideoPreloader] init error: $e');
      await _ctrl?.dispose();
      _ctrl = null;
    } finally {
      _loading = false;
    }
  }

  // -- Accessors --------------------------------------------------------------
  /// True when the controller is fully ready to play.
  bool get isReady => _initialized && _ctrl != null;

  /// The pre-warmed controller. Null if preloading failed.
  VideoPlayerController? get controller => isReady ? _ctrl : null;

  // -- Lifecycle helpers ------------------------------------------------------
  /// Call when MapView opens — starts playback from the beginning instantly.
  Future<void> play() async {
    if (!isReady) return;
    await _ctrl!.seekTo(Duration.zero);
    await _ctrl!.play();
  }

  /// Call on MapView.dispose — pauses & rewinds so the next open is instant.
  Future<void> reset() async {
    if (!isReady) return;
    await _ctrl!.pause();
    await _ctrl!.seekTo(Duration.zero);
  }

  /// Full teardown (call only if the app is completely exiting).
  Future<void> disposeAll() async {
    await _ctrl?.dispose();
    _ctrl = null;
    _initialized = false;
    _loading = false;
  }
}
