import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class SplashVideoScreen extends StatefulWidget {
  const SplashVideoScreen({super.key});

  @override
  State<SplashVideoScreen> createState() => _SplashVideoScreenState();
}

class _SplashVideoScreenState extends State<SplashVideoScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isFirstLaunch = true;
  bool _showSkipButton = false;

  @override
  void initState() {
    super.initState();

    // Force full-screen immersive mode for the splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _checkLaunchStatus();
  }

  Future<void> _checkLaunchStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('first_launch') ?? true;
    
    if (!_isFirstLaunch) {
      // Boot in under 1 second for return visits
      _navigateToHome();
      return;
    }

    // Mark as not first launch for next time
    await prefs.setBool('first_launch', false);

    _controller = VideoPlayerController.asset('assets/videos/startup.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller.setLooping(false);
        _controller.setVolume(1.0); // Audio on, full volume
        _controller.play();

        // If we wanted a skip button after 2 seconds on first launch:
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showSkipButton = true);
        });
      });

    // Listen for video completion and navigate to HomeScreen
    _controller.addListener(_onVideoProgress);
  }

  void _onVideoProgress() {
    if (!mounted) return;
    final pos = _controller.value.position;
    final dur = _controller.value.duration;

    // Navigate when video has finished playing
    if (_controller.value.isInitialized &&
        !_controller.value.isPlaying &&
        pos >= dur &&
        dur > Duration.zero) {
      _controller.removeListener(_onVideoProgress);
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    // Restore system UI before entering main app
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          // Smooth fade-in transition into the app
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    if (_isFirstLaunch && _initialized) {
      _controller.removeListener(_onVideoProgress);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFirstLaunch) return const Scaffold(backgroundColor: Colors.black);

    return Scaffold(
      backgroundColor: Colors.black,
      body: _initialized
          ? Stack(
              children: [
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
                if (_showSkipButton)
                  Positioned(
                    top: 50,
                    right: 20,
                    child: GestureDetector(
                      onTap: _navigateToHome,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          "Skip",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const SizedBox.shrink(), // Pure black screen while buffering
    );
  }
}
