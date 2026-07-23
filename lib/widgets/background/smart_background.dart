import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../providers/background_provider.dart';
import '../../theme/app_theme.dart';

/// Smart background widget that reacts to [BackgroundProvider].
/// Supports:
///  - Default asset video (original behaviour)
///  - Custom local video file (looping, muted)
///  - Custom local image file (fitted cover)
///
/// Performance notes:
///  - Uses [Selector] so it only rebuilds when path/type actually changes
///  - [VideoPlayer] is wrapped in [RepaintBoundary] to isolate GPU decoding
///  - Background loading is triggered from [didChangeDependencies] /
///    [didUpdateWidget], NOT from inside build()
class SmartBackground extends StatefulWidget {
  final double opacity;
  final bool isPaused;

  const SmartBackground({
    super.key,
    this.opacity = 0.8,
    this.isPaused = false,
  });

  @override
  State<SmartBackground> createState() => _SmartBackgroundState();
}

class _SmartBackgroundState extends State<SmartBackground>
    with WidgetsBindingObserver {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _hasError = false;

  // Track what we last loaded so we only rebuild when it changes
  String? _loadedPath;
  BackgroundType? _loadedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Triggered when provider value changes — safe to call here, NOT in build()
    final prov = context.read<BackgroundProvider>();
    if (prov.initialized) {
      _loadBackground(prov.activePath, prov.activeType);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ctrl == null || !_initialized) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _ctrl!.pause();
    } else if (state == AppLifecycleState.resumed && !widget.isPaused) {
      _ctrl!.play();
    }
  }

  Future<void> _loadBackground(String path, BackgroundType type) async {
    if (_loadedPath == path && _loadedType == type) return;

    _loadedPath = path;
    _loadedType = type;

    final oldCtrl = _ctrl;
    _ctrl = null;
    if (mounted) setState(() { _initialized = false; _hasError = false; });
    oldCtrl?.dispose();

    if (type == BackgroundType.customImage) {
      if (mounted && _loadedPath == path) {
        setState(() => _initialized = true);
      }
      return;
    }

    // Small delay to let the screen transition finish smoothly
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _loadedPath != path) return; // stale — another load started

    try {
      final ctrl = type == BackgroundType.defaultVideo
          ? VideoPlayerController.asset(path)
          : VideoPlayerController.file(File(path));

      await ctrl.initialize();
      await ctrl.setVolume(0.0);
      await ctrl.setLooping(true);
      if (!widget.isPaused) await ctrl.play();

      if (mounted && _loadedPath == path) {
        setState(() {
          _ctrl = ctrl;
          _initialized = true;
        });
      } else {
        ctrl.dispose();
      }
    } catch (e) {
      debugPrint('[SmartBackground] Error loading background: $e');
      if (mounted && _loadedPath == path) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void didUpdateWidget(SmartBackground old) {
    super.didUpdateWidget(old);
    if (_ctrl != null && _initialized) {
      if (widget.isPaused && !old.isPaused) {
        _ctrl!.pause();
      } else if (!widget.isPaused && old.isPaused) {
        _ctrl!.play();
      }
    }
  }

  Widget _buildGradientFallback() => Container(
    decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
  );

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when path OR type changes — not on every
    // provider notifyListeners() call (e.g., library updates)
    return Selector<BackgroundProvider, (String, BackgroundType, bool)>(
      selector: (_, p) => (p.activePath, p.activeType, p.initialized),
      builder: (context, data, _) {
        final (path, type, ready) = data;

        if (!ready) return _buildGradientFallback();

        // Trigger load when selector detects a change (not inside every build)
        if (_loadedPath != path || _loadedType != type) {
          // Schedule after frame to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadBackground(path, type);
          });
        }

        if (_hasError || !_initialized) return _buildGradientFallback();

        Widget bg;

        if (type == BackgroundType.customImage) {
          bg = Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // Limit decoded size to screen resolution — no need for full res
            cacheWidth: 1080,
          );
        } else if (_ctrl != null) {
          bg = FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _ctrl!.value.size.width,
              height: _ctrl!.value.size.height,
              child: VideoPlayer(_ctrl!),
            ),
          );
        } else {
          return _buildGradientFallback();
        }

        // RepaintBoundary isolates video/image decoding from the parent tree
        return AnimatedOpacity(
          opacity: widget.opacity,
          duration: const Duration(milliseconds: 300),
          child: SizedBox.expand(
            child: RepaintBoundary(child: bg),
          ),
        );
      },
    );
  }
}
