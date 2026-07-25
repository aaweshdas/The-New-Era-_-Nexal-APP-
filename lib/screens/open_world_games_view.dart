import 'dart:async';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'game_webview_screen.dart';
import 'luanti_game_screen.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _kBg = Color(0xFF060913);
const _kPurple = Color(0xFF7C3AED);
const _kCyan = Color(0xFF00E5FF);
const _kPink = Color(0xFFEC4899);
const _kAmber = Color(0xFFF59E0B);
const _kGreen = Color(0xFF10B981);

// ─── Arcade Game Model ────────────────────────────────────────────────────────

class ArcadeGame {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String description;
  final String? bannerAsset;
  final String engine;
  final String difficulty;
  final Color difficultyColor;
  final bool isPlayable;
  final IconData icon;
  final Color themeColor;
  final List<Color> gradientColors;
  final String? gameUrl;
  final String? gameAssetFolder;
  final String playersCount;
  final String rating;
  final List<String> tags;

  const ArcadeGame({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.description,
    this.bannerAsset,
    required this.engine,
    required this.difficulty,
    required this.difficultyColor,
    required this.isPlayable,
    required this.icon,
    required this.themeColor,
    required this.gradientColors,
    this.gameUrl,
    this.gameAssetFolder,
    this.playersCount = '1.4k',
    this.rating = '4.9',
    this.tags = const [],
  });
}

// ─── Leaderboard Entry Model ──────────────────────────────────────────────────

class LeaderboardEntry {
  final int rank;
  final String username;
  final int score;
  final int level;
  final Color color;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.score,
    required this.level,
    required this.color,
  });
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class OpenWorldGamesView extends StatefulWidget {
  const OpenWorldGamesView({super.key});

  @override
  State<OpenWorldGamesView> createState() => _OpenWorldGamesViewState();
}

class _OpenWorldGamesViewState extends State<OpenWorldGamesView>
    with TickerProviderStateMixin {
  // State
  bool _isBackendOnline = false;
  bool _isCheckingBackend = true;
  String _selectedCategory = 'ALL';
  bool _showLeaderboard = false;
  int _latencyMs = 12;

  // Animations
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;

  // ── Data ─────────────────────────────────────────────────────────────────────

  final List<ArcadeGame> _games = const [
    ArcadeGame(
      id: 'wordl',
      title: 'WORDL 3D',
      subtitle: 'Quantum Delivery Simulator',
      category: '3D SIM',
      description:
          'Navigate your quantum vessel across a live-rotating 3D globe. Collect cargo, dodge hazards, and race the clock in a zero-latency cloud experience.',
      bannerAsset: 'assets/wordl/assets/images/game_banner.png',
      engine: 'Three.js · WebGL 2.0',
      difficulty: 'HARD',
      difficultyColor: _kAmber,
      isPlayable: true,
      icon: LucideIcons.globe,
      themeColor: _kCyan,
      gradientColors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
      gameAssetFolder: 'assets/wordl',
      playersCount: '2.8k',
      rating: '4.9',
      tags: ['Physics', 'Cloud', 'Zero-Load'],
    ),
    ArcadeGame(
      id: 'voxel_realm',
      title: 'VOXEL REALM',
      subtitle: 'Luanti 3D Open World Sandbox',
      category: 'OPEN WORLD',
      description:
          'Build, mine, craft, and survive in an infinite procedurally generated 3D voxel universe. Powered by the native Luanti C++ engine with Voxelibre & Minetest support.',
      bannerAsset: 'assets/images/voxel_realm_banner.png',
      engine: 'Luanti C++ · 60 FPS Native',
      difficulty: 'MEDIUM',
      difficultyColor: _kGreen,
      isPlayable: true,
      icon: LucideIcons.box,
      themeColor: _kPurple,
      gradientColors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
      playersCount: '1.2k',
      rating: '4.8',
      tags: ['Voxel', 'Sandbox', 'Voxelibre', 'Minetest'],
    ),
    ArcadeGame(
      id: 'cyber_runner',
      title: 'CYBER RUN',
      subtitle: 'Neon Synthwave Runner 2099',
      category: 'ACTION',
      description:
          'Blast through neon futuristic megacities at hyper-speed. Hack grid gates, dodge energy walls, and dominate the global leaderboard.',
      bannerAsset: 'assets/images/cyber_run_banner.png',
      engine: 'WebGL Shader Core',
      difficulty: 'EXPERT',
      difficultyColor: _kPink,
      isPlayable: false,
      icon: LucideIcons.zap,
      themeColor: _kPink,
      gradientColors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
      playersCount: '—',
      rating: '5.0',
      tags: ['Action', 'Endless', 'PvP'],
    ),
  ];

  final List<LeaderboardEntry> _leaderboard = const [
    LeaderboardEntry(rank: 1, username: 'AriaMind_99',  score: 48920, level: 42, color: _kAmber),
    LeaderboardEntry(rank: 2, username: 'QuantumRider', score: 42150, level: 38, color: Color(0xFFB0BEC5)),
    LeaderboardEntry(rank: 3, username: 'CyberVoxel',   score: 39800, level: 35, color: Color(0xFFCD7F32)),
    LeaderboardEntry(rank: 4, username: 'NexusExplorer',score: 31200, level: 29, color: _kCyan),
    LeaderboardEntry(rank: 5, username: 'Starlight_X',  score: 28400, level: 24, color: _kPurple),
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

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
          .timeout(const Duration(seconds: 4));
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
    if (!game.isPlayable) { _toast('Coming soon to Nexal Cloud Arcade!'); return; }
    HapticFeedback.heavyImpact();

    final Widget destination = (game.id == 'voxel_realm' || game.engine.contains('Luanti'))
        ? LuantiGameScreen(gameTitle: game.title)
        : GameWebViewScreen(
            gameUrl: game.gameUrl,
            gameTitle: game.title,
            gameAssetFolder: game.gameAssetFolder ?? 'assets/wordl',
          );

    Navigator.push(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim, secondAnim) => destination,
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    ));
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
      backgroundColor: _kPurple,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  List<ArcadeGame> get _filtered =>
      _selectedCategory == 'ALL' ? _games : _games.where((g) => g.category == _selectedCategory).toList();

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final userName = user?.name ?? 'Nexal Pilot';
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBg,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(children: [
        // Full-screen background orbs (behind everything)
        _buildBgOrbs(),
        // Full-screen scrollable content
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Full-bleed Hero Header (behind status bar)
            SliverToBoxAdapter(child: _buildHeroHeader(userName, topPad)),
            // Category Filter
            SliverToBoxAdapter(child: _buildCategoryStrip()),
            // Stats Row
            SliverToBoxAdapter(child: _buildStatsRow()),
            // Section label
            SliverToBoxAdapter(child: _buildSectionLabel()),
            // Game Cards
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildGameCard(_filtered[i], i),
                  childCount: _filtered.length,
                ),
              ),
            ),
            // Leaderboard
            if (_showLeaderboard)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: _buildLeaderboard(),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ]),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────────

  Widget _buildBgOrbs() {
    return Stack(
      children: [
        // ── Full-Screen Background Image (Arcade BG.png) ──────────────────────────
        Positioned.fill(
          child: Image.asset(
            'assets/Arcade BG.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),

        // ── Crystal-Clear Gradient & Vignette Overlay ─────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kBg.withValues(alpha: 0.10),
                  _kBg.withValues(alpha: 0.25),
                  _kBg.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),

        // ── Top-left purple glow orb ─────────────────────────────────────────────
        AnimatedBuilder(
          animation: _floatCtrl,
          builder: (context, _) => Positioned(
            top: -80 + 20 * _floatCtrl.value,
            left: -60,
            child: _orb(300, _kPurple, 0.12),
          ),
        ),

        // ── Top-right cyan glow orb ──────────────────────────────────────────────
        AnimatedBuilder(
          animation: _floatCtrl,
          builder: (context, _) => Positioned(
            top: 200 - 20 * _floatCtrl.value,
            right: -80,
            child: _orb(260, _kCyan, 0.10),
          ),
        ),

        // ── Bottom-left pink glow orb ────────────────────────────────────────────
        AnimatedBuilder(
          animation: _floatCtrl,
          builder: (context, _) => Positioned(
            bottom: -60 + 15 * _floatCtrl.value,
            left: -40,
            child: _orb(320, _kPink, 0.10),
          ),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color, double alpha) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: alpha),
      boxShadow: [BoxShadow(color: color.withValues(alpha: alpha * 1.5), blurRadius: size * 0.45, spreadRadius: 24)],
    ),
  );

  // ── Full-Bleed Hero Header ────────────────────────────────────────────────────

  Widget _buildHeroHeader(String userName, double topPad) {
    final statusColor = _isCheckingBackend ? _kAmber : (_isBackendOnline ? _kGreen : _kAmber);
    final statusLabel = _isCheckingBackend
        ? 'CONNECTING...'
        : (_isBackendOnline ? 'LIVE · $_latencyMs ms' : 'OFFLINE');

    return Stack(
      children: [
        // Full-bleed transparent background
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(0, topPad, 0, 0),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: CustomPaint(
            painter: _GridPainter(_kCyan.withValues(alpha: 0.04)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Floating nav bar ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(children: [
                    _glassButton(
                      child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                      onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                    ),
                    const Spacer(),
                    // Live pill
                    _liveStatusPill(statusColor, statusLabel),
                    const SizedBox(width: 10),
                    // Leaderboard toggle
                    _glassButton(
                      highlight: _showLeaderboard,
                      child: Icon(LucideIcons.trophy,
                        color: _showLeaderboard ? _kCyan : Colors.white60, size: 19),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showLeaderboard = !_showLeaderboard);
                      },
                    ),
                  ]),
                ),

                // ── Hero content ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge row
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_kPink, _kPurple]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: _kPink.withValues(alpha: 0.4), blurRadius: 12)],
                          ),
                          child: Text('NEXAL CLOUD ARCADE',
                            style: GoogleFonts.outfit(
                              fontSize: 9, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 2.5,
                            )),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _kGreen.withValues(alpha: 0.4)),
                          ),
                          child: Text('⚡ ZERO CPU',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 8.5, fontWeight: FontWeight.bold,
                              color: _kGreen, letterSpacing: 1.5,
                            )),
                        ),
                      ]),

                      const SizedBox(height: 14),

                      // Giant ARCADE title
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [Color(0xFFFFFFFF), _kCyan, _kPurple],
                          stops: [0.0, 0.55, 1.0],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(r),
                        child: Text('ARCADE',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 88,
                            color: Colors.white,
                            letterSpacing: 8,
                            height: 0.9,
                          )),
                      ),

                      // Tagline
                      Text(
                        'Stream next-gen games live · Zero installs · 0% device load',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Player identity card
                      _buildPlayerChip(userName),

                      const SizedBox(height: 20),

                      // Neon accent divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _kCyan.withValues(alpha: 0.6),
                              _kPurple.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassButton({
    required Widget child,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: highlight
                  ? _kPurple.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: highlight
                    ? _kPurple.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _liveStatusPill(Color color, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) => Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color, blurRadius: 4 + 5 * _pulseCtrl.value)],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: 1.2,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildPlayerChip(String name) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: _kCyan.withValues(alpha: 0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            // Avatar
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kPurple, _kPink],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'N',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(name,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              Text('RANK #1  •  48,920 PTS',
                style: GoogleFonts.shareTechMono(
                  color: _kCyan, fontSize: 9.5, letterSpacing: 1,
                )),
            ]),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kAmber.withValues(alpha: 0.35)),
              ),
              child: Text('LVL 42',
                style: GoogleFonts.shareTechMono(
                  color: _kAmber, fontSize: 10, fontWeight: FontWeight.bold,
                )),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Category Strip ────────────────────────────────────────────────────────────

  Widget _buildCategoryStrip() {
    final cats = ['ALL', '3D SIM', 'OPEN WORLD', 'ACTION'];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final sel = _selectedCategory == cat;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = cat); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? _kCyan.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: sel ? _kCyan : Colors.white.withValues(alpha: 0.08),
                  width: sel ? 1.5 : 1,
                ),
                boxShadow: sel ? [BoxShadow(color: _kCyan.withValues(alpha: 0.3), blurRadius: 12)] : [],
              ),
              child: Text(cat,
                style: GoogleFonts.outfit(
                  color: sel ? _kCyan : Colors.white54,
                  fontSize: 11.5,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 1.5,
                )),
            ),
          );
        },
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(children: [
        _statChip(LucideIcons.activity, '$_latencyMs ms', 'LATENCY', _kGreen),
        const SizedBox(width: 10),
        _statChip(LucideIcons.cpu, 'WebGL 2.0', 'GPU ENGINE', _kCyan),
        const SizedBox(width: 10),
        _statChip(LucideIcons.server, 'Cloud', 'POWERED BY', _kPurple),
        const Spacer(),
        Text('${_filtered.length} GAMES',
          style: GoogleFonts.shareTechMono(
            color: Colors.white24, fontSize: 10, letterSpacing: 1,
          )),
      ]),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: GoogleFonts.shareTechMono(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold,
          )),
          Text(label, style: GoogleFonts.outfit(
            color: Colors.white38, fontSize: 8, letterSpacing: 0.8,
          )),
        ]),
      ]),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────────

  Widget _buildSectionLabel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kPink, _kPurple], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 10),
        Text('AVAILABLE ENGINES',
          style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 12,
            fontWeight: FontWeight.w800, letterSpacing: 2,
          )),
      ]),
    );
  }

  // ── Game Card ─────────────────────────────────────────────────────────────────

  Widget _buildGameCard(ArcadeGame game, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: game.themeColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(color: game.themeColor.withValues(alpha: 0.14), blurRadius: 24, spreadRadius: -4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Banner
            _buildCardBanner(game),
            // Body
            _buildCardBody(game),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: (index * 120).ms, duration: 450.ms)
     .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic, duration: 400.ms);
  }

  Widget _buildCardBanner(ArcadeGame game) {
    return SizedBox(
      height: 170,
      child: Stack(fit: StackFit.expand, children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: game.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Asset image
        if (game.bannerAsset != null)
          Positioned.fill(child: Image.asset(
            game.bannerAsset!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const SizedBox(),
          )),

        // Dark overlay
        Positioned.fill(child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        )),

        // Grid pattern overlay
        Positioned.fill(child: CustomPaint(painter: _GridPainter(game.themeColor.withValues(alpha: 0.06)))),

        // Top badges
        Positioned(top: 14, left: 14, right: 14, child: Row(children: [
          _badge(game.category, game.themeColor),
          const SizedBox(width: 8),
          _badge(game.difficulty, game.difficultyColor),
          const Spacer(),
          if (game.isPlayable)
            _badge('● LIVE', _kGreen)
          else
            _badge('⏳ SOON', Colors.white38),
        ])),

        // Bottom: icon + title
        Positioned(bottom: 14, left: 14, right: 14, child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: game.themeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: game.themeColor.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: game.themeColor.withValues(alpha: 0.4), blurRadius: 16)],
            ),
            child: Icon(game.icon, color: game.themeColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(game.title,
              style: GoogleFonts.bebasNeue(
                color: Colors.white, fontSize: 28, letterSpacing: 2,
              )),
            Text(game.subtitle,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11.5, fontWeight: FontWeight.w500,
              )),
          ])),
          // Rating
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(game.rating,
              style: GoogleFonts.outfit(
                color: _kAmber, fontSize: 18, fontWeight: FontWeight.w800,
              )),
            Text('RATING', style: GoogleFonts.outfit(
              color: Colors.white38, fontSize: 8.5, letterSpacing: 1,
            )),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildCardBody(ArcadeGame game) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Description
        Text(game.description,
          style: GoogleFonts.outfit(
            fontSize: 13, color: Colors.white.withValues(alpha: 0.65), height: 1.55,
          )),

        const SizedBox(height: 14),

        // Info row: engine + players
        Row(children: [
          Icon(LucideIcons.cpu, size: 13, color: Colors.white38),
          const SizedBox(width: 6),
          Text(game.engine, style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10.5)),
          const Spacer(),
          Icon(LucideIcons.users, size: 13, color: Colors.white38),
          const SizedBox(width: 6),
          Text(game.playersCount, style: GoogleFonts.outfit(
            color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w600,
          )),
        ]),

        const SizedBox(height: 12),

        // Tags
        if (game.tags.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: game.tags.map((t) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: game.themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: game.themeColor.withValues(alpha: 0.2)),
            ),
            child: Text(t, style: GoogleFonts.outfit(
              color: game.themeColor.withValues(alpha: 0.9),
              fontSize: 10, fontWeight: FontWeight.w600,
            )),
          )
        ).toList()),

        const SizedBox(height: 16),

        // Divider
        Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

        const SizedBox(height: 14),

        // Launch Button
        _buildLaunchButton(game),
      ]),
    );
  }

  Widget _buildLaunchButton(ArcadeGame game) {
    return GestureDetector(
      onTap: () => _launchGame(game),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: game.isPlayable
              ? LinearGradient(colors: game.gradientColors)
              : null,
          color: game.isPlayable ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: game.isPlayable
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: game.isPlayable
              ? [BoxShadow(color: game.themeColor.withValues(alpha: 0.4), blurRadius: 18, spreadRadius: -4)]
              : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            game.isPlayable ? LucideIcons.play : LucideIcons.clock,
            color: game.isPlayable ? Colors.black : Colors.white38,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            game.isPlayable ? 'LAUNCH CLOUD ENGINE' : 'COMING SOON',
            style: GoogleFonts.outfit(
              color: game.isPlayable ? Colors.black : Colors.white38,
              fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2,
            ),
          ),
          if (game.isPlayable) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('🚀', style: const TextStyle(fontSize: 13)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label, style: GoogleFonts.outfit(
        color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1,
      )),
    );
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────────

  Widget _buildLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kAmber.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [BoxShadow(color: _kAmber.withValues(alpha: 0.12), blurRadius: 24)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [_kAmber, _kPink],
                ).createShader(r),
                child: const Icon(LucideIcons.trophy, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text('HALL OF FAME', style: GoogleFonts.bebasNeue(
                color: Colors.white, fontSize: 22, letterSpacing: 2,
              )),
              const Spacer(),
              Text('GLOBAL', style: GoogleFonts.shareTechMono(
                color: Colors.white24, fontSize: 10, letterSpacing: 1,
              )),
            ]),

            const SizedBox(height: 4),
            Divider(color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 8),

            // Entries
            ..._leaderboard.map((e) => _buildLeaderboardRow(e)),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLeaderboardRow(LeaderboardEntry e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        // Rank
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: e.color.withValues(alpha: 0.12),
            border: Border.all(color: e.color.withValues(alpha: 0.4)),
          ),
          child: Center(child: Text(
            e.rank <= 3 ? ['🥇','🥈','🥉'][e.rank - 1] : '#${e.rank}',
            style: TextStyle(fontSize: e.rank <= 3 ? 14 : 10),
          )),
        ),
        const SizedBox(width: 12),
        // Name + Level
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.username, style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700,
          )),
          Text('LEVEL ${e.level}', style: GoogleFonts.shareTechMono(
            color: Colors.white38, fontSize: 9.5, letterSpacing: 1,
          )),
        ])),
        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: e.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${e.score} PTS', style: GoogleFonts.shareTechMono(
            color: e.color, fontSize: 12, fontWeight: FontWeight.bold,
          )),
        ),
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
