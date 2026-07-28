import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'game_webview_screen.dart';

// ─── Theme Colors ─────────────────────────────────────────────────────────────
const _kBg = Color(0xFF060913);
const _kCardBg = Color(0xFF0D1117);
const _kPurple = Color(0xFF7C3AED);
const _kCyan = Color(0xFF00E5FF);
const _kPink = Color(0xFFEC4899);
const _kGreen = Color(0xFF10B981);
const _kAmber = Color(0xFFF59E0B);

class LuantiGameScreen extends StatefulWidget {
  final String gameTitle;
  final String initialMode;

  const LuantiGameScreen({
    super.key,
    this.gameTitle = 'VOXEL REALM',
    this.initialMode = 'voxelibre',
  });

  @override
  State<LuantiGameScreen> createState() => _LuantiGameScreenState();
}

class _LuantiGameScreenState extends State<LuantiGameScreen>
    with TickerProviderStateMixin {
  Process? _gameProcess;
  bool _isRunning = false;
  int? _processPid;
  String _selectedGameId = 'voxelibre';
  bool _quickStart = true;
  final String _selectedWorld = 'hkj';
  String _statusMessage = 'READY TO LAUNCH';
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _selectedGameId = widget.initialMode;

    // Set immersive mode for gaming experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    // Auto-launch the Real Native Luanti C++ engine when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isRunning) {
        _launchLuantiEngine();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Locates the `luanti.exe` executable on the filesystem.
  File? _findLuantiExecutable() {
    if (kIsWeb) return null;
    try {
      final candidatePaths = [
        's:/All Code/Antigravity/Nexal_App/luanti-master/bin/luanti.exe',
        'C:/Nexal_App/luanti-master/bin/luanti.exe',
      ];
      try {
        final cur = Directory.current.path;
        candidatePaths.add('$cur/luanti-master/bin/luanti.exe');
        candidatePaths.add('$cur/bin/luanti.exe');
        candidatePaths.add('$cur/../luanti-master/bin/luanti.exe');
      } catch (_) {}

      try {
        Directory dir = Directory(Platform.resolvedExecutable).parent;
        for (int i = 0; i < 6; i++) {
          candidatePaths.add('${dir.path}/luanti-master/bin/luanti.exe');
          candidatePaths.add('${dir.path}/bin/luanti.exe');
          if (dir.parent.path == dir.path) break;
          dir = dir.parent;
        }
      } catch (_) {}

      for (final p in candidatePaths) {
        final f = File(p);
        if (f.existsSync()) {
          return f;
        }
      }
    } catch (e) {
      debugPrint('Error finding luanti executable: $e');
    }
    return null;
  }

  /// Finds the working directory (`luanti-master` folder).
  Directory? _findLuantiWorkDir() {
    if (kIsWeb) return null;
    final exe = _findLuantiExecutable();
    if (exe != null) {
      return exe.parent.parent; // parent of bin/
    }
    return null;
  }

  Future<void> _launchLuantiEngine() async {
    if (_isRunning) {
      _showToast('Luanti engine is already running!');
      return;
    }

    if (kIsWeb) {
      HapticFeedback.heavyImpact();
      setState(() {
        _statusMessage = 'SENDING LAUNCH SIGNAL TO SERVER...';
      });

      final gatewayBase = AppConfig.gatewayUrl;
      final backendUrls = [
        '$gatewayBase/game/api/launch-luanti',
        if (!gatewayBase.contains('localhost')) 'http://localhost:10000/game/api/launch-luanti',
        'http://127.0.0.1:10000/game/api/launch-luanti',
      ];

      bool launched = false;
      for (final url in backendUrls) {
        try {
          final res = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'gameId': _selectedGameId,
              'quickStart': _quickStart,
              'worldName': _selectedWorld,
            }),
          ).timeout(const Duration(seconds: 4));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final pid = data['pid'];
            setState(() {
              _isRunning = true;
              _processPid = pid;
              _statusMessage = 'ENGINE RUNNING (Server PID: $pid)';
            });
            _showToast('🚀 Luanti Voxel Engine Launched on PC!');
            launched = true;
            break;
          }
        } catch (_) {}
      }

      if (!launched) {
        setState(() {
          _statusMessage = 'PLEASE START GAME BACKEND (port 3005) OR RUN APP NATIVELY';
        });
        _showToast('Could not connect to Game Backend on port 3005. Please start backend server!');
      }
      return;
    }

    final exeFile = _findLuantiExecutable();
    final workDir = _findLuantiWorkDir();

    if (exeFile == null || !exeFile.existsSync()) {
      setState(() {
        _statusMessage = 'LAUNCHING IN-APP 3D ENGINE...';
      });
      _launchInAppVoxelGame();
      return;
    }

    HapticFeedback.heavyImpact();

    setState(() {
      _statusMessage = 'INITIALIZING C++ ENGINE...';
    });

    final args = <String>[];

    if (_quickStart) {
      args.add('--go');
      if (_selectedGameId == 'voxelibre') {
        args.addAll(['--gameid', 'voxelibre']);
      } else if (_selectedGameId == 'minetest_game' || _selectedGameId == 'minetest') {
        args.addAll(['--worldname', 'hkj', '--gameid', 'minetest']);
      }
    }

    try {
      final process = await Process.start(
        exeFile.path,
        args,
        workingDirectory: workDir?.path,
      );

      setState(() {
        _gameProcess = process;
        _isRunning = true;
        _processPid = process.pid;
        _statusMessage = 'ENGINE RUNNING · PID: ${process.pid}';
      });

      _showToast('🚀 Luanti Voxel Realm Launched! (60 FPS Native)');

      // Listen for process exit
      process.exitCode.then((code) {
        if (mounted) {
          setState(() {
            _isRunning = false;
            _gameProcess = null;
            _processPid = null;
            _statusMessage = 'SESSION ENDED (Exit code: $code)';
          });
        }
      });
    } catch (e) {
      debugPrint('Error launching Luanti: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'LAUNCH FAILED: $e';
        });
        _showToast('Failed to start Luanti: $e');
      }
    }
  }

  void _stopLuantiEngine() {
    if (_gameProcess != null) {
      _gameProcess!.kill(ProcessSignal.sigterm);
      setState(() {
        _isRunning = false;
        _gameProcess = null;
        _processPid = null;
        _statusMessage = 'ENGINE STOPPED';
      });
      _showToast('Luanti Engine stopped.');
    }
  }

  void _launchInAppVoxelGame() {
    HapticFeedback.heavyImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GameWebViewScreen(
          gameTitle: 'VOXEL REALM 3D',
          gameAssetFolder: 'assets/wordl',
        ),
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
        backgroundColor: _kPurple,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background Animated Color Orbs
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPurple.withValues(alpha: 0.22),
                boxShadow: [
                  BoxShadow(color: _kPurple.withValues(alpha: 0.30), blurRadius: 120, spreadRadius: 60),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kCyan.withValues(alpha: 0.16),
                boxShadow: [
                  BoxShadow(color: _kCyan.withValues(alpha: 0.25), blurRadius: 120, spreadRadius: 60),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPink.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(color: _kPink.withValues(alpha: 0.18), blurRadius: 90, spreadRadius: 40),
                ],
              ),
            ),
          ),

          // Main Layout Scroll View
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Nav Bar
                SliverToBoxAdapter(child: _buildTopNav()),
                // Hero Header Card
                SliverToBoxAdapter(child: _buildHeroCard()),
                // Mode Selector
                SliverToBoxAdapter(child: _buildModeSelector()),
                // Controls & Details
                SliverToBoxAdapter(child: _buildControlGuide()),
                const SliverToBoxAdapter(child: SizedBox(height: 44)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VOXEL REALM',
                style: GoogleFonts.bebasNeue(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'LUANTI NATIVE C++ ENGINE',
                style: GoogleFonts.shareTechMono(
                  color: _kCyan,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Engine Status Indicator Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: (_isRunning ? _kGreen : _kAmber).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: (_isRunning ? _kGreen : _kAmber).withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: (_isRunning ? _kGreen : _kAmber).withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) => Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRunning ? _kGreen : _kAmber,
                      boxShadow: [
                        BoxShadow(
                          color: _isRunning ? _kGreen : _kAmber,
                          blurRadius: 4 + 5 * _pulseCtrl.value,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isRunning ? 'ENGINE ACTIVE (${_processPid ?? 0})' : 'READY',
                  style: GoogleFonts.shareTechMono(
                    color: _isRunning ? _kGreen : _kAmber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _kPurple.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _kPurple.withValues(alpha: 0.18),
              blurRadius: 36,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _kPurple.withValues(alpha: 0.3),
                        _kCyan.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _kCyan.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(LucideIcons.box, color: _kCyan, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.gameTitle,
                            style: GoogleFonts.bebasNeue(
                              color: Colors.white,
                              fontSize: 36,
                              letterSpacing: 2.5,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kCyan.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'v5.10',
                              style: GoogleFonts.shareTechMono(
                                color: _kCyan,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Luanti Engine 5.10 · C++ Direct3D / OpenGL Acceleration',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              'Infinite procedurally-generated 3D voxel sandbox. Build, mine, craft, and explore custom worlds with full native C++ hardware acceleration at 60 FPS.',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13.5,
                height: 1.55,
              ),
            ),

            const SizedBox(height: 22),

            // Spec badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _specBadge('NATIVE C++', LucideIcons.cpu, _kCyan),
                _specBadge('60 FPS', LucideIcons.gauge, _kGreen),
                _specBadge('VOXELIBRE', LucideIcons.trees, _kPink),
                _specBadge('WORLD: HKJ', LucideIcons.globe, _kAmber),
              ],
            ),

            const SizedBox(height: 24),

            // Primary CTA: Start Real Native Luanti C++ Engine
            GestureDetector(
              onTap: _isRunning ? _stopLuantiEngine : _launchLuantiEngine,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 56,
                decoration: BoxDecoration(
                  gradient: _isRunning
                      ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                      : const LinearGradient(colors: [_kCyan, _kPurple, _kPink]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRunning ? Colors.redAccent : _kCyan).withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRunning ? LucideIcons.square : LucideIcons.play,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isRunning ? 'TERMINATE NATIVE PROCESS (${_processPid ?? 0})' : 'START REAL NATIVE LUANTI C++ ENGINE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Secondary Option: Play In-App 3D WebGL Realm
            GestureDetector(
              onTap: _launchInAppVoxelGame,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.globe, color: _kCyan, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'PLAY WEBGL 3D REALM (IN-APP CANVAS)',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            Center(
              child: Text(
                _statusMessage,
                style: GoogleFonts.shareTechMono(
                  color: _isRunning ? _kGreen : Colors.white.withValues(alpha: 0.42),
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _specBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.gamepad, color: _kCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                'SELECT GAME MODE',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _modeOptionCard(
                  id: 'voxelibre',
                  title: 'VOXELIBRE',
                  desc: 'Survival & Crafting',
                  icon: LucideIcons.trees,
                  color: _kGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeOptionCard(
                  id: 'minetest_game',
                  title: 'MINETEST',
                  desc: 'Classic Sandbox',
                  icon: LucideIcons.box,
                  color: _kCyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeOptionCard(
                  id: '',
                  title: 'MAIN MENU',
                  desc: 'Full GUI Launcher',
                  icon: LucideIcons.layoutGrid,
                  color: _kPurple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Start toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kAmber.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(LucideIcons.zap, color: _kAmber, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct In-Game Quick Start (--go)',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Skip menus and launch directly into world "hkj"',
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _quickStart,
                  activeThumbColor: _kCyan,
                  activeTrackColor: _kCyan.withValues(alpha: 0.3),
                  onChanged: (val) {
                    setState(() => _quickStart = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeOptionCard({
    required String id,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    final sel = _selectedGameId == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedGameId = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.16) : _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? color : Colors.white.withValues(alpha: 0.08),
            width: sel ? 1.8 : 1,
          ),
          boxShadow: sel
              ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16)]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: sel ? color : Colors.white54, size: 24),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.bebasNeue(
                color: sel ? Colors.white : Colors.white70,
                fontSize: 17,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlGuide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.gamepad2, color: _kCyan, size: 22),
                const SizedBox(width: 10),
                Text(
                  'KEYBOARD & MOUSE CONTROLS',
                  style: GoogleFonts.bebasNeue(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
            const SizedBox(height: 16),

            _controlRow('W / A / S / D', 'Move forward / left / backward / right'),
            _controlRow('SPACEBAR', 'Jump / Ascend in flight'),
            _controlRow('LEFT SHIFT', 'Sneak / Descend'),
            _controlRow('LEFT CLICK', 'Mine voxel block / Attack'),
            _controlRow('RIGHT CLICK', 'Build voxel block / Interact / Use item'),
            _controlRow('KEY "I"', 'Open Player Inventory'),
            _controlRow('KEY "ESC"', 'Pause Menu / Mouse release'),
          ],
        ),
      ),
    );
  }

  Widget _controlRow(String key, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kCyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kCyan.withValues(alpha: 0.35)),
            ),
            child: Text(
              key,
              style: GoogleFonts.shareTechMono(
                color: _kCyan,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              desc,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
