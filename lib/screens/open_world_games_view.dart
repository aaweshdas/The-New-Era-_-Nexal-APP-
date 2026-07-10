import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'game_webview_screen.dart';
import '../theme/app_theme.dart';
import '../services/aria_config.dart';

class OpenWorldGamesView extends StatefulWidget {
  const OpenWorldGamesView({super.key});

  @override
  State<OpenWorldGamesView> createState() => _OpenWorldGamesViewState();
}

class _OpenWorldGamesViewState extends State<OpenWorldGamesView> {
  bool _isBackendOnline = false;
  bool _isCheckingBackend = true;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    setState(() {
      _isCheckingBackend = true;
    });
    try {
      final config = await AriaConfig.load();
      final url = '${config.backendUrl}/health';
      debugPrint("Checking backend health at: $url");
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        setState(() {
          _isBackendOnline = true;
          _isCheckingBackend = false;
        });
      } else {
        setState(() {
          _isBackendOnline = false;
          _isCheckingBackend = false;
        });
      }
    } catch (e) {
      debugPrint("Backend health check failed: $e");
      setState(() {
        _isBackendOnline = false;
        _isCheckingBackend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Deep Space Background Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.deepSpaceGradient,
                ),
              ),
            ),
            
            // Decorative Nebulae Glow
            Positioned(
              top: -100,
              right: -50,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cyan500.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.purple500.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),

            // Scrollable Content
            Positioned.fill(
              child: Column(
                children: [
                  const SizedBox(height: 80), // Space for floating header
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          // Premium Title
                          Text(
                            "OPEN WORLD",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: AppTheme.cyan500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Featured Games",
                            style: GoogleFonts.rye(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Active Game: WORDL Messenger
                          _buildFeaturedGameCard(
                            context,
                            title: "MESSENGER (WORDL)",
                            subtitle: "3D Planet Delivery Simulator",
                            description: "It's a small planet, but someone's gotta make the deliveries. Maneuver your delivery vehicle across a compact rotating 3D globe, collect packages, dodge obstacles, and beat the clock in real-time gravity simulation.",
                            imageAsset: "assets/wordl/assets/images/game_banner.png",
                            engine: "HTML5 WebGL / Three.js",
                            difficulty: "Medium",
                            isPlayable: true,
                            onPlay: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const GameWebViewScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                  transitionDuration: const Duration(milliseconds: 400),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          // Locked Game 1: Nebula Explorer
                          Text(
                            "Coming Soon",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFeaturedGameCard(
                            context,
                            title: "NEBULA BOUND",
                            subtitle: "Infinite Space Survival",
                            description: "Command a starship in a fully open procedural galaxy. Gather raw minerals, evade cosmic anomalies, and establish trade routes between distant alien stations.",
                            imageAsset: null, // Procedural look
                            engine: "Unity WebGL / WASM",
                            difficulty: "Hard",
                            isPlayable: false,
                          ),

                          const SizedBox(height: 20),

                          // Locked Game 2: Cyber Run
                          _buildFeaturedGameCard(
                            context,
                            title: "CYBERPULSE 2099",
                            subtitle: "Neon City Racer",
                            description: "Race through rain-soaked vertical highways in a towering cyberpunk megacity. Customize anti-gravity bikes and master drift mechanics in neon-lit environments.",
                            imageAsset: null,
                            engine: "PlayCanvas WebGL",
                            difficulty: "Easy",
                            isPlayable: false,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Premium Glassmorphic Header (decent and stylish)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Section: Frosted Back Button
                        GestureDetector(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.arrowLeft,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),

                        // Center Section: Glowing Futuristic Title
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [
                                AppTheme.cyan500,
                                AppTheme.purple500,
                              ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            "NEXAL ARCADE",
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: AppTheme.cyan500.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Section: Glowing Gamepad Status Badge
                        GestureDetector(
                          onTap: _checkBackendHealth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isCheckingBackend
                                    ? Colors.white24
                                    : (_isBackendOnline
                                        ? Colors.greenAccent.withValues(alpha: 0.3)
                                        : Colors.redAccent.withValues(alpha: 0.3)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.gamepad2,
                                  color: _isCheckingBackend
                                      ? Colors.white54
                                      : (_isBackendOnline ? Colors.greenAccent : Colors.redAccent),
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCheckingBackend
                                      ? "CHECKING..."
                                      : (_isBackendOnline ? "BACKEND ONLINE" : "BACKEND OFFLINE"),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _isCheckingBackend
                                        ? Colors.white54
                                        : (_isBackendOnline ? Colors.greenAccent : Colors.redAccent),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _isCheckingBackend
                                        ? Colors.orangeAccent
                                        : (_isBackendOnline ? Colors.greenAccent : Colors.redAccent),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isCheckingBackend
                                            ? Colors.orangeAccent.withValues(alpha: 0.6)
                                            : (_isBackendOnline
                                                ? Colors.greenAccent.withValues(alpha: 0.8)
                                                : Colors.redAccent.withValues(alpha: 0.8)),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required String? imageAsset,
    required String engine,
    required String difficulty,
    required bool isPlayable,
    VoidCallback? onPlay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPlayable
              ? AppTheme.cyan500.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner/Visual Section
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: imageAsset != null
                      ? Image.asset(
                          imageAsset,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.indigo.shade900,
                                Colors.black,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.gamepad2,
                              size: 64,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                ),
                // Premium Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                // Badges
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPlayable
                          ? AppTheme.cyan500.withValues(alpha: 0.85)
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPlayable ? "READY TO PLAY" : "COMING SOON",
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white12,
                      ),
                    ),
                    child: Text(
                      engine,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content info Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.purple500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Difficulty badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Diff: $difficulty",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Play / Action Button
                if (isPlayable)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.cyan500,
                            AppTheme.purple500,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cyan500.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onPlay,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.play,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "LAUNCH INSTANT PLAY",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.lock,
                              color: Colors.white38,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "LOCKED (DEVELOPMENT IN PROGRESS)",
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white38,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
