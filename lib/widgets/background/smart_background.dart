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

    _ctrl?.dispose();
    _ctrl = null;
    if (mounted) setState(() { _initialized = false; _hasError = false; });

    _loadedPath = path;
    _loadedType = type;

    if (type == BackgroundType.customImage) {
      // No video controller needed — just mark initialized
      if (mounted) setState(() => _initialized = true);
      return;
    }

    // ── Video: asset or file ──────────────────────────────────────
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _loadedPath != path) return; // stale call

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
      debugPrint('[SmartBackground] Error: $e');
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

  @override
  Widget build(BuildContext context) {
    return Consumer<BackgroundProvider>(
      builder: (context, prov, _) {
        if (!prov.initialized) {
          return Container(
            decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
          );
        }

        // Kick off load if needed (non-blocking side-effect)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadBackground(prov.activePath, prov.activeType);
        });

        if (_hasError || !_initialized) {
          return Container(
            decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
          );
        }

        Widget bg;

        if (prov.activeType == BackgroundType.customImage) {
          bg = Image.file(
            File(prov.activePath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
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
          bg = Container(
            decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
          );
        }

        return AnimatedOpacity(
          opacity: widget.opacity,
          duration: const Duration(milliseconds: 300),
          child: SizedBox.expand(child: bg),
        );
      },
    );
  }
}
