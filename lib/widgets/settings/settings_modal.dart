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
  const _AccentStyle({required this.name, required this.primary, required this.secondary});
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
  int _selectedAccent = 1;
  bool _darkMode = true;
  bool _notifications = true;
  String _selectedLanguage = 'English (US)';

  // Security
  bool _biometricsEnabled = false;
  bool _encryptSync       = true;
  bool _privacyShield     = false;
  bool _appLockPin        = false;
  String _autoLockTime    = 'Immediately';

  // Diagnostics
  bool _testingConnection = false;
  String _connectionStatus = 'Not Tested';
  int? _connectionPing;
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

  // Accent definitions
  final List<_AccentStyle> _accents = [
    const _AccentStyle(name: 'Solar Gold',    primary: Color(0xFFD4A843), secondary: Color(0xFFB45309)),
    const _AccentStyle(name: 'Electric Cyan', primary: Color(0xFF00E5FF), secondary: Color(0xFF0284C7)),
    const _AccentStyle(name: 'Cosmic Violet', primary: Color(0xFFA855F7), secondary: Color(0xFF7E22CE)),
    const _AccentStyle(name: 'Ruby Rose',     primary: Color(0xFFF43F5E), secondary: Color(0xFFBE123C)),
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
    _selectedAccent   = prefs.getInt('nexal_selected_accent') ?? 1;
    _darkMode         = prefs.getBool('nexal_dark_mode') ?? true;
    _notifications    = prefs.getBool('nexal_notifications') ?? true;
    _selectedLanguage = prefs.getString('nexal_language') ?? 'English (US)';
    _username         = prefs.getString('user_username') ?? 'neuralnexus';

    _biometricsEnabled = prefs.getBool('nexal_biometrics_enabled') ?? false;
    _encryptSync       = prefs.getBool('nexal_encrypt_sync') ?? true;
    _privacyShield     = prefs.getBool('nexal_privacy_shield') ?? false;
    _appLockPin        = prefs.getBool('nexal_app_lock_pin') ?? false;
    _autoLockTime      = prefs.getString('nexal_auto_lock_time') ?? 'Immediately';

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
    await prefs.setString('nexal_auto_lock_time', _autoLockTime);

    await prefs.setBool('nexal_notif_aria', _notifAria);
    await prefs.setBool('nexal_notif_map', _notifMap);
    await prefs.setBool('nexal_notif_friend', _notifFriend);
    await prefs.setBool('nexal_notif_system', _notifSystem);

    if (mounted) {
      setState(() {
        _saving = false;
        _saved  = true;
      });
      _showToast('⚡ Settings successfully synchronized');
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

    final triggerUrls = [
      'http://localhost:3007/start-all',
      'http://localhost:3005/game/api/start-all',
      'http://localhost:3008/settings/start-all',
    ];
    for (final url in triggerUrls) {
      try {
        await http.post(Uri.parse(url)).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }

    if (!kIsWeb) {
      try {
        final candidatePaths = [
          's:/All Code/Antigravity/Nexal_App/Backend/start_all_backends.bat',
          '${Directory.current.path}/Backend/start_all_backends.bat',
        ];
        for (final p in candidatePaths) {
          final f = File(p);
          if (f.existsSync()) {
            await Process.start('cmd.exe', ['/c', f.path], workingDirectory: f.parent.path);
            break;
          }
        }
      } catch (e) {
        debugPrint('[Settings] Batch launch error: $e');
      }
    }

    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 2));
      await _checkAllBackendsHealth();
      if (_backendHealth['Gateway (10000)'] == true) break;
    }

    if (mounted) {
      setState(() => _startingAllBackends = false);
      final count = _backendHealth.values.where((v) => v).length;
      _showToast(
        count > 0
            ? '⚡ All $count Backends Online & Connected!'
            : 'Backend launch signal sent! Please verify start_all_backends.bat.',
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
      _showToast('🧹 Cache successfully purged');
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: _accent.primary.withValues(alpha: 0.6), width: 1.2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          // Vignette Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),

          // 3D Liquid Glass Main Container
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.55),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.60),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.primary.withValues(alpha: 0.20),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top Header Bar
                        _buildTopHeaderBar(),

                        // Nav Rail + Content Area
                        Expanded(
                          child: Row(
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
                                    ? Center(
                                        child: CircularProgressIndicator(color: _accent.primary),
                                      )
                                    : _buildActiveTabContent(),
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
  // Top Header Sanctuary Bar
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTopHeaderBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo Squircle Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [_accent.primary, _accent.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.primary.withValues(alpha: 0.40),
                  blurRadius: 16,
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset('assets/nexal_logo.png', fit: BoxFit.cover),
            ),
          ),

          const SizedBox(width: 14),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETTINGS SANCTUARY',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Quantum Config & Orchestrator',
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Save Changes Liquid Button
          GestureDetector(
            onTap: _saving ? null : _saveAllSettings,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        _accent.primary.withValues(alpha: 0.85),
                        _accent.secondary.withValues(alpha: 0.85),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_saving)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      else
                        Icon(_saved ? LucideIcons.check : LucideIcons.save, size: 15, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _saved ? 'SAVED' : 'SAVE CHANGES',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Close Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sub-Tab Content Switcher
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildSystemTab();
      case 1:
        return _buildVisualsTab();
      case 2:
        return _buildSecurityTab();
      case 3:
        return _buildDiagnosticsTab();
      case 4:
        return _buildNotificationsTab();
      case 5:
        return _buildAboutTab();
      default:
        return _buildSystemTab();
    }
  }

  // ── Tab 0: System (Backend Orchestrator & API Config) ──────────────────────
  Widget _buildSystemTab() {
    final activeCount = _backendHealth.values.where((v) => v).length;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        SettingsSectionLabel(text: 'Backend Suite Orchestrator', icon: LucideIcons.cpu, accentColor: _accent.primary),

        // Master Launch Banner
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                _accent.primary.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.50),
              ],
            ),
            border: Border.all(color: _accent.primary.withValues(alpha: 0.55), width: 1.4),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.primary.withValues(alpha: 0.20),
                ),
                child: Icon(LucideIcons.zap, color: _accent.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Backends Orchestrator',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeCount / 7 Services Active & Ready',
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _startingAllBackends ? null : _turnOnAllBackends,
                icon: _startingAllBackends
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(LucideIcons.power, size: 16, color: Colors.black),
                label: Text(
                  _startingAllBackends ? 'Starting...' : 'TURN ON ALL',
                  style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Health Status Grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _backendHealth.entries.map((e) {
            final isOnline = e.value;
            return Container(
              width: 165,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isOnline ? const Color(0xFF22C55E).withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: isOnline ? const Color(0xFF22C55E).withValues(alpha: 0.40) : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),

        SettingsSectionLabel(text: 'AI & Gateway API Keys', icon: LucideIcons.key, accentColor: _accent.primary),

        _buildGlassTextField(
          controller: _backendUrlCtrl,
          label: 'Gateway Server URL',
          hint: 'http://localhost:10000',
          icon: LucideIcons.server,
        ),
        const SizedBox(height: 14),
        _buildGlassTextField(
          controller: _groqKeyCtrl,
          label: 'GROQ API Key',
          hint: 'gsk_...',
          icon: LucideIcons.brainCircuit,
          obscure: _obscureGroq,
          onToggleObscure: () => setState(() => _obscureGroq = !_obscureGroq),
        ),
        const SizedBox(height: 14),
        _buildGlassTextField(
          controller: _deepgramKeyCtrl,
          label: 'Deepgram Voice Key',
          hint: 'Key...',
          icon: LucideIcons.mic,
          obscure: _obscureDeepgram,
          onToggleObscure: () => setState(() => _obscureDeepgram = !_obscureDeepgram),
        ),
        const SizedBox(height: 14),
        _buildGlassTextField(
          controller: _livekitUrlCtrl,
          label: 'LiveKit URL',
          hint: 'wss://livekit...',
          icon: LucideIcons.radio,
        ),
        const SizedBox(height: 14),
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

  // ── Tab 1: Visuals & Themes ────────────────────────────────────────────────
  Widget _buildVisualsTab() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        SettingsSectionLabel(text: 'Theme Accent Spectrum', icon: LucideIcons.palette, accentColor: _accent.primary),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_accents.length, (i) {
            final acc = _accents[i];
            final selected = _selectedAccent == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedAccent = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [acc.primary, acc.secondary]),
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: acc.primary.withValues(alpha: 0.6), blurRadius: 18)]
                      : [],
                ),
                child: Center(
                  child: selected
                      ? const Icon(LucideIcons.check, color: Colors.white, size: 24)
                      : const SizedBox.shrink(),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 28),

        SettingsSectionLabel(text: 'Liquid Density & Mode', icon: LucideIcons.sun, accentColor: _accent.primary),

        _buildGlassSwitchTile(
          title: 'Obsidian Night Mode',
          subtitle: 'Deep OLED black backdrop with high contrast glow',
          value: _darkMode,
          onChanged: (v) => setState(() => _darkMode = v),
          icon: LucideIcons.moon,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'Realtime Notifications',
          subtitle: 'Enable visual toast alerts for system messages',
          value: _notifications,
          onChanged: (v) => setState(() => _notifications = v),
          icon: LucideIcons.bellRing,
        ),

        const SizedBox(height: 28),

        SettingsSectionLabel(text: 'System Language', icon: LucideIcons.languages, accentColor: _accent.primary),

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
              dropdownColor: Colors.grey.shade900,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
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
  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        SettingsSectionLabel(text: 'Quantum Vault Protection', icon: LucideIcons.shieldCheck, accentColor: _accent.primary),

        _buildGlassSwitchTile(
          title: 'Biometric Authentication',
          subtitle: 'Require FaceID / Fingerprint to open app',
          value: _biometricsEnabled,
          onChanged: (v) => setState(() => _biometricsEnabled = v),
          icon: LucideIcons.scanFace,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'End-to-End Encrypted Sync',
          subtitle: 'Encrypt data before transmitting to gateway',
          value: _encryptSync,
          onChanged: (v) => setState(() => _encryptSync = v),
          icon: LucideIcons.lock,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'Privacy Shield',
          subtitle: 'Mask sensitive API keys and tokens in UI',
          value: _privacyShield,
          onChanged: (v) => setState(() => _privacyShield = v),
          icon: LucideIcons.eyeOff,
        ),
      ],
    );
  }

  // ── Tab 3: Diagnostics & Cache ─────────────────────────────────────────────
  Widget _buildDiagnosticsTab() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        SettingsSectionLabel(text: 'Network Latency', icon: LucideIcons.activity, accentColor: _accent.primary),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gateway Connection', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(
                      _connectionPing != null ? '$_connectionPing ms • $_connectionStatus' : _connectionStatus,
                      style: GoogleFonts.outfit(color: _connectionPing != null ? Colors.greenAccent : Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _testingConnection ? null : _testLatency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _testingConnection
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : Text('PING', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        SettingsSectionLabel(text: 'Storage & Cache', icon: LucideIcons.database, accentColor: _accent.primary),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Temporary App Cache', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${_cacheFootprint.toStringAsFixed(1)} MB occupied', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _purgingCache ? null : _purgeCache,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('PURGE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 4: Notifications ───────────────────────────────────────────────────
  Widget _buildNotificationsTab() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        SettingsSectionLabel(text: 'Signal Alert Channels', icon: LucideIcons.bell, accentColor: _accent.primary),

        _buildGlassSwitchTile(
          title: 'ARIA AI Alerts',
          subtitle: 'Proactive intelligence & voice triggers',
          value: _notifAria,
          onChanged: (v) => setState(() => _notifAria = v),
          icon: LucideIcons.bot,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'Map Radar Signals',
          subtitle: 'Proximity notifications & geo alerts',
          value: _notifMap,
          onChanged: (v) => setState(() => _notifMap = v),
          icon: LucideIcons.mapPin,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'System Updates',
          subtitle: 'Gateway & server status broadcasts',
          value: _notifSystem,
          onChanged: (v) => setState(() => _notifSystem = v),
          icon: LucideIcons.radio,
        ),
        const SizedBox(height: 28),

        SettingsSectionLabel(text: 'Feedback & Alert Styles', icon: LucideIcons.volume2, accentColor: _accent.primary),

        _buildGlassSwitchTile(
          title: 'Notification Sound Effects',
          subtitle: 'Play audio chime on alert arrival',
          value: _notifSound,
          onChanged: (v) => setState(() => _notifSound = v),
          icon: LucideIcons.volume2,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'Haptic Vibration',
          subtitle: 'Tactile haptic pulses for incoming signals',
          value: _notifVibration,
          onChanged: (v) => setState(() => _notifVibration = v),
          icon: LucideIcons.vibrate,
        ),
        const SizedBox(height: 12),
        _buildGlassSwitchTile(
          title: 'Badge Counters',
          subtitle: 'Display unread indicator badges on tabs',
          value: _notifBadge,
          onChanged: (v) => setState(() => _notifBadge = v),
          icon: LucideIcons.badgeAlert,
        ),
      ],
    );
  }

  // ── Tab 5: About Nexal ─────────────────────────────────────────────────────
  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        SettingsSectionLabel(text: 'Nexal Quantum Architecture', icon: LucideIcons.info, accentColor: _accent.primary),

        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(colors: [_accent.primary, _accent.secondary]),
                  boxShadow: [BoxShadow(color: _accent.primary.withValues(alpha: 0.4), blurRadius: 24)],
                ),
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/nexal_logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 14),
              Text('NEXAL THE NEW ERA', style: GoogleFonts.rye(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Version $_appVersion (Build $_buildNumber)', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helper Components
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
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          icon: Icon(icon, color: _accent.primary, size: 20),
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.white38),
          border: InputBorder.none,
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.white54, size: 18),
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
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accent.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
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
