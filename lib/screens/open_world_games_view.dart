import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'game_webview_screen.dart';

// ─── Design Tokens & Color Palette ──────────────────────────────────────────

const Color _kBg = Color(0xFF040711);           // Ultra-Deep Obsidian Space
const Color _kCardBg = Color(0xFF090D1A);       // Dark Glass Card Background
const Color _kNeonGreen = Color(0xFF00FF9D);    // Cyber Bio-Emerald
const Color _kNeonCyan = Color(0xFF00E5FF);     // Quantum Cyan
const Color _kNeonPurple = Color(0xFFA855F7);   // Cosmic Violet/Purple
const Color _kSolarGold = Color(0xFFFFB800);    // Hall of Fame Gold
const Color _kSilver = Color(0xFFC0C0C0);       // Silver Medal
const Color _kBronze = Color(0xFFCD7F32);       // Bronze Medal
const Color _kDarkGlass = Color(0xFF0E1424);

// ─── Models ──────────────────────────────────────────────────────────────────

class ArcadeGame {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String description;
  final String? bannerAsset;
  final String engine;
  final String badgeText;
  final Color badgeColor;
  final bool isPlayable;
  final IconData icon;
  final Color themeColor;
  final List<Color> gradientColors;
  final String? gameUrl;
  final String? gameAssetFolder;
  final String rating;
  final bool isBookmarked;

  const ArcadeGame({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.description,
    this.bannerAsset,
    required this.engine,
    required this.badgeText,
    required this.badgeColor,
    required this.isPlayable,
    required this.icon,
    required this.themeColor,
    required this.gradientColors,
    this.gameUrl,
    this.gameAssetFolder,
    this.rating = '4.9',
    this.isBookmarked = false,
  });
}

class LeaderboardEntry {
  final int rank;
  final String username;
  final int score;
  final Color badgeColor;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.score,
    required this.badgeColor,
    this.isCurrentUser = false,
  });
}

class ArcadeQuest {
  final String id;
  final String title;
  final String reward;
  final int currentProgress;
  final int totalProgress;
  final IconData icon;

  const ArcadeQuest({
    required this.id,
    required this.title,
    required this.reward,
    required this.currentProgress,
    required this.totalProgress,
    required this.icon,
  });
}

// ─── Main Screen Widget ───────────────────────────────────────────────────────

class OpenWorldGamesView extends StatefulWidget {
  const OpenWorldGamesView({super.key});

  @override
  State<OpenWorldGamesView> createState() => _OpenWorldGamesViewState();
}

class _OpenWorldGamesViewState extends State<OpenWorldGamesView>
    with TickerProviderStateMixin {
  // State Variables
  bool _isBackendOnline = false;
  bool _isCheckingBackend = true;
  String _selectedCategory = 'ALL';
  int _latencyMs = 12;
  final Set<String> _bookmarkedGames = {};

  // Controllers
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;

  // ── Game Data Definitions ──────────────────────────────────────────────────

  final List<ArcadeGame> _games = const [
    ArcadeGame(
      id: 'wordl',
      title: 'WORDL 3D',
      subtitle: 'Quantum Delivery Simulator',
      category: '3D SIM',
      description: 'Deliver. Upgrade. Dominate the globe. Real-time physics. Infinite possibilities.',
      bannerAsset: 'assets/wordl/assets/images/game_banner.png',
      engine: 'Three.js WebGL 2.0',
      badgeText: 'HOT',
      badgeColor: _kNeonGreen,
      isPlayable: true,
      icon: LucideIcons.globe,
      themeColor: _kNeonGreen,
      gradientColors: [Color(0xFF00FF9D), Color(0xFF00E5FF)],
      gameAssetFolder: 'assets/wordl',
      rating: '4.9',
    ),
    ArcadeGame(
      id: 'voxel_realm',
      title: 'VOXEL REALM',
      subtitle: 'Luanti 3D Open World Sandbox',
      category: 'OPEN WORLD',
      description: 'Build. Explore. Survive. A limitless voxel universe.',
      bannerAsset: 'assets/images/voxel_realm_banner.png',
      engine: 'Luanti Engine 5.9.0',
      badgeText: 'NEW',
      badgeColor: _kNeonPurple,
      isPlayable: true,
      icon: LucideIcons.box,
      themeColor: _kNeonPurple,
      gradientColors: [Color(0xFFA855F7), Color(0xFFEC4899)],
      gameAssetFolder: 'assets/voxel_realm',
      rating: '4.8',
    ),
  ];

  final List<LeaderboardEntry> _leaderboard = const [
    LeaderboardEntry(rank: 1, username: 'QuantumX', score: 92450, badgeColor: _kSolarGold),
    LeaderboardEntry(rank: 2, username: 'NovaPrime', score: 74880, badgeColor: _kSilver),
    LeaderboardEntry(rank: 3, username: 'CryoStrike', score: 63210, badgeColor: _kBronze),
    LeaderboardEntry(rank: 4, username: 'AriaMind_99', score: 48920, badgeColor: _kNeonGreen, isCurrentUser: true),
    LeaderboardEntry(rank: 5, username: 'ShadowByte', score: 41330, badgeColor: _kNeonCyan),
  ];

  final List<ArcadeQuest> _quests = const [
    ArcadeQuest(
      id: 'q1',
      title: 'Play 2 Different Games',
      reward: 'XP 250',
      currentProgress: 1,
      totalProgress: 2,
      icon: LucideIcons.gamepad2,
    ),
    ArcadeQuest(
      id: 'q2',
      title: 'Stream for 30 Minutes',
      reward: 'XP 300',
      currentProgress: 18,
      totalProgress: 30,
      icon: LucideIcons.wifi,
    ),
    ArcadeQuest(
      id: 'q3',
      title: 'Win 3 Matches',
      reward: 'XP 400',
      currentProgress: 2,
      totalProgress: 3,
      icon: LucideIcons.swords,
    ),
  ];

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _checkBackend();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final game in _games) {
      if (game.bannerAsset != null) {
        precacheImage(AssetImage(game.bannerAsset!), context).catchError((_) {});
      }
    }
    precacheImage(const AssetImage('assets/Arcade BG.png'), context).catchError((_) {});
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    final sw = Stopwatch()..start();
    try {
      final res = await http
          .get(Uri.parse('${AppConfig.gatewayUrl}/game/api/status'))
          .timeout(const Duration(seconds: 3));
      sw.stop();
      if (mounted) {
        setState(() {
          _isBackendOnline = res.statusCode == 200;
          _isCheckingBackend = false;
          _latencyMs = sw.elapsedMilliseconds.clamp(1, 999);
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isBackendOnline = false; _isCheckingBackend = false; });
    }
  }

  void _launchGame(ArcadeGame game) {
    if (!game.isPlayable) {
      _toast('"${game.title}" is coming soon!');
      return;
    }
    HapticFeedback.heavyImpact();

    final Widget destination = GameWebViewScreen(
      gameUrl: game.gameUrl,
      gameTitle: game.title,
      gameAssetFolder: game.gameAssetFolder ?? 'assets/wordl',
    );

    Navigator.push(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim, secondAnim) => destination,
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    ));
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      backgroundColor: _kNeonPurple,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final userName = user?.name ?? 'AriaMind_99';
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        // Background Glow Canvas
        RepaintBoundary(child: _buildBackgroundCanvas()),

        // Main Scrollable Content View
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Redesigned High-Tech Cyber Header
            SliverToBoxAdapter(child: _buildRedesignedHeader(topPad, userName)),

            // Category Filter Strip
            SliverToBoxAdapter(child: _buildCategoryStrip()),

            // 2-Column Game Cards Grid
            SliverToBoxAdapter(child: _buildDualGameCardsGrid()),

            // Split Quests & Leaderboard Section
            SliverToBoxAdapter(child: _buildQuestsAndLeaderboardSection()),

            // Clean bottom spacing without footer
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ]),
    );
  }

  // ── Background Canvas ───────────────────────────────────────────────────────

  Widget _buildBackgroundCanvas() {
    return Stack(
      children: [
        // Full screen background image fallback with bright, clear visibility
        Positioned.fill(
          child: Image.asset(
            'assets/Arcade BG.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),

        // Deepened Cyber Overlay for adjusted comfortable lighting
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kBg.withValues(alpha: 0.55),
                  _kBg.withValues(alpha: 0.78),
                  _kBg.withValues(alpha: 0.90),
                  _kBg.withValues(alpha: 0.96),
                ],
                stops: const [0.0, 0.35, 0.70, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Redesigned Header Section ───────────────────────────────────────────────

  Widget _buildRedesignedHeader(double topPad, String userName) {
    final statusColor = _isCheckingBackend ? _kSolarGold : (_isBackendOnline ? _kNeonGreen : _kSolarGold);
    final statusLabel = _isCheckingBackend
        ? 'CONNECTING...'
        : (_isBackendOnline ? 'LIVE ${_latencyMs}ms' : 'OFFLINE');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border(bottom: BorderSide(color: _kNeonGreen.withValues(alpha: 0.15), width: 1)),
      ),
      child: CustomPaint(
        painter: _GridPainter(_kNeonCyan.withValues(alpha: 0.04)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Glass Navigation & Status Row ─────────────────────────
              Row(children: [
                // Back Button
                _circularNavBtn(
                  icon: LucideIcons.arrowLeft,
                  onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                ),
                const SizedBox(width: 12),

                // Live Stream Pill
                _livePill(statusColor, statusLabel),

                const Spacer(),

                // Action Controls
                _circularNavBtn(
                  icon: LucideIcons.search,
                  onTap: () { HapticFeedback.selectionClick(); },
                ),
                const SizedBox(width: 8),
                Stack(clipBehavior: Clip.none, children: [
                  _circularNavBtn(
                    icon: LucideIcons.calendar,
                    onTap: () { HapticFeedback.selectionClick(); },
                  ),
                  Positioned(
                    top: 2, right: 2,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kNeonGreen,
                        boxShadow: [BoxShadow(color: _kNeonGreen, blurRadius: 6)],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(width: 8),
                _circularNavBtn(
                  icon: LucideIcons.trophy,
                  iconColor: _kSolarGold,
                  borderColor: _kSolarGold.withValues(alpha: 0.4),
                  onTap: () { HapticFeedback.selectionClick(); },
                ),
              ]),

              const SizedBox(height: 22),

              // ── Redesigned Hero Glass Command Card ─────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _kCardBg.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _kNeonGreen.withValues(alpha: 0.20), width: 1.2),
                      boxShadow: [
                        BoxShadow(color: _kNeonGreen.withValues(alpha: 0.08), blurRadius: 12, spreadRadius: 0),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Glowing Emblem Logo
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _kDarkGlass,
                                border: Border.all(color: _kNeonGreen.withValues(alpha: 0.5), width: 1.2),
                                boxShadow: [
                                  BoxShadow(color: _kNeonGreen.withValues(alpha: 0.15), blurRadius: 10),
                                ],
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.gamepad2, color: _kNeonGreen, size: 24),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Main Title & Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    ShaderMask(
                                      shaderCallback: (r) => const LinearGradient(
                                        colors: [Colors.white, _kNeonCyan],
                                      ).createShader(r),
                                      child: Text('NEXAL ARCADE',
                                        style: GoogleFonts.sora(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 2.0,
                                        )),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _kNeonGreen.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: _kNeonGreen.withValues(alpha: 0.4)),
                                      ),
                                      child: Text('v4.2 PRO',
                                        style: GoogleFonts.shareTechMono(
                                          color: _kNeonGreen, fontSize: 8.5, fontWeight: FontWeight.bold,
                                        )),
                                    ),
                                  ]),
                                  const SizedBox(height: 2),
                                  Text('Stream Next-Gen Games Live · Zero CPU Load',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 11.5,
                                    )),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

                        const SizedBox(height: 14),

                        // Pilot HUD Profile Bar inside Header Card
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white10,
                                border: Border.all(color: _kNeonCyan, width: 1.2),
                              ),
                              child: const Icon(LucideIcons.user, color: _kNeonCyan, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PILOT: $userName',
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  )),
                                Text('LVL 42  •  RANK #4 GLOBAL',
                                  style: GoogleFonts.shareTechMono(
                                    color: _kNeonCyan, fontSize: 9, letterSpacing: 0.8,
                                  )),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _kSolarGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _kSolarGold.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.star, color: _kSolarGold, size: 12),
                                  const SizedBox(width: 4),
                                  Text('48,920 PTS',
                                    style: GoogleFonts.shareTechMono(
                                      color: _kSolarGold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circularNavBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.15),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _livePill(Color color, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) => Icon(LucideIcons.zap, color: color, size: 12),
            ),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.shareTechMono(
              fontSize: 10.5, fontWeight: FontWeight.bold,
              color: Colors.white, letterSpacing: 1.0,
            )),
          ]),
        ),
      ),
    );
  }

  // ── Category Filter Strip ───────────────────────────────────────────────────

  Widget _buildCategoryStrip() {
    final categories = [
      {'name': 'ALL', 'icon': LucideIcons.layoutGrid},
      {'name': '3D SIM', 'icon': LucideIcons.box},
      {'name': 'OPEN WORLD', 'icon': LucideIcons.globe},
      {'name': 'ACTION', 'icon': LucideIcons.crosshair},
      {'name': 'MULTIPLAYER', 'icon': LucideIcons.users},
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == categories.length) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 18),
            );
          }

          final cat = categories[i];
          final String catName = cat['name'] as String;
          final IconData catIcon = cat['icon'] as IconData;
          final sel = _selectedCategory == catName;

          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = catName); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _kNeonGreen.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? _kNeonGreen : Colors.white.withValues(alpha: 0.1),
                  width: sel ? 1.4 : 1,
                ),
                boxShadow: sel ? [BoxShadow(color: _kNeonGreen.withValues(alpha: 0.3), blurRadius: 10)] : [],
              ),
              child: Row(children: [
                Icon(catIcon, size: 14, color: sel ? _kNeonGreen : Colors.white60),
                const SizedBox(width: 6),
                Text(catName,
                  style: GoogleFonts.outfit(
                    color: sel ? _kNeonGreen : Colors.white60,
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: 1.1,
                  )),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── 2-Column Game Cards Grid ────────────────────────────────────────────────

  Widget _buildDualGameCardsGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Card: WORDL 3D
          Expanded(child: _buildArcadeCard(_games[0])),
          const SizedBox(width: 14),
          // Right Card: VOXEL REALM
          Expanded(child: _buildArcadeCard(_games[1])),
        ],
      ),
    );
  }

  Widget _buildArcadeCard(ArcadeGame game) {
    final isBookmarked = _bookmarkedGames.contains(game.id);

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: game.themeColor.withValues(alpha: 0.5), width: 1.4),
        boxShadow: [
          BoxShadow(color: game.themeColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Artwork Preview Area
            SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fallback Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: game.gradientColors),
                    ),
                  ),

                  // Image Asset
                  if (game.bannerAsset != null)
                    Image.asset(
                      game.bannerAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => const SizedBox(),
                    ),

                  // Dark Overlay Vignette
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Left Badge (HOT / NEW)
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: game.badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: game.badgeColor.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        game.badgeText == 'HOT' ? '🔥 HOT' : 'NEW',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Top Right Bookmark Button
                  Positioned(
                    top: 10, right: 10,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isBookmarked) {
                            _bookmarkedGames.remove(game.id);
                          } else {
                            _bookmarkedGames.add(game.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.5),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Icon(
                          isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                          color: isBookmarked ? game.themeColor : Colors.white70,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(game.title,
                    style: GoogleFonts.outfit(
                      color: game.themeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    )),
                  const SizedBox(height: 2),

                  // Subtitle
                  Text(game.subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 8),

                  // Rating & Engine Pill
                  Row(children: [
                    const Icon(LucideIcons.star, color: _kSolarGold, size: 12),
                    const SizedBox(width: 3),
                    Text(game.rating,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(game.engine,
                          style: GoogleFonts.shareTechMono(color: game.themeColor, fontSize: 8.5),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 8),

                  // Description
                  Text(game.description,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 14),

                  // LAUNCH CLOUD ENGINE Button
                  GestureDetector(
                    onTap: () => _launchGame(game),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: game.themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: game.themeColor),
                        boxShadow: [
                          BoxShadow(color: game.themeColor.withValues(alpha: 0.3), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.cloud, color: game.themeColor, size: 14),
                          const SizedBox(width: 6),
                          Text('LAUNCH CLOUD ENGINE',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            )),
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
    );
  }

  // ── Split Quests & Leaderboard Section ──────────────────────────────────────

  Widget _buildQuestsAndLeaderboardSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDailyQuestsCard()),
                const SizedBox(width: 14),
                Expanded(child: _buildHallOfFameCard()),
              ],
            );
          }
          return Column(
            children: [
              _buildDailyQuestsCard(),
              const SizedBox(height: 16),
              _buildHallOfFameCard(),
            ],
          );
        },
      ),
    );
  }

  // ── Daily Quests Card ────────────────────────────────────────────────────────

  Widget _buildDailyQuestsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kNeonGreen.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            const Icon(LucideIcons.target, color: _kNeonGreen, size: 16),
            const SizedBox(width: 6),
            Text('DAILY QUESTS',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            const Spacer(),
            const Icon(LucideIcons.clock, color: Colors.white38, size: 12),
            const SizedBox(width: 4),
            Text('07:32:18',
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
          ]),
          const SizedBox(height: 4),
          Text('Complete quests. Earn XP. Claim rewards.',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),

          const SizedBox(height: 12),

          // Quest Items
          ..._quests.map((q) => _buildQuestRow(q)),

          const SizedBox(height: 12),

          // Daily Progress Bar
          Row(children: [
            Text('DAILY PROGRESS',
              style: GoogleFonts.outfit(color: _kNeonGreen, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            const Spacer(),
            Text('650 / 1,000 XP',
              style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 9.5)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                  value: 0.65,
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(_kNeonGreen),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.gift, color: _kSolarGold, size: 16),
          ]),
        ],
      ),
    );
  }

  Widget _buildQuestRow(ArcadeQuest q) {
    final double ratio = q.currentProgress / q.totalProgress;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(q.icon, color: _kNeonGreen, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 4,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(ratio >= 1.0 ? _kNeonGreen : _kNeonCyan),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${q.currentProgress}/${q.totalProgress}',
                style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 8.5)),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _kNeonGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kNeonGreen.withValues(alpha: 0.3)),
          ),
          child: Text(q.reward,
            style: GoogleFonts.shareTechMono(color: _kNeonGreen, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ── Hall of Fame Card ────────────────────────────────────────────────────────

  Widget _buildHallOfFameCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kSolarGold.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            const Icon(LucideIcons.trophy, color: _kSolarGold, size: 16),
            const SizedBox(width: 6),
            Text('HALL OF FAME',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            const Spacer(),
            Text('TOP PILOTS',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9.5, letterSpacing: 0.8)),
          ]),

          const SizedBox(height: 10),

          // Leaderboard Rows
          ..._leaderboard.map((e) => _buildLeaderboardTile(e)),

          const SizedBox(height: 10),

          // VIEW FULL LEADERBOARD Button
          GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); },
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kSolarGold.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('VIEW FULL LEADERBOARD',
                  style: GoogleFonts.outfit(color: _kSolarGold, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight, color: _kSolarGold, size: 13),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry e) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: e.isCurrentUser ? _kNeonGreen.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: e.isCurrentUser ? Border.all(color: _kNeonGreen.withValues(alpha: 0.4)) : null,
      ),
      child: Row(children: [
        // Rank Badge
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: e.badgeColor.withValues(alpha: 0.15),
            border: Border.all(color: e.badgeColor),
          ),
          child: Center(child: Text(
            e.rank <= 3 ? ['🥇','🥈','🥉'][e.rank - 1] : '${e.rank}',
            style: TextStyle(fontSize: e.rank <= 3 ? 11 : 9.5, fontWeight: FontWeight.bold, color: Colors.white),
          )),
        ),
        const SizedBox(width: 8),
        // Avatar
        Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
          child: const Icon(LucideIcons.user, color: Colors.white70, size: 12),
        ),
        const SizedBox(width: 8),
        // Name
        Expanded(
          child: Text(e.username,
            style: GoogleFonts.outfit(
              color: e.isCurrentUser ? _kNeonGreen : Colors.white,
              fontSize: 11, fontWeight: e.isCurrentUser ? FontWeight.bold : FontWeight.w500,
            )),
        ),
        // Points
        Row(children: [
          const Icon(LucideIcons.star, color: _kSolarGold, size: 10),
          const SizedBox(width: 3),
          Text('${e.score} PTS',
            style: GoogleFonts.shareTechMono(color: _kSolarGold, fontSize: 9.5, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}

// ─── Grid Painter ─────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}
