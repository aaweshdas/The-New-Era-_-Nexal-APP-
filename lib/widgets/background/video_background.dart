import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../theme/app_theme.dart';

class VideoBackground extends StatefulWidget {
  final String videoPath;
  final double opacity;
  final bool isPaused;

  const VideoBackground({
    super.key,
    this.videoPath = 'assets/videos/Background.mp4',
    this.opacity = 1.0,
    this.isPaused = false,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoPath);

      await _controller.initialize();

      await _controller.setVolume(0.0);
      await _controller.setLooping(true);
      if (!widget.isPaused) {
        await _controller.play();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading background video: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(VideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (widget.isPaused && !oldWidget.isPaused) {
        _controller.pause();
      } else if (!widget.isPaused && oldWidget.isPaused) {
        _controller.play();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    // Pause video when app goes to background to save battery
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed && !widget.isPaused) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If error or not initialized, show the deep space gradient as fallback
    if (_hasError || !_isInitialized) {
      return Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
      );
    }

    return Opacity(
      opacity: widget.opacity,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}
