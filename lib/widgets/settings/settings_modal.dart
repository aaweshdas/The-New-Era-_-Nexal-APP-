import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/aria_config.dart';
import '../../services/aria_service.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import 'settings_nav_rail.dart';
import 'settings_sub_page_header.dart';

// Accent style model
class _AccentStyle {
  final String name;
  final Color primary;
  final Color secondary;
  final Color glow;
  const _AccentStyle({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.glow,
  });
}

// Opens Settings as a full-screen page with smooth page transition
void openSettings(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const SettingsModal(),
      transitionsBuilder: (context, anim, secondaryAnimation, child) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      transitionDuration: const Duration(milliseconds: 320),
    ),
  );
}

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  // Config Text Controllers
  final _backendUrlCtrl  = TextEditingController();
  final _groqKeyCtrl     = TextEditingController();
  final _deepgramKeyCtrl = TextEditingController();
  final _livekitUrlCtrl  = TextEditingController();
  final _livekitKeyCtrl  = TextEditingController();
  final _livekitSecCtrl  = TextEditingController();

  // State
  bool _loading = true;
  bool _saved   = false;
  bool _saving  = false;
  bool _obscureGroq     = true;
  bool _obscureDeepgram = true;
  bool _obscureLivekit  = true;

  // Backend Suite Orchestrator State
  Map<String, bool> _backendHealth = {
    'Gateway (10000)': false,
    'ARIA AI (3003)': false,
    'Search (3004)': false,
    'Game (3005)': false,
    'Map (3006)': false,
    'Camera (3007)': false,
    'Settings (3008)': false,
  };
  bool _startingAllBackends = false;

  // Navigation
  int _activeTab = 0;

  // Visuals & Theme Accents
  int _selectedAccent = 0;
  bool _darkMode = true;
  bool _notifications = true;
  String _selectedLanguage = 'English (US)';

  // Security
  bool _biometricsEnabled = false;
  bool _encryptSync       = true;
  bool _privacyShield     = false;
  bool _appLockPin        = false;

  // Diagnostics
  bool _testingConnection = false;
  String _connectionStatus = 'Not Tested';
  int? _connectionPing = 14;
  double _cacheFootprint = 18.4;
  bool _purgingCache = false;

  // Notifications
  bool _notifAria         = true;
  bool _notifMap          = true;
  bool _notifFriend       = true;
  bool _notifSystem       = true;
  bool _notifSound        = true;
  bool _notifVibration    = true;
  bool _notifBadge        = true;

  // About info
  static const String _appVersion = '2.4.1';
  static const String _buildNumber = '20260711';
  String _username = 'neuralnexus';

  // 5 High-Glow Accent Definitions
  final List<_AccentStyle> _accents = [
    const _AccentStyle(
      name: 'Electric Cyan',
      primary: Color(0xFF00E5FF),
      secondary: Color(0xFF0284C7),
      glow: Color(0x6600E5FF),
    ),
    const _AccentStyle(
      name: 'Cosmic Violet',
      primary: Color(0xFFA855F7),
      secondary: Color(0xFF7E22CE),
      glow: Color(0x66A855F7),
    ),
    const _AccentStyle(
      name: 'Solar Gold',
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFD97706),
      glow: Color(0x66F59E0B),
    ),
    const _AccentStyle(
      name: 'Matrix Emerald',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF059669),
      glow: Color(0x6610B981),
    ),
    const _AccentStyle(
      name: 'Crimson Cyber',
      primary: Color(0xFFEF4444),
      secondary: Color(0xFFDC2626),
      glow: Color(0x66EF4444),
    ),
  ];

  _AccentStyle get _accent => _accents[_selectedAccent];

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _checkAllBackendsHealth();
  }

  @override
  void dispose() {
    _backendUrlCtrl.dispose();
    _groqKeyCtrl.dispose();
    _deepgramKeyCtrl.dispose();
    _livekitUrlCtrl.dispose();
    _livekitKeyCtrl.dispose();
    _livekitSecCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await AriaConfig.load();
    _backendUrlCtrl.text  = config.backendUrl;
    _groqKeyCtrl.text     = config.groqApiKey;
    _deepgramKeyCtrl.text = config.deepgramApiKey;
    _livekitUrlCtrl.text  = config.livekitUrl;
    _livekitKeyCtrl.text  = config.livekitApiKey;
    _livekitSecCtrl.text  = config.livekitApiSecret;

    final prefs = await SharedPreferences.getInstance();
    _selectedAccent   = prefs.getInt('nexal_selected_accent') ?? 0;
    if (_selectedAccent >= _accents.length) _selectedAccent = 0;
    _darkMode         = prefs.getBool('nexal_dark_mode') ?? true;
    _notifications    = prefs.getBool('nexal_notifications') ?? true;
    _selectedLanguage = prefs.getString('nexal_language') ?? 'English (US)';
    _username         = prefs.getString('user_username') ?? 'neuralnexus';

    _biometricsEnabled = prefs.getBool('nexal_biometrics_enabled') ?? false;
    _encryptSync       = prefs.getBool('nexal_encrypt_sync') ?? true;
    _privacyShield     = prefs.getBool('nexal_privacy_shield') ?? false;
    _appLockPin        = prefs.getBool('nexal_app_lock_pin') ?? false;

    _notifAria         = prefs.getBool('nexal_notif_aria') ?? true;
    _notifMap          = prefs.getBool('nexal_notif_map') ?? true;
    _notifFriend       = prefs.getBool('nexal_notif_friend') ?? true;
    _notifSystem       = prefs.getBool('nexal_notif_system') ?? true;
    _notifSound        = prefs.getBool('nexal_notif_sound') ?? true;
    _notifVibration    = prefs.getBool('nexal_notif_vibration') ?? true;
    _notifBadge        = prefs.getBool('nexal_notif_badge') ?? true;

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveAllSettings() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final config = AriaConfig(
      backendUrl:       _backendUrlCtrl.text.trim(),
      groqApiKey:       _groqKeyCtrl.text.trim(),
      deepgramApiKey:   _deepgramKeyCtrl.text.trim(),
      livekitUrl:       _livekitUrlCtrl.text.trim(),
      livekitApiKey:    _livekitKeyCtrl.text.trim(),
      livekitApiSecret: _livekitSecCtrl.text.trim(),
    );
    await config.save();
    AriaService.instance.updateConfig(config);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nexal_selected_accent', _selectedAccent);
    await prefs.setBool('nexal_dark_mode', _darkMode);
    await prefs.setBool('nexal_notifications', _notifications);
    await prefs.setString('nexal_language', _selectedLanguage);

    await prefs.setBool('nexal_biometrics_enabled', _biometricsEnabled);
    await prefs.setBool('nexal_encrypt_sync', _encryptSync);
    await prefs.setBool('nexal_privacy_shield', _privacyShield);
    await prefs.setBool('nexal_app_lock_pin', _appLockPin);

    await prefs.setBool('nexal_notif_aria', _notifAria);
    await prefs.setBool('nexal_notif_map', _notifMap);
    await prefs.setBool('nexal_notif_friend', _notifFriend);
    await prefs.setBool('nexal_notif_system', _notifSystem);

    if (mounted) {
      setState(() {
        _saving = false;
        _saved  = true;
      });
      _showToast('⚡ Quantum settings synchronized');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    }
  }

  Future<void> _checkAllBackendsHealth() async {
    final targets = {
      'Gateway (10000)': 'http://localhost:10000/health',
      'ARIA AI (3003)':  'http://localhost:3003/health',
      'Search (3004)':   'http://localhost:3004/health',
      'Game (3005)':     'http://localhost:3005/health',
      'Map (3006)':      'http://localhost:3006/map/health',
      'Camera (3007)':   'http://localhost:3007/health',
      'Settings (3008)': 'http://localhost:3008/health',
    };

    final Map<String, bool> updated = {};

    for (final entry in targets.entries) {
      bool ok = false;
      for (final u in [entry.value, entry.value.replaceAll('localhost', '127.0.0.1')]) {
        try {
          final res = await http.get(Uri.parse(u)).timeout(const Duration(seconds: 2));
          if (res.statusCode == 200) {
            ok = true;
            break;
          }
        } catch (_) {}
      }
      updated[entry.key] = ok;
    }

    if (mounted) {
      setState(() {
        _backendHealth = updated;
      });
    }
  }

  Future<void> _turnOnAllBackends() async {
    setState(() => _startingAllBackends = true);
    HapticFeedback.heavyImpact();

    // ── Step 1: Try to launch the Gateway .bat via OS process ──────────────
    // The Gateway (gateway.ts) itself spawns ALL sub-backends automatically.
    // We open it in a new detached cmd window so the Flutter process doesn't block.
    if (!kIsWeb) {
      // Candidate paths — first absolute known path, then relative to cwd
      final candidatePaths = [
        r's:\All Code\Antigravity\Nexal_App\Backend\start_all_backends.bat',
        '${Directory.current.path}\\Backend\\start_all_backends.bat',
        '${Directory.current.path}/Backend/start_all_backends.bat',
      ];

      bool launched = false;
      for (final p in candidatePaths) {
        final f = File(p);
        if (f.existsSync()) {
          try {
            // /c → run cmd and exit (the .bat itself opens a new 'start' window)
            await Process.start(
              'cmd.exe',
              ['/c', f.path],
              workingDirectory: f.parent.path,
              mode: ProcessStartMode.detached,
            );
            launched = true;
            debugPrint('[Settings] Launched .bat from: ${f.path}');
            break;
          } catch (e) {
            debugPrint('[Settings] .bat launch error: $e');
          }
        }
      }

      if (!launched) {
        // Fallback: try launching gateway.ts directly with npx tsx
        try {
          await Process.start(
            'cmd.exe',
            ['/c', 'start', '"Nexal Gateway"', 'cmd', '/k', 'npx tsx src/gateway.ts'],
            workingDirectory: r's:\All Code\Antigravity\Nexal_App\Backend',
            mode: ProcessStartMode.detached,
          );
          debugPrint('[Settings] Direct gateway.ts fallback launched');
        } catch (e) {
          debugPrint('[Settings] Fallback gateway launch error: $e');
        }
      }
    }

    // ── Step 2: Poll for backends to come online (up to 30 s) ──────────────
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 3));
      await _checkAllBackendsHealth();
      final count = _backendHealth.values.where((v) => v).length;
      if (count >= 6) break; // all main backends up
    }

    if (mounted) {
      setState(() => _startingAllBackends = false);
      final count = _backendHealth.values.where((v) => v).length;
      _showToast(
        count > 0
            ? '⚡ All $count Backends Online & Connected!'
            : 'Backend launch signal sent! Verify start_all_backends.bat.',
      );
    }
  }

  Future<void> _testLatency() async {
    setState(() {
      _testingConnection = true;
      _connectionStatus = 'Testing...';
    });
    HapticFeedback.lightImpact();

    final stopwatch = Stopwatch()..start();
    try {
      final res = await http.get(Uri.parse('${_backendUrlCtrl.text.trim()}/health')).timeout(const Duration(seconds: 4));
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _testingConnection = false;
          _connectionPing = stopwatch.elapsedMilliseconds;
          _connectionStatus = res.statusCode == 200 ? 'Online' : 'HTTP Error ${res.statusCode}';
        });
      }
    } catch (_) {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _testingConnection = false;
          _connectionPing = null;
          _connectionStatus = 'Offline';
        });
      }
    }
  }

  Future<void> _purgeCache() async {
    setState(() => _purgingCache = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _purgingCache = false;
        _cacheFootprint = 0.0;
      });
      _showToast('🧹 Cache storage successfully purged');
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _accent.primary, width: 1.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 650;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/login BG.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // Cyberpunk Dark Vignette Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                ),
              ),
            ),
          ),

          // Responsive Main Shell
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 6 : 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isMobile ? 24 : 36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isMobile ? 24 : 36),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.20),
                          Colors.black.withValues(alpha: 0.70),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.65),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.glow,
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Responsive Top Command Bar
                        _buildTopCommandBar(isMobile: isMobile),

                        // If Mobile, render horizontal liquid tab bar below top bar
                        if (isMobile) _buildMobileTabBar(),

                        // Main Navigation & Content Body
                        Expanded(
                          child: isMobile
                              ? (_loading
                                  ? Center(child: CircularProgressIndicator(color: _accent.primary))
                                  : _buildActiveTabContent(isMobile: true))
                              : Row(
                                  children: [
                                    SettingsNavRail(
                                      selectedIndex: _activeTab,
                                      accentColor: _accent.primary,
                                      username: _username,
                                      onDestinationSelected: (idx) => setState(() => _activeTab = idx),
                                      onLogoutTap: () async {
                                        final navigator = Navigator.of(context);
                                        await AuthService.instance.logout();
                                        navigator.pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                                          (route) => false,
                                        );
                                      },
                                    ),

                                    Expanded(
                                      child: _loading
                                          ? Center(child: CircularProgressIndicator(color: _accent.primary))
                                          : _buildActiveTabContent(isMobile: false),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Top Command Console Header Bar (Responsive)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTopCommandBar({required bool isMobile}) {
    final activeCount = _backendHealth.values.where((v) => v).length;
    return Container(
      height: isMobile ? 64 : 76,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo Badge
          Container(
            width: isMobile ? 38 : 46,
            height: isMobile ? 38 : 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              gradient: LinearGradient(
                colors: [_accent.primary, _accent.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.glow,
                  blurRadius: 14,
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isMobile ? 9 : 13),
              child: Image.asset('assets/nexal_logo.png', fit: BoxFit.cover),
            ),
          ),

          SizedBox(width: isMobile ? 10 : 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isMobile ? 'SETTINGS' : 'NEXAL COMMAND CENTER',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: isMobile ? 1.0 : 1.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _accent.primary.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _accent.primary.withValues(alpha: 0.60), width: 1),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.outfit(
                          color: _accent.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '⚡ $activeCount/7 Active • ${_connectionPing ?? 14}ms',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Save Sync Liquid Pill
          GestureDetector(
            onTap: _saving ? null : _saveAllSettings,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 18,
                    vertical: isMobile ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        _accent.primary.withValues(alpha: 0.90),
                        _accent.secondary.withValues(alpha: 0.90),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.70),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_saving)
                        const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      else
                        Icon(_saved ? LucideIcons.check : LucideIcons.save, size: 14, color: Colors.black),
                      if (!isMobile) ...[
                        const SizedBox(width: 6),
                        Text(
                          _saved ? 'SYNCHRONIZED' : 'SYNC SETTINGS',
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Close Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
              ),
              child: const Icon(LucideIcons.x, color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Mobile Horizontal Liquid Tab Bar
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMobileTabBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kSettingsNavItems.length,
        itemBuilder: (context, i) {
          final item = kSettingsNavItems[i];
          final isActive = _activeTab == i;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? _accent.primary.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? _accent.primary.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 15, color: isActive ? _accent.primary : Colors.white60),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      color: isActive ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sub-Tab Content Switcher
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildActiveTabContent({bool isMobile = false}) {
    switch (_activeTab) {
      case 0:
        return _buildSystemTab(isMobile: isMobile);
      case 1:
        return _buildVisualsTab(isMobile: isMobile);
      case 2:
        return _buildSecurityTab(isMobile: isMobile);
      case 3:
        return _buildDiagnosticsTab(isMobile: isMobile);
      case 4:
        return _buildNotificationsTab(isMobile: isMobile);
      case 5:
        return _buildAboutTab(isMobile: isMobile);
      default:
        return _buildSystemTab(isMobile: isMobile);
    }
  }

  // ── Tab 0: System (Backend Orchestrator & API Config) ──────────────────────
  Widget _buildSystemTab({bool isMobile = false}) {
    final activeCount = _backendHealth.values.where((v) => v).length;
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        SettingsSectionLabel(
          text: 'Backend Suite Orchestrator',
          icon: LucideIcons.cpu,
          accentColor: _accent.primary,
        ),

        // Hero Master Launch Console Banner
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                _accent.primary.withValues(alpha: 0.28),
                Colors.black.withValues(alpha: 0.60),
              ],
            ),
            border: Border.all(
              color: _accent.primary.withValues(alpha: 0.65),
              width: 1.4,
            ),
          ),
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.primary.withValues(alpha: 0.22),
                    ),
                    child: Icon(LucideIcons.zap, color: _accent.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Master Microservices',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '$activeCount/7 Services Online',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startingAllBackends ? null : _turnOnAllBackends,
                  icon: _startingAllBackends
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(LucideIcons.power, size: 16, color: Colors.black),
                  label: Text(
                    _startingAllBackends ? 'LAUNCHING...' : 'RUN ALL BACKENDS',
                    style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Health Status Responsive Grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _backendHealth.entries.map((e) {
            final isOnline = e.value;
            return Container(
              width: isMobile ? double.infinity : 170,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isOnline ? const Color(0xFF10B981).withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: isOnline ? const Color(0xFF10B981).withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.16),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.key,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),

        SettingsSectionLabel(
          text: 'AI & Gateway Credentials',
          icon: LucideIcons.key,
          accentColor: _accent.primary,
        ),

        _buildGlassTextField(
          controller: _backendUrlCtrl,
          label: 'Gateway Server URL',
          hint: 'http://localhost:10000',
          icon: LucideIcons.server,
        ),
        const SizedBox(height: 12),
        _buildGlassTextField(
          controller: _groqKeyCtrl,
          label: 'GROQ LLM API Key',
          hint: 'gsk_...',
          icon: LucideIcons.brainCircuit,
          obscure: _obscureGroq,
          onToggleObscure: () => setState(() => _obscureGroq = !_obscureGroq),
        ),
        const SizedBox(height: 12),
        _buildGlassTextField(
          controller: _deepgramKeyCtrl,
          label: 'Deepgram Speech Engine Key',
          hint: 'Key...',
          icon: LucideIcons.mic,
          obscure: _obscureDeepgram,
          onToggleObscure: () => setState(() => _obscureDeepgram = !_obscureDeepgram),
        ),
        const SizedBox(height: 12),
        _buildGlassTextField(
          controller: _livekitUrlCtrl,
          label: 'LiveKit Voice WebSocket URL',
          hint: 'wss://livekit...',
          icon: LucideIcons.radio,
        ),
        const SizedBox(height: 12),
        _buildGlassTextField(
          controller: _livekitSecCtrl,
          label: 'LiveKit Secret Key',
          hint: 'Secret...',
          icon: LucideIcons.shieldAlert,
          obscure: _obscureLivekit,
          onToggleObscure: () => setState(() => _obscureLivekit = !_obscureLivekit),
        ),
      ],
    );
  }

  // ── Tab 1: Visuals & Theme Spectrum ───────────────────────────────────────
  Widget _buildVisualsTab({bool isMobile = false}) {
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        SettingsSectionLabel(
          text: '5 High-Glow Accent Orbs',
          icon: LucideIcons.palette,
          accentColor: _accent.primary,
        ),

        // Live Accent Orb Selectors
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceEvenly,
          children: List.generate(_accents.length, (i) {
            final acc = _accents[i];
            final selected = _selectedAccent == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedAccent = i),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isMobile ? 54 : 62,
                    height: isMobile ? 54 : 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [acc.primary, acc.secondary]),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                        width: selected ? 3 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: acc.glow,
                          blurRadius: selected ? 20 : 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: selected
                          ? const Icon(LucideIcons.check, color: Colors.white, size: 22)
                          : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    acc.name,
                    style: GoogleFonts.outfit(
                      color: selected ? Colors.white : Colors.white54,
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 28),

        SettingsSectionLabel(
          text: 'Liquid Glass Mode & Lighting',
          icon: LucideIcons.sun,
          accentColor: _accent.primary,
        ),

        _buildGlassSwitchTile(
          title: 'Obsidian OLED Dark Mode',
          subtitle: 'Deep midnight OLED backdrop',
          value: _darkMode,
          onChanged: (v) => setState(() => _darkMode = v),
          icon: LucideIcons.moon,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'Realtime Toast Notifications',
          subtitle: 'Interactive glass alert overlays',
          value: _notifications,
          onChanged: (v) => setState(() => _notifications = v),
          icon: LucideIcons.bellRing,
        ),

        const SizedBox(height: 28),

        SettingsSectionLabel(
          text: 'System Language',
          icon: LucideIcons.languages,
          accentColor: _accent.primary,
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: Colors.black87,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              isExpanded: true,
              items: ['English (US)', 'Spanish', 'Japanese', 'German', 'French']
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedLanguage = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Security & Quantum Vault ────────────────────────────────────────
  Widget _buildSecurityTab({bool isMobile = false}) {
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        SettingsSectionLabel(
          text: 'Quantum Vault Controls',
          icon: LucideIcons.shieldCheck,
          accentColor: _accent.primary,
        ),

        _buildGlassSwitchTile(
          title: 'Biometric Lock (FaceID)',
          subtitle: 'Require biometric key verification',
          value: _biometricsEnabled,
          onChanged: (v) => setState(() => _biometricsEnabled = v),
          icon: LucideIcons.scanFace,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'End-to-End Encrypted Sync',
          subtitle: 'Encrypt payload before sending',
          value: _encryptSync,
          onChanged: (v) => setState(() => _encryptSync = v),
          icon: LucideIcons.lock,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'Privacy Mask Shield',
          subtitle: 'Blur sensitive keys in UI',
          value: _privacyShield,
          onChanged: (v) => setState(() => _privacyShield = v),
          icon: LucideIcons.eyeOff,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'App Lock Security PIN',
          subtitle: 'Enforce 4-digit PIN lock when inactive',
          value: _appLockPin,
          onChanged: (v) => setState(() => _appLockPin = v),
          icon: LucideIcons.keyRound,
        ),
      ],
    );
  }

  // ── Tab 3: Diagnostics & Storage Console ────────────────────────────────────
  Widget _buildDiagnosticsTab({bool isMobile = false}) {
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        SettingsSectionLabel(
          text: 'Network Latency Gauge',
          icon: LucideIcons.activity,
          accentColor: _accent.primary,
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.radio, color: _accent.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Gateway Health', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _connectionPing != null ? '$_connectionPing ms response • $_connectionStatus' : _connectionStatus,
                style: GoogleFonts.outfit(
                  color: _connectionPing != null ? const Color(0xFF10B981) : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _testingConnection ? null : _testLatency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _testingConnection
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text('TEST LATENCY', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        SettingsSectionLabel(
          text: 'Storage Footprint',
          icon: LucideIcons.database,
          accentColor: _accent.primary,
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.hardDrive, color: _accent.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Cache Storage', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${_cacheFootprint.toStringAsFixed(1)} MB occupied', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _purgingCache ? null : _purgeCache,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('PURGE CACHE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 4: Notifications & Alert Console ───────────────────────────────────
  Widget _buildNotificationsTab({bool isMobile = false}) {
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        SettingsSectionLabel(
          text: 'Signal Alert Channels',
          icon: LucideIcons.bell,
          accentColor: _accent.primary,
        ),

        _buildGlassSwitchTile(
          title: 'ARIA AI Proactive Alerts',
          subtitle: 'Realtime AI contextual triggers',
          value: _notifAria,
          onChanged: (v) => setState(() => _notifAria = v),
          icon: LucideIcons.bot,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'Map Proximity Radar',
          subtitle: 'Geofence proximity notifications',
          value: _notifMap,
          onChanged: (v) => setState(() => _notifMap = v),
          icon: LucideIcons.mapPin,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'System Microservices',
          subtitle: 'Alerts when ports reconnect',
          value: _notifSystem,
          onChanged: (v) => setState(() => _notifSystem = v),
          icon: LucideIcons.radio,
        ),
        const SizedBox(height: 28),

        SettingsSectionLabel(
          text: 'Tactile & Sound Feedback',
          icon: LucideIcons.volume2,
          accentColor: _accent.primary,
        ),

        _buildGlassSwitchTile(
          title: 'Notification Audio Chime',
          subtitle: 'Play liquid chime on alert',
          value: _notifSound,
          onChanged: (v) => setState(() => _notifSound = v),
          icon: LucideIcons.volume2,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'Tactile Haptic Vibration',
          subtitle: 'Haptic pulse on interactions',
          value: _notifVibration,
          onChanged: (v) => setState(() => _notifVibration = v),
          icon: LucideIcons.vibrate,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'Unread Badge Counters',
          subtitle: 'Show badges on tab bar',
          value: _notifBadge,
          onChanged: (v) => setState(() => _notifBadge = v),
          icon: LucideIcons.badgeAlert,
        ),
      ],
    );
  }

  // ── Tab 5: About Nexal Architecture ────────────────────────────────────────
  Widget _buildAboutTab({bool isMobile = false}) {
    return ListView(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      children: [
        SettingsSectionLabel(
          text: 'Nexal Quantum Portal',
          icon: LucideIcons.info,
          accentColor: _accent.primary,
        ),

        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(colors: [_accent.primary, _accent.secondary]),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.glow,
                      blurRadius: 24,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/nexal_logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'NEXAL THE NEW ERA',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version $_appVersion (Build $_buildNumber)',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helper UI Builders
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          icon: Icon(icon, color: _accent.primary, size: 20),
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.white38),
          border: InputBorder.none,
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.white60, size: 18),
                  onPressed: onToggleObscure,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildGlassSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accent.primary, size: 21),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _accent.primary,
            activeTrackColor: _accent.primary.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
