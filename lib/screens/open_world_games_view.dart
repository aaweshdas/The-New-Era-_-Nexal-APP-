import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'game_webview_screen.dart';
import '../theme/app_theme.dart';


// ─── Arcade Game Model ───────────────────────────────────────────────────────

class ArcadeGame {
  final String id;
  final String title;
  final String category;
  final String description;
  final String? bannerAsset;
  final String engine;
  final String difficulty;
  final bool isPlayable;
  final IconData fallbackIcon;
  final Color themeColor;
  final String? gameUrl;
  final String? gameAssetFolder;

  const ArcadeGame({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.bannerAsset,
    required this.engine,
    required this.difficulty,
    required this.isPlayable,
    required this.fallbackIcon,
    required this.themeColor,
    this.gameUrl,
    this.gameAssetFolder,
  });
}


// ─── Main Screen ─────────────────────────────────────────────────────────────

class OpenWorldGamesView extends StatefulWidget {
  const OpenWorldGamesView({super.key});

  @override
  State<OpenWorldGamesView> createState() => _OpenWorldGamesViewState();
}

class _OpenWorldGamesViewState extends State<OpenWorldGamesView> {
  bool _isBackendOnline = false;
  bool _isCheckingBackend = true;
  String _selectedCategory = 'ALL';

  // Genuine playable games (⛏️ Voxel Game + WORDL 3D Sim)
  final List<ArcadeGame> _arcadeGames = const [
    // ─── ⛏️ VOXEL GAME — Open World Sandbox ────────────────────────────────────
    ArcadeGame(
      id: 'voxel_game',
      title: '⛏️ VOXEL GAME',
      category: 'VOXEL WORLD',
      description: 'Explore, build, and craft across infinite 3D voxel realms. Features procedural terrain, block destruction & placement, 60 FPS WebGL rendering, and full touch/keyboard controls.',
      engine: 'Three.js / WebGL 3D',
      difficulty: 'Open World',
      isPlayable: true,
      fallbackIcon: LucideIcons.box,
      themeColor: Color(0xFF10B981), // Emerald Voxel Green
      gameAssetFolder: 'assets/voxel',
    ),

    // ─── WORDL — 3D Delivery Simulation ───────────────────────────────────────
    ArcadeGame(
      id: 'wordl',
      title: 'WORDL',
      category: '3D SIM',
      description: 'Maneuver your delivery vehicle across a compact rotating 3D globe, collect packages, dodge obstacles, and beat the clock in real-time gravity physics simulation.',
      bannerAsset: 'assets/wordl/assets/images/game_banner.png',
      engine: 'Three.js / WebGL',
      difficulty: 'Med',
      isPlayable: true,
      fallbackIcon: LucideIcons.globe,
      themeColor: AppTheme.cyan500,
      gameAssetFolder: 'assets/wordl',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    try {
      final res = await http.get(Uri.parse('https://nexal-backend.onrender.com/health')).timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _isBackendOnline = res.statusCode == 200;
          _isCheckingBackend = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBackendOnline = false;
          _isCheckingBackend = false;
        });
      }
    }
  }

  void _launchGame(ArcadeGame game) {
    if (!game.isPlayable) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GameWebViewScreen(
          gameUrl: game.gameUrl,
          gameTitle: game.title,
          gameAssetFolder: game.gameAssetFolder ?? 'assets/voxel',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }


  List<ArcadeGame> get _filteredGames {
    if (_selectedCategory == 'ALL') return _arcadeGames;
    return _arcadeGames.where((g) => g.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient Glow Backgrounds
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.purple500.withValues(alpha: 0.15),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 4.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 5.seconds, begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9)),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Redesigned Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back Navigation Row
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white12),
                              ),
                              child: IconButton(
                                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const Spacer(),
                            // Server Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isBackendOnline ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isBackendOnline ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.amber.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isBackendOnline ? Colors.greenAccent : Colors.amberAccent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isBackendOnline ? Colors.greenAccent : Colors.amberAccent).withValues(alpha: 0.8),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isCheckingBackend ? 'CHECKING GATEWAY...' : (_isBackendOnline ? 'CLOUD ENGINE ONLINE' : 'STANDALONE MODE'),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Year-Wise Timeline Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Text(
                            "EST. 2026 • HYPER CLOUD ENGINE v3.0",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title with Rye Font and Shimmering Glow
                        Text(
                          "NEXAL ARCADE",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.rye(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                blurRadius: 20,
                              ),
                              Shadow(
                                color: AppTheme.purple500.withValues(alpha: 0.4),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          "Next-generation open world games. Streamed directly from high-speed cloud clusters — zero phone processing load.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Category Pill Selector
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: ['ALL', 'VOXEL WORLD', '3D SIM'].map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF10B981) : Colors.white24,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                              blurRadius: 12,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.black : Colors.white70,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Playable Games Cards ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final game = _filteredGames[index];
                        return _buildGameCard(game);
                      },
                      childCount: _filteredGames.length,
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

  Widget _buildGameCard(ArcadeGame game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: game.themeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: game.themeColor.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner / Icon Header
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      game.themeColor.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (game.bannerAsset != null)
                      Positioned.fill(
                        child: Image.asset(
                          game.bannerAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: game.themeColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: game.themeColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          game.category,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: game.themeColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: game.themeColor.withValues(alpha: 0.6)),
                            ),
                            child: Icon(game.fallbackIcon, color: game.themeColor, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game.title,
                                  style: GoogleFonts.rye(
                                    fontSize: 22,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  game.engine,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Description & Play Action
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.description,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: game.themeColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: game.themeColor.withValues(alpha: 0.5),
                        ),
                        onPressed: () => _launchGame(game),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.play, size: 20, color: Colors.black),
                            const SizedBox(width: 8),
                            Text(
                              "LAUNCH ENGINE",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
