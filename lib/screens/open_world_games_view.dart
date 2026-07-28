import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'game_webview_screen.dart';

// ─── StitchMCP Cyber-Glassmorphism Palette & Styling Tokens ───────────────────

const Color _kBg = Color(0xFF060913);         // Deep Space Obsidian
const Color _kCardBg = Color(0xFF10131D);     // Surface Obsidian Container
const Color _kBioEmerald = Color(0xFF10B981); // Bio-Emerald Green Primary
const Color _kCyberCyan = Color(0xFF00E5FF);   // Cyber Cyan Accent
const Color _kSolarGold = Color(0xFFF59E0B);  // Solar Gold Achievement
const Color _kCosmicViolet = Color(0xFF8B5CF6);// Cosmic Violet Aura
const Color _kAuroraPink = Color(0xFFEC4899);  // Aurora Pink Highlight
const Color _kDeepBlue = Color(0xFF3B82F6);    // Deep Blue Sub-Surface

enum ArcadeViewMode { featured, grid, list }

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
  final List<String> controls;
  final String streamQuality;

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
    this.controls = const ['Touch / Mouse', 'WASD Movement', 'Space Action'],
    this.streamQuality = '60 FPS · 4K Stream',
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

// ─── Arcade Quest Model ───────────────────────────────────────────────────────

class ArcadeQuest {
  final String id;
  final String title;
  final String reward;
  final double progress;
  final IconData icon;
  final bool isCompleted;

  const ArcadeQuest({
    required this.id,
    required this.title,
    required this.reward,
    required this.progress,
    required this.icon,
    this.isCompleted = false,
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
  bool _showQuests = false;
  bool _showSearch = false;
  String _searchQuery = '';
  ArcadeViewMode _viewMode = ArcadeViewMode.featured;
  int _latencyMs = 12;

  // Controllers
  final TextEditingController _searchCtrl = TextEditingController();
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
      difficultyColor: _kSolarGold,
      isPlayable: true,
      icon: LucideIcons.globe,
      themeColor: _kCyberCyan,
      gradientColors: [Color(0xFF00E5FF), Color(0xFF7C3AED)],
      gameAssetFolder: 'assets/wordl',
      playersCount: '2.8k',
      rating: '4.9',
      tags: ['Physics', 'Cloud', 'Zero-Load', 'Interactive 3D'],
      controls: ['Drag to Rotate Globe', 'Tap Cargo to Deliver', 'Space Turbo Boost'],
      streamQuality: '60 FPS · 0% CPU Load',
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
      difficultyColor: _kBioEmerald,
      isPlayable: true,
      icon: LucideIcons.box,
      themeColor: _kCosmicViolet,
      gradientColors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
      gameAssetFolder: 'assets/voxel_realm',
      playersCount: '1.2k',
      rating: '4.8',
      tags: ['Voxel', 'Sandbox', 'Voxelibre', 'Minetest'],
      controls: ['WASD Move', 'Mouse Look / Touch Drag', 'Left Click Mine', 'Right Click Place'],
      streamQuality: '60 FPS Native · C++ Core',
    ),
    ArcadeGame(
      id: 'cyber_run',
      title: 'CYBER RUN 2099',
      subtitle: 'Zero-G Cloud Runner',
      category: 'ACTION',
      description:
          'Dash through neon-lit futuristic skyscrapers, dodge plasma barriers, and trigger quantum gravity shifts in this high-speed arcade runner.',
      bannerAsset: 'assets/images/cyber_run_banner.png',
      engine: 'Cloud Shader 4.0 · WebGL',
      difficulty: 'INSANE',
      difficultyColor: _kAuroraPink,
      isPlayable: false,
      icon: LucideIcons.zap,
      themeColor: _kAuroraPink,
      gradientColors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
      playersCount: '3.4k Interested',
      rating: '5.0',
      tags: ['Cyberpunk', 'High-Speed', 'Neon', 'Gravity Shift'],
      controls: ['Swipe/Arrow Left & Right', 'Space Jump', 'Down Slide'],
      streamQuality: '120 FPS Ultra Stream',
    ),
    ArcadeGame(
      id: 'quantum_arena',
      title: 'QUANTUM ARENA',
      subtitle: 'PvP Mech Battle Simulator',
      category: 'MULTIPLAYER',
      description:
          'Engage in real-time tactical mech battles against online pilots. Customize loadouts and dominate the cloud arena.',
      engine: 'Realtime Netcode · WebGL',
      difficulty: 'HARD',
      difficultyColor: _kSolarGold,
      isPlayable: false,
      icon: LucideIcons.swords,
      themeColor: _kDeepBlue,
      gradientColors: [Color(0xFF3B82F6), Color(0xFF00E5FF)],
      playersCount: '4.1k Pre-Reg',
      rating: '4.9',
      tags: ['PvP', 'Mechs', 'Multiplayer', 'Tactical'],
      controls: ['Virtual Dual Joysticks', 'Fire Weapons', 'Shield Deploy'],
      streamQuality: '60 FPS Low Latency',
    ),
  ];

  final List<LeaderboardEntry> _leaderboard = const [
    LeaderboardEntry(rank: 1, username: 'AriaMind_99',  score: 48920, level: 42, color: _kSolarGold),
    LeaderboardEntry(rank: 2, username: 'QuantumRider', score: 42150, level: 38, color: Color(0xFFB0BEC5)),
    LeaderboardEntry(rank: 3, username: 'CyberVoxel',   score: 39800, level: 35, color: Color(0xFFCD7F32)),
    LeaderboardEntry(rank: 4, username: 'NexusExplorer',score: 31200, level: 29, color: _kCyberCyan),
    LeaderboardEntry(rank: 5, username: 'Starlight_X',  score: 28400, level: 24, color: _kCosmicViolet),
  ];

  final List<ArcadeQuest> _quests = const [
    ArcadeQuest(
      id: 'q1',
      title: 'Complete 3 Quantum Deliveries in WORDL 3D',
      reward: '+500 EXP · 50 NEX',
      progress: 0.66,
      icon: LucideIcons.packageCheck,
    ),
    ArcadeQuest(
      id: 'q2',
      title: 'Mine 50 Voxel Blocks in VOXEL REALM',
      reward: '+800 EXP · Rare Skin',
      progress: 1.0,
      icon: LucideIcons.pickaxe,
      isCompleted: true,
    ),
    ArcadeQuest(
      id: 'q3',
      title: 'Maintain 60 FPS Cloud Session for 10 Mins',
      reward: '+300 EXP · Cloud Badge',
      progress: 0.35,
      icon: LucideIcons.gauge,
    ),
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
    _searchCtrl.dispose();
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
      _toast('"${game.title}" is coming soon to Nexal Cloud Arcade!');
      return;
    }
    HapticFeedback.heavyImpact();

    final Widget destination = GameWebViewScreen(
      gameUrl: game.gameUrl,
      gameTitle: game.title,
      gameAssetFolder: game.gameAssetFolder ?? 'assets/wordl',
    );

    Navigator.push(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
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
      backgroundColor: _kCosmicViolet,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  List<ArcadeGame> get _filteredGames {
    return _games.where((game) {
      final matchesCategory = _selectedCategory == 'ALL' || game.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          game.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          game.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          game.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();
  }

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
        // Isolated Background Canvas with RepaintBoundary for 60FPS scroll
        RepaintBoundary(child: _buildBgOrbs()),

        // Main Scrollable Body
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Floating Header Bar & Hero Section
            SliverToBoxAdapter(child: _buildHeaderSection(userName, topPad)),

            // Search Bar (if active)
            if (_showSearch)
              SliverToBoxAdapter(child: _buildSearchBar()),

            // Quests Section (if expanded)
            if (_showQuests)
              SliverToBoxAdapter(child: _buildQuestsSection()),

            // Category Selector & View Switcher
            SliverToBoxAdapter(child: _buildCategoryAndControlsRow()),

            // Games Display Grid/List
            _buildGamesSliver(),

            // Leaderboard Section
            if (_showLeaderboard)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: _buildLeaderboard(),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ]),
    );
  }

  // ── Background Layer ──────────────────────────────────────────────────────────

  Widget _buildBgOrbs() {
    return Stack(
      children: [
        // Arcade Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/Arcade BG.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),

        // StitchMCP Vignette Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kBg.withValues(alpha: 0.15),
                  _kBg.withValues(alpha: 0.45),
                  _kBg.withValues(alpha: 0.80),
                  _kBg,
                ],
                stops: const [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Top-left Bio-Emerald Glow Orb
        AnimatedBuilder(
          animation: _floatCtrl,
          builder: (context, _) => Positioned(
            top: -60 + 15 * _floatCtrl.value,
            left: -50,
            child: _orb(320, _kBioEmerald, 0.16),
          ),
        ),

        // Top-right Cyber Cyan Glow Orb
        AnimatedBuilder(
          animation: _floatCtrl,
          builder: (context, _) => Positioned(
            top: 180 - 20 * _floatCtrl.value,
            right: -60,
            child: _orb(280, _kCyberCyan, 0.14),
          ),
        ),

        // Bottom-left Cosmic Violet Glow Orb
        AnimatedBuilder(
          animation: _floatCtrl,
          builder: (context, _) => Positioned(
            bottom: 40 + 15 * _floatCtrl.value,
            left: -40,
            child: _orb(300, _kCosmicViolet, 0.14),
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
      boxShadow: [BoxShadow(color: color.withValues(alpha: alpha * 1.6), blurRadius: size * 0.45, spreadRadius: 20)],
    ),
  );

  // ── Header & Hero Section ────────────────────────────────────────────────────

  Widget _buildHeaderSection(String userName, double topPad) {
    final statusColor = _isCheckingBackend ? _kSolarGold : (_isBackendOnline ? _kBioEmerald : _kSolarGold);
    final statusLabel = _isCheckingBackend
        ? 'CONNECTING...'
        : (_isBackendOnline ? '⚡ LIVE · $_latencyMs ms' : 'OFFLINE');

    return Container(
      padding: EdgeInsets.fromLTRB(0, topPad + 10, 0, 0),
      child: CustomPaint(
        painter: _GridPainter(_kCyberCyan.withValues(alpha: 0.03)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floating Command Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _glassButton(
                  child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                  onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                ),
                const Spacer(),
                // Live Status Pill
                _liveStatusPill(statusColor, statusLabel),
                const SizedBox(width: 8),
                // Search Toggle
                _glassButton(
                  highlight: _showSearch,
                  child: Icon(LucideIcons.search,
                    color: _showSearch ? _kCyberCyan : Colors.white70, size: 18),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showSearch = !_showSearch);
                  },
                ),
                const SizedBox(width: 8),
                // Quests Toggle
                _glassButton(
                  highlight: _showQuests,
                  child: Icon(LucideIcons.target,
                    color: _showQuests ? _kSolarGold : Colors.white70, size: 18),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showQuests = !_showQuests);
                  },
                ),
                const SizedBox(width: 8),
                // Leaderboard Toggle
                _glassButton(
                  highlight: _showLeaderboard,
                  child: Icon(LucideIcons.trophy,
                    color: _showLeaderboard ? _kAuroraPink : Colors.white70, size: 18),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showLeaderboard = !_showLeaderboard);
                  },
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // Hero Main Title & Badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kAuroraPink, _kCosmicViolet]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _kAuroraPink.withValues(alpha: 0.4), blurRadius: 12)],
                      ),
                      child: Text('NEXAL CLOUD ARCADE',
                        style: GoogleFonts.sora(
                          fontSize: 9.5, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 2.2,
                        )),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kBioEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kBioEmerald.withValues(alpha: 0.4)),
                      ),
                      child: Text('⚡ 0% CPU LOAD',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 8.5, fontWeight: FontWeight.bold,
                          color: _kBioEmerald, letterSpacing: 1.5,
                        )),
                    ),
                  ]),

                  const SizedBox(height: 10),

                  // Sora Display Header
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFFFFFFFF), _kCyberCyan, _kBioEmerald],
                      stops: [0.0, 0.55, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(r),
                    child: Text('ARCADE',
                      style: GoogleFonts.sora(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1.0,
                      )),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Stream next-gen games live · Zero load · Cyber-Glass cloud',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Player Pilot HUD Chip
                  _buildPlayerChip(userName),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
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
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: highlight
                  ? _kCosmicViolet.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: highlight
                    ? _kCosmicViolet.withValues(alpha: 0.7)
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
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) => Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color, blurRadius: 3 + 4 * _pulseCtrl.value)],
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(label, style: GoogleFonts.shareTechMono(
              fontSize: 10.5, fontWeight: FontWeight.w700,
              color: Colors.white, letterSpacing: 1.1,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildPlayerChip(String name) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: _kCyberCyan.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            // Avatar
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_kBioEmerald, _kCyberCyan],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'N',
                  style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(name,
                style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
              Text('RANK #1  •  48,920 PTS',
                style: GoogleFonts.shareTechMono(
                  color: _kCyberCyan, fontSize: 9, letterSpacing: 0.8,
                )),
            ]),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kSolarGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kSolarGold.withValues(alpha: 0.35)),
              ),
              child: Text('LVL 42',
                style: GoogleFonts.shareTechMono(
                  color: _kSolarGold, fontSize: 9.5, fontWeight: FontWeight.bold,
                )),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Search Bar Section ────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kCyberCyan.withValues(alpha: 0.35)),
            ),
            child: Row(children: [
              const Icon(LucideIcons.search, color: _kCyberCyan, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search cloud games, tags, or engines...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(LucideIcons.x, color: Colors.white54, size: 16),
                ),
            ]),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.2, end: 0);
  }

  // ── Arcade Daily Quests Widget ───────────────────────────────────────────────

  Widget _buildQuestsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kSolarGold.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [BoxShadow(color: _kSolarGold.withValues(alpha: 0.1), blurRadius: 16)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(LucideIcons.target, color: _kSolarGold, size: 18),
              const SizedBox(width: 8),
              Text('DAILY ARCADE QUESTS',
                style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const Spacer(),
              Text('RESETS IN 14H', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 9.5)),
            ]),
            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 10),
            ..._quests.map((q) => _buildQuestTile(q)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildQuestTile(ArcadeQuest q) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(q.icon, color: q.isCompleted ? _kBioEmerald : Colors.white60, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: q.progress,
                minHeight: 4,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(q.isCompleted ? _kBioEmerald : _kCyberCyan),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: q.isCompleted ? _kBioEmerald.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: q.isCompleted ? _kBioEmerald : Colors.white24),
          ),
          child: Text(
            q.isCompleted ? 'CLAIMED' : q.reward,
            style: GoogleFonts.shareTechMono(
              color: q.isCompleted ? _kBioEmerald : _kSolarGold,
              fontSize: 9.5, fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Category & View Controls Row ─────────────────────────────────────────────

  Widget _buildCategoryAndControlsRow() {
    final categories = ['ALL', '3D SIM', 'OPEN WORLD', 'ACTION', 'MULTIPLAYER'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final sel = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = cat); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? _kCyberCyan.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? _kCyberCyan : Colors.white.withValues(alpha: 0.08),
                            width: sel ? 1.4 : 1,
                          ),
                          boxShadow: sel ? [BoxShadow(color: _kCyberCyan.withValues(alpha: 0.25), blurRadius: 10)] : [],
                        ),
                        child: Text(cat,
                          style: GoogleFonts.sora(
                            color: sel ? _kCyberCyan : Colors.white60,
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: 1.2,
                          )),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(children: [
                _viewModeBtn(ArcadeViewMode.featured, LucideIcons.layoutTemplate),
                _viewModeBtn(ArcadeViewMode.grid, LucideIcons.layoutGrid),
                _viewModeBtn(ArcadeViewMode.list, LucideIcons.list),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _viewModeBtn(ArcadeViewMode mode, IconData icon) {
    final sel = _viewMode == mode;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _viewMode = mode); },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: sel ? _kCosmicViolet.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 15, color: sel ? _kCyberCyan : Colors.white38),
      ),
    );
  }

  // ── Games Display Switcher ───────────────────────────────────────────────────

  Widget _buildGamesSliver() {
    final games = _filteredGames;
    if (games.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text('No cloud games matching "$_searchQuery"',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
          ),
        ),
      );
    }

    if (_viewMode == ArcadeViewMode.grid) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.76,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _buildGridCard(games[i], i),
            childCount: games.length,
          ),
        ),
      );
    } else if (_viewMode == ArcadeViewMode.list) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _buildListCard(games[i], i),
            childCount: games.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _buildFeaturedCard(games[i], i),
          childCount: games.length,
        ),
      ),
    );
  }

  // ── Featured Game Card ───────────────────────────────────────────────────────

  Widget _buildFeaturedCard(ArcadeGame game, int index) {
    return GestureDetector(
      onTap: () => _showGameDetailsSheet(game),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: _kCardBg.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: game.themeColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(color: game.themeColor.withValues(alpha: 0.14), blurRadius: 20, spreadRadius: -2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildCardBanner(game),
              _buildCardBody(game),
            ]),
          ),
        ),
      ).animate().fadeIn(delay: (index * 80).ms, duration: 350.ms)
       .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic, duration: 350.ms),
    );
  }

  Widget _buildCardBanner(ArcadeGame game) {
    return SizedBox(
      height: 160,
      child: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: game.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        if (game.bannerAsset != null)
          Positioned.fill(child: Image.asset(
            game.bannerAsset!,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, st) => const SizedBox(),
          )),

        Positioned.fill(child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
        )),

        Positioned.fill(child: CustomPaint(painter: _GridPainter(game.themeColor.withValues(alpha: 0.06)))),

        Positioned(top: 12, left: 12, right: 12, child: Row(children: [
          _badge(game.category, game.themeColor),
          const SizedBox(width: 6),
          _badge(game.difficulty, game.difficultyColor),
          const Spacer(),
          if (game.isPlayable)
            _badge('● LIVE STREAM', _kBioEmerald)
          else
            _badge('⏳ SOON', Colors.white38),
        ])),

        Positioned(bottom: 12, left: 12, right: 12, child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: game.themeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: game.themeColor.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: game.themeColor.withValues(alpha: 0.3), blurRadius: 12)],
            ),
            child: Icon(game.icon, color: game.themeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(game.title,
              style: GoogleFonts.sora(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5,
              )),
            Text(game.subtitle,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11, fontWeight: FontWeight.w500,
              )),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.star, color: _kSolarGold, size: 14),
              const SizedBox(width: 4),
              Text(game.rating,
                style: GoogleFonts.sora(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800,
                )),
            ]),
            Text('RATING', style: GoogleFonts.sora(
              color: Colors.white38, fontSize: 8, letterSpacing: 0.8,
            )),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildCardBody(ArcadeGame game) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(game.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 12.5, color: Colors.white.withValues(alpha: 0.65), height: 1.5,
          )),

        const SizedBox(height: 12),

        Row(children: [
          const Icon(LucideIcons.cpu, size: 12, color: Colors.white38),
          const SizedBox(width: 5),
          Text(game.engine, style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10)),
          const Spacer(),
          const Icon(LucideIcons.users, size: 12, color: Colors.white38),
          const SizedBox(width: 5),
          Text(game.playersCount, style: GoogleFonts.outfit(
            color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600,
          )),
        ]),

        const SizedBox(height: 10),

        if (game.tags.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: game.tags.map((t) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: game.themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: game.themeColor.withValues(alpha: 0.2)),
            ),
            child: Text(t, style: GoogleFonts.outfit(
              color: game.themeColor.withValues(alpha: 0.9),
              fontSize: 9.5, fontWeight: FontWeight.w600,
            )),
          )
        ).toList()),

        const SizedBox(height: 14),

        _buildLaunchButton(game),
      ]),
    );
  }

  Widget _buildLaunchButton(ArcadeGame game) {
    return GestureDetector(
      onTap: () => _launchGame(game),
      child: Container(
        height: 46,
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
              ? [BoxShadow(color: game.themeColor.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: -3)]
              : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            game.isPlayable ? LucideIcons.play : LucideIcons.clock,
            color: game.isPlayable ? Colors.black : Colors.white38,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            game.isPlayable ? 'LAUNCH CLOUD ENGINE' : 'COMING SOON',
            style: GoogleFonts.sora(
              color: game.isPlayable ? Colors.black : Colors.white38,
              fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.8,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Grid Layout Card ────────────────────────────────────────────────────────

  Widget _buildGridCard(ArcadeGame game, int index) {
    return GestureDetector(
      onTap: () => _showGameDetailsSheet(game),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: game.themeColor.withValues(alpha: 0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 5,
              child: Stack(fit: StackFit.expand, children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: game.gradientColors),
                  ),
                ),
                if (game.bannerAsset != null)
                  Image.asset(game.bannerAsset!, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => const SizedBox()),
                Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.35))),
                Positioned(top: 8, left: 8, child: _badge(game.category, game.themeColor)),
              ]),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(game.title,
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(game.engine,
                    style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 8.5),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _launchGame(game),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: game.isPlayable ? LinearGradient(colors: game.gradientColors) : null,
                        color: game.isPlayable ? null : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(game.isPlayable ? 'PLAY' : 'SOON',
                          style: GoogleFonts.sora(color: game.isPlayable ? Colors.black : Colors.white38,
                            fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms);
  }

  // ── List Layout Card ────────────────────────────────────────────────────────

  Widget _buildListCard(ArcadeGame game, int index) {
    return GestureDetector(
      onTap: () => _showGameDetailsSheet(game),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kCardBg.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: game.themeColor.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: game.gradientColors),
            ),
            child: Icon(game.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(game.title, style: GoogleFonts.sora(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Text('${game.category} · ${game.engine}', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 9.5)),
            ]),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _launchGame(game),
            style: ElevatedButton.styleFrom(
              backgroundColor: game.isPlayable ? game.themeColor : Colors.white10,
              foregroundColor: game.isPlayable ? Colors.black : Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(game.isPlayable ? 'LAUNCH' : 'SOON',
              style: GoogleFonts.sora(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ]),
      ),
    ).animate().fadeIn(delay: (index * 50).ms);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label, style: GoogleFonts.sora(
        color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1,
      )),
    );
  }

  // ── Interactive Game Details Modal Sheet ────────────────────────────────────

  void _showGameDetailsSheet(ArcadeGame game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F1D).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: game.themeColor.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  SizedBox(
                    height: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(fit: StackFit.expand, children: [
                        Container(decoration: BoxDecoration(gradient: LinearGradient(colors: game.gradientColors))),
                        if (game.bannerAsset != null)
                          Image.asset(game.bannerAsset!, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => const SizedBox()),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.4))),
                        Positioned(bottom: 14, left: 14, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(game.title, style: GoogleFonts.sora(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          Text(game.subtitle, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                        ])),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text('GAME OVERVIEW', style: GoogleFonts.sora(color: _kCyberCyan, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text(game.description, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5)),

                  const SizedBox(height: 20),

                  Text('LIVE CLOUD SPECS', style: GoogleFonts.sora(color: _kCosmicViolet, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _specBadge(LucideIcons.gauge, 'Stream Quality', game.streamQuality, _kBioEmerald),
                    _specBadge(LucideIcons.cpu, 'Engine Architecture', game.engine, _kCyberCyan),
                    _specBadge(LucideIcons.activity, 'Netcode Latency', '$_latencyMs ms Live Ping', _kSolarGold),
                    _specBadge(LucideIcons.users, 'Active Pilots', game.playersCount, _kAuroraPink),
                  ]),

                  const SizedBox(height: 20),

                  Text('CONTROLS OVERVIEW', style: GoogleFonts.sora(color: _kSolarGold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  ...game.controls.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      const Icon(LucideIcons.gamepad2, color: Colors.white54, size: 14),
                      const SizedBox(width: 8),
                      Text(c, style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5)),
                    ]),
                  )),

                  const SizedBox(height: 28),

                  _buildLaunchButton(game),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _specBadge(IconData icon, String label, String value, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9)),
            Text(value, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  // ── Leaderboard Section ───────────────────────────────────────────────────────

  Widget _buildLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCardBg.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kSolarGold.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [BoxShadow(color: _kSolarGold.withValues(alpha: 0.12), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(colors: [_kSolarGold, _kAuroraPink]).createShader(r),
                child: const Icon(LucideIcons.trophy, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text('HALL OF FAME', style: GoogleFonts.sora(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const Spacer(),
              Text('GLOBAL PILOTS', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 9.5)),
            ]),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 6),
            ..._leaderboard.map((e) => _buildLeaderboardRow(e)),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildLeaderboardRow(LeaderboardEntry e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: e.color.withValues(alpha: 0.14),
            border: Border.all(color: e.color.withValues(alpha: 0.45)),
          ),
          child: Center(child: Text(
            e.rank <= 3 ? ['🥇','🥈','🥉'][e.rank - 1] : '#${e.rank}',
            style: TextStyle(fontSize: e.rank <= 3 ? 13 : 9.5, fontWeight: FontWeight.bold, color: Colors.white),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.username, style: GoogleFonts.sora(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text('LEVEL ${e.level}', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 9)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: e.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${e.score} PTS', style: GoogleFonts.shareTechMono(
            color: e.color, fontSize: 11.5, fontWeight: FontWeight.bold,
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
