import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

// Opens Settings as a full-screen page
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
      transitionDuration: const Duration(milliseconds: 280),
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

  Future<void> _checkAllBackendsHealth() async {
    final targets = {
      'Gateway (10000)': 'http://localhost:10000/health',
      'ARIA AI (3003)': 'http://localhost:3003/health',
      'Search (3004)': 'http://localhost:3004/health',
      'Game (3005)': 'http://localhost:3005/health',
      'Map (3006)': 'http://localhost:3006/map/health',
      'Camera (3007)': 'http://localhost:3007/health',
      'Settings (3008)': 'http://localhost:3008/health',
    };

    final Map<String, bool> updated = {};

    // 1. Try single Gateway health check first
    for (final gwUrl in ['http://localhost:10000/health', 'http://127.0.0.1:10000/health']) {
      try {
        final res = await http.get(Uri.parse(gwUrl)).timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['status'] == 'online') {
            for (final k in targets.keys) {
              updated[k] = true;
            }
            if (mounted) setState(() => _backendHealth = updated);
            return;
          }
        }
      } catch (_) {}
    }

    // 2. Direct checks per port (trying both localhost and 127.0.0.1)
    for (final entry in targets.entries) {
      bool ok = false;
      final urls = [
        entry.value,
        entry.value.replaceAll('localhost', '127.0.0.1'),
      ];
      for (final u in urls) {
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

    // Send HTTP trigger to all potential listening server ports
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

    // On native desktop platform launch batch file
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

    // Poll up to 10 seconds for backends to report online
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 2));
      await _checkAllBackendsHealth();
      if (_backendHealth['Gateway (10000)'] == true) {
        break;
      }
    }

    if (mounted) {
      setState(() => _startingAllBackends = false);
      final count = _backendHealth.values.where((v) => v).length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          count > 0
              ? '⚡ All $count Backends Online & Connected!'
              : 'Backend launch signal sent! Please run start_all_backends.bat if launching locally.',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        backgroundColor: count > 0 ? _accent.primary : Colors.amber.shade800,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // Navigation
  int _activeTab = 0;

  // Visuals
  int _selectedAccent = 1;
  bool _darkMode = true;
  bool _notifications = true;
  String _selectedLanguage = 'English (US)';

  // Security
  bool _biometricsEnabled = false;
  bool _encryptSync = true;
  bool _privacyShield = false;
  bool _appLockPin = false;
  String _autoLockTime = 'Immediately';
  bool _clearingActivityLogs = false;

  // Diagnostics
  bool _testingConnection = false;
  String _connectionStatus = 'Not Tested';
  int? _connectionPing;
  double _cacheFootprint = 18.4;
  bool _purgingCache = false;

  // Notifications
  bool _notifAria = true;
  bool _notifMap = true;
  bool _notifFriend = true;
  bool _notifSystem = true;
  bool _notifSound = true;
  bool _notifVibration = true;
  bool _notifBadge = true;
  bool _notifDoNotDisturb = false;
  String _notifStyle = 'Banner';
  String _notifFrequency = 'Real-time';

  // About
  static const String _appVersion = '2.4.1';
  static const String _buildNumber = '20260711';
  static const String _releaseChannel = 'Beta';

  // Username for avatar
  String _username = 'neuralnexus';

  // Accent definitions
  final List<_AccentStyle> _accents = [
    _AccentStyle(name: 'Solar Gold',    primary: const Color(0xFFD4A843), secondary: const Color(0xFFB45309)),
    _AccentStyle(name: 'Electric Cyan', primary: const Color(0xFF22D3EE), secondary: const Color(0xFF0EA5E9)),
    _AccentStyle(name: 'Cosmic Violet', primary: const Color(0xFFC084FC), secondary: const Color(0xFF7E22CE)),
    _AccentStyle(name: 'Ruby Rose',     primary: const Color(0xFFF43F5E), secondary: const Color(0xFFBE123C)),
  ];

  _AccentStyle get _accent => _accents[_selectedAccent];

  @override
  void initState() {
    super.initState();
    _loadConfig();
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
    _notifDoNotDisturb = prefs.getBool('nexal_notif_dnd') ?? false;
    _notifStyle        = prefs.getString('nexal_notif_style') ?? 'Banner';
    _notifFrequency    = prefs.getString('nexal_notif_frequency') ?? 'Real-time';

    if (mounted) setState(() => _loading = false);

    // Remote sync
    try {
      final syncUri = Uri.parse('${config.backendUrl}/settings');
      final response = await http.get(syncUri).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _backendUrlCtrl.text  = data['backendUrl']       ?? config.backendUrl;
        _groqKeyCtrl.text     = data['groqApiKey']       ?? config.groqApiKey;
        _deepgramKeyCtrl.text = data['deepgramApiKey']   ?? config.deepgramApiKey;
        _livekitUrlCtrl.text  = data['livekitUrl']       ?? config.livekitUrl;
        _livekitKeyCtrl.text  = data['livekitApiKey']    ?? config.livekitApiKey;
        _livekitSecCtrl.text  = data['livekitApiSecret'] ?? config.livekitApiSecret;
        _selectedAccent       = data['selectedAccent']   ?? _selectedAccent;
        _darkMode             = data['darkMode']         ?? _darkMode;
        _notifications        = data['notifications']    ?? _notifications;
        _selectedLanguage     = data['selectedLanguage'] ?? _selectedLanguage;
        if (mounted) setState(() {});
      }
    } catch (_) {
      debugPrint('[Settings] Offline fallback');
    }
  }

  Future<void> _saveConfig() async {
    if (_saving) return;
    setState(() => _saving = true);

    final config = await AriaConfig.load();
    config.backendUrl       = _backendUrlCtrl.text.trim();
    config.groqApiKey       = _groqKeyCtrl.text.trim();
    config.deepgramApiKey   = _deepgramKeyCtrl.text.trim();
    config.livekitUrl       = _livekitUrlCtrl.text.trim();
    config.livekitApiKey    = _livekitKeyCtrl.text.trim();
    config.livekitApiSecret = _livekitSecCtrl.text.trim();
    await config.save();
    await AriaService.instance.pushConfigToBackend();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nexal_selected_accent',    _selectedAccent);
    await prefs.setBool('nexal_dark_mode',         _darkMode);
    await prefs.setBool('nexal_notifications',     _notifications);
    await prefs.setString('nexal_language',        _selectedLanguage);
    await prefs.setBool('nexal_biometrics_enabled', _biometricsEnabled);
    await prefs.setBool('nexal_encrypt_sync',      _encryptSync);
    await prefs.setBool('nexal_privacy_shield',    _privacyShield);
    await prefs.setBool('nexal_app_lock_pin',      _appLockPin);
    await prefs.setString('nexal_auto_lock_time',  _autoLockTime);
    await prefs.setBool('nexal_notif_aria',        _notifAria);
    await prefs.setBool('nexal_notif_map',         _notifMap);
    await prefs.setBool('nexal_notif_friend',      _notifFriend);
    await prefs.setBool('nexal_notif_system',      _notifSystem);
    await prefs.setBool('nexal_notif_sound',       _notifSound);
    await prefs.setBool('nexal_notif_vibration',   _notifVibration);
    await prefs.setBool('nexal_notif_badge',       _notifBadge);
    await prefs.setBool('nexal_notif_dnd',         _notifDoNotDisturb);
    await prefs.setString('nexal_notif_style',     _notifStyle);
    await prefs.setString('nexal_notif_frequency', _notifFrequency);

    try {
      await http.post(
        Uri.parse('${config.backendUrl}/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'backendUrl': config.backendUrl,
          'groqApiKey': config.groqApiKey,
          'deepgramApiKey': config.deepgramApiKey,
          'livekitUrl': config.livekitUrl,
          'livekitApiKey': config.livekitApiKey,
          'livekitApiSecret': config.livekitApiSecret,
          'selectedAccent': _selectedAccent,
          'darkMode': _darkMode,
          'notifications': _notifications,
          'selectedLanguage': _selectedLanguage,
          'biometricsEnabled': _biometricsEnabled,
          'encryptSync': _encryptSync,
          'privacyShield': _privacyShield,
          'appLockPin': _appLockPin,
          'autoLockTime': _autoLockTime,
          'notifAria': _notifAria,
          'notifMap': _notifMap,
          'notifFriend': _notifFriend,
          'notifSystem': _notifSystem,
          'notifSound': _notifSound,
          'notifVibration': _notifVibration,
          'notifBadge': _notifBadge,
          'notifDoNotDisturb': _notifDoNotDisturb,
          'notifStyle': _notifStyle,
          'notifFrequency': _notifFrequency,
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      debugPrint('[Settings] Remote sync failed');
    }

    if (mounted) {
      setState(() { _saving = false; _saved = true; });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    }
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

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Log Out',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your Nexal account?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(
                      color: _accent.primary, strokeWidth: 2.5))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left vertical nav rail
                        SettingsNavRail(
                          selectedIndex: _activeTab,
                          accentColor: _accent.primary,
                          username: _username,
                          onDestinationSelected: (i) =>
                              setState(() => _activeTab = i),
                          onLogoutTap: _confirmLogout,
                        ),
                        // Right content
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween(
                                  begin: const Offset(0.03, 0),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: ValueKey(_activeTab),
                              child: _buildTabContent(_activeTab),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            if (!_loading) _buildSaveBar(),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final tabLabels = [
      'System', 'Visuals', 'Security', 'Diagnostics', 'Notifications', 'About'
    ];
    final tabIcons = [
      LucideIcons.cpu, LucideIcons.palette, LucideIcons.shieldCheck,
      LucideIcons.activity, LucideIcons.bell, LucideIcons.info,
    ];
    final currentLabel = tabLabels[_activeTab];
    final currentIcon  = tabIcons[_activeTab];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080C18),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Back · Title · Version chip ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 20, 10),
            child: Row(
              children: [
                // Back button — minimal pill style
                Material(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.arrowLeft,
                              color: Colors.white70, size: 16),
                          SizedBox(width: 5),
                          Text('Back',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nexal App Configuration',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.33),
                          fontSize: 11.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Logout chip
                GestureDetector(
                  onTap: _confirmLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.logOut, color: Colors.redAccent, size: 12),
                        SizedBox(width: 5),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Version chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accent.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _accent.primary.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accent.primary,
                          boxShadow: [BoxShadow(
                            color: _accent.primary.withValues(alpha: 0.6),
                            blurRadius: 4,
                          )],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'v2.4.1',
                        style: TextStyle(
                          color: _accent.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Row 2: Active tab breadcrumb ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              children: [
                // Glowing left-border tab badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: _accent.primary, width: 3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(currentIcon,
                          size: 14, color: _accent.primary),
                      const SizedBox(width: 7),
                      Text(
                        currentLabel,
                        style: TextStyle(
                          color: _accent.primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Divider line growing to accent gradient
                Expanded(
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _accent.primary.withValues(alpha: 0.4),
                          Colors.transparent,
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

  // ─── TAB ROUTER ─────────────────────────────────────────────────────────────
  Widget _buildTabContent(int tab) {
    return switch (tab) {
      0 => _buildSystemTab(),
      1 => _buildVisualsTab(),
      2 => _buildSecurityTab(),
      3 => _buildDiagnosticsTab(),
      4 => _buildNotificationsTab(),
      5 => _buildAboutTab(),
      _ => const SizedBox(),
    };
  }

  // ─── SHARED HELPERS ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, IconData icon) => SettingsSectionLabel(
    text: text, icon: icon, accentColor: _accent.primary,
  );

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SettingsTile(
        icon: icon, title: title, description: desc,
        accentColor: _accent.primary,
        trailing: Switch.adaptive(
          value: value,
          activeThumbColor: _accent.primary,
          activeTrackColor: _accent.primary.withValues(alpha: 0.25),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dropdownTile({
    required IconData icon,
    required String title,
    required String desc,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SettingsTile(
        icon: icon, title: title, description: desc,
        accentColor: _accent.primary,
        trailing: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF161622),
          icon: const Icon(LucideIcons.chevronDown,
              color: Colors.white38, size: 15),
          underline: const SizedBox(),
          style: TextStyle(
            color: _accent.primary, fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          onChanged: onChanged,
          items: items.map((v) =>
              DropdownMenuItem(value: v, child: Text(v))).toList(),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    required String hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                color: _accent.primary.withValues(alpha: 0.7), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    cursorColor: _accent.primary,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 4),
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onToggleObscure != null)
              GestureDetector(
                onTap: onToggleObscure,
                child: Icon(
                  obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: Colors.white38, size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllBackendsCard() {
    final onlineCount = _backendHealth.values.where((v) => v).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.primary.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _accent.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _accent.primary.withValues(alpha: 0.4)),
                ),
                child: Icon(LucideIcons.server, color: _accent.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNIFIED BACKEND SUITE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'ARIA AI · Search · Game · Map · Camera · Settings',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (onlineCount > 0 ? Colors.greenAccent : Colors.amber).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (onlineCount > 0 ? Colors.greenAccent : Colors.amber).withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$onlineCount / 7 ONLINE',
                  style: GoogleFonts.shareTechMono(
                    color: onlineCount > 0 ? Colors.greenAccent : Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Microservices status grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _backendHealth.entries.map((e) {
              final isOnline = e.value;
              final color = isOnline ? Colors.greenAccent : Colors.redAccent.withValues(alpha: 0.7);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: isOnline ? [BoxShadow(color: color, blurRadius: 4)] : [],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      e.key,
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // Big "TURN ON ALL BACKENDS" CTA Button
          GestureDetector(
            onTap: _startingAllBackends ? null : _turnOnAllBackends,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accent.primary,
                    _accent.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _accent.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _startingAllBackends
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(LucideIcons.power, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _startingAllBackends ? 'TURNING ON ALL SERVICES...' : '⚡ TURN ON ALL BACKENDS',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 0: SYSTEM ──────────────────────────────────────────────────────────
  Widget _buildSystemTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 44),
      children: [
        _buildAllBackendsCard(),
        const SizedBox(height: 12),
        _sectionLabel('ENVIRONMENT', LucideIcons.layers),
        Row(
          children: [
            Expanded(child: _presetCard(
              label: 'Render Prod', icon: LucideIcons.cloud,
              desc: 'Remote Server',
              active: _backendUrlCtrl.text.contains('onrender.com'),
              onTap: () => _applyEnv('render'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _presetCard(
              label: 'Local Debug', icon: LucideIcons.laptop,
              desc: '10.0.2.2',
              active: _backendUrlCtrl.text.contains('10.0.2.2'),
              onTap: () => _applyEnv('local'),
            )),
          ],
        ),
        const SizedBox(height: 28),
        _sectionLabel('SERVER ENGINE', LucideIcons.server),
        _inputField(label: 'Core API Endpoint',
            controller: _backendUrlCtrl,
            icon: LucideIcons.link, hint: 'https://your-api.com'),
        const SizedBox(height: 16),
        _sectionLabel('AI KEYS', LucideIcons.brain),
        _inputField(label: 'Groq LLM Key',
            controller: _groqKeyCtrl,
            icon: LucideIcons.key, obscure: _obscureGroq,
            onToggleObscure: () =>
                setState(() => _obscureGroq = !_obscureGroq),
            hint: 'gsk_...'),
        _inputField(label: 'Deepgram Voice Key',
            controller: _deepgramKeyCtrl,
            icon: LucideIcons.mic, obscure: _obscureDeepgram,
            onToggleObscure: () =>
                setState(() => _obscureDeepgram = !_obscureDeepgram),
            hint: '49a1...'),
        const SizedBox(height: 16),
        _sectionLabel('LIVEKIT', LucideIcons.radio),
        _inputField(label: 'Agent Gateway',
            controller: _livekitUrlCtrl,
            icon: LucideIcons.globe, hint: 'wss://...'),
        _inputField(label: 'API Key',
            controller: _livekitKeyCtrl,
            icon: LucideIcons.shieldAlert, obscure: _obscureLivekit,
            onToggleObscure: () =>
                setState(() => _obscureLivekit = !_obscureLivekit),
            hint: 'API...'),
        _inputField(label: 'API Secret',
            controller: _livekitSecCtrl,
            icon: LucideIcons.lock, obscure: _obscureLivekit,
            hint: 'xH4L...'),
      ],
    );
  }

  Widget _presetCard({
    required String label, required IconData icon,
    required String desc, required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: active
              ? _accent.primary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? _accent.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: active ? _accent.primary : Colors.white38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                    color: Colors.white, fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                  )),
                  Text(desc, style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyEnv(String env) {
    if (env == 'render') {
      _backendUrlCtrl.text = 'https://nexal-backend.onrender.com';
      _livekitUrlCtrl.text = 'wss://friday-si6nqz7u.livekit.cloud';
      _livekitKeyCtrl.text = 'API6vNUPttbHXDd';
      _livekitSecCtrl.text = 'xH4Ld1M8SQZ4XSXQTMYDmMttC8ii2i8nWO09adFSwHG';
    } else {
      _backendUrlCtrl.text = 'http://10.0.2.2:5000';
      _livekitUrlCtrl.text = 'ws://10.0.2.2:7880';
      _livekitKeyCtrl.text = 'devkey';
      _livekitSecCtrl.text = 'secret';
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Preset applied: ${env.toUpperCase()}',
          style: const TextStyle(fontSize: 13)),
      backgroundColor: const Color(0xFF1E293B),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ─── TAB 1: VISUALS ─────────────────────────────────────────────────────────
  Widget _buildVisualsTab() {
    final List<String> languages = [
      'English (US)', 'Spanish', 'German', 'Hindi', 'French'
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 44),
      children: [
        _sectionLabel('ACCENT COLOR', LucideIcons.palette),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nebula Glow', style: TextStyle(
                  color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              const Text('Choose your primary interface accent',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_accents.length, (i) {
                  final a = _accents[i];
                  final sel = _selectedAccent == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAccent = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? a.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? a.primary : Colors.white12,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                colors: [a.primary, a.secondary]),
                            boxShadow: sel ? [BoxShadow(
                              color: a.primary.withValues(alpha: 0.4),
                              blurRadius: 8)] : null,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(a.name.split(' ')[1], style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel
                              ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? Colors.white : Colors.white38,
                        )),
                      ]),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _sectionLabel('PREFERENCES', LucideIcons.sliders),
        _switchTile(icon: LucideIcons.moon, title: 'Dark Mode',
            desc: 'Saves battery on OLED displays',
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v)),
        _switchTile(icon: LucideIcons.bell, title: 'Notifications',
            desc: 'Push and acoustic feedback',
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v)),
        const SizedBox(height: 28),
        _sectionLabel('LANGUAGE', LucideIcons.globe),
        _dropdownTile(icon: LucideIcons.globe,
            title: 'Language', desc: 'Interface language',
            value: _selectedLanguage, items: languages,
            onChanged: (v) => setState(() => _selectedLanguage = v!)),
      ],
    );
  }

  // ─── TAB 2: SECURITY ────────────────────────────────────────────────────────
  Widget _buildSecurityTab() {
    final List<String> lockIntervals = [
      'Immediately', '1 Minute', '5 Minutes', 'Never'
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 44),
      children: [
        _sectionLabel('AUTHENTICATION', LucideIcons.fingerprint),
        _switchTile(icon: LucideIcons.fingerprint,
            title: 'Biometric Verification',
            desc: 'Fingerprint or FaceID unlock',
            value: _biometricsEnabled,
            onChanged: (v) => setState(() => _biometricsEnabled = v)),
        _switchTile(icon: LucideIcons.lock, title: 'Device PIN Lock',
            desc: 'Passcode required on launch',
            value: _appLockPin,
            onChanged: (v) => setState(() => _appLockPin = v)),
        _dropdownTile(icon: LucideIcons.clock,
            title: 'Auto-Lock Interval', desc: 'Inactivity timeout',
            value: _autoLockTime, items: lockIntervals,
            onChanged: (v) => setState(() => _autoLockTime = v!)),
        const SizedBox(height: 28),
        _sectionLabel('PRIVACY & SYNC', LucideIcons.shieldCheck),
        _switchTile(icon: LucideIcons.shieldAlert,
            title: 'End-to-End Encrypted Sync',
            desc: 'Secures data in transit',
            value: _encryptSync,
            onChanged: (v) => setState(() => _encryptSync = v)),
        _switchTile(icon: LucideIcons.eyeOff, title: 'Privacy Shield',
            desc: 'Blurs preview in app switcher',
            value: _privacyShield,
            onChanged: (v) => setState(() => _privacyShield = v)),
        const SizedBox(height: 28),
        _sectionLabel('DATA MANAGEMENT', LucideIcons.trash2),
        _dangerCard(
          icon: LucideIcons.history,
          title: 'Clear Activity & Location History',
          desc: 'Purges search queries, geolocation caches, and private logs permanently.',
          buttonLabel: _clearingActivityLogs ? 'Purging...' : 'Purge Logs',
          isLoading: _clearingActivityLogs,
          onTap: _clearingActivityLogs ? null : _clearLogs,
        ),
      ],
    );
  }

  Widget _dangerCard({
    required IconData icon, required String title,
    required String desc, required String buttonLabel,
    required bool isLoading, required VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(
              color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 6),
        Text(desc, style: const TextStyle(
            color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity, height: 38,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              foregroundColor: Colors.redAccent, elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.25)),
              ),
            ),
            onPressed: onTap,
            child: isLoading
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.redAccent))
                : Text(buttonLabel, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Future<void> _clearLogs() async {
    setState(() => _clearingActivityLogs = true);
    final config = await AriaConfig.load();
    try {
      await http.post(Uri.parse(
              '${config.backendUrl}/settings/clear-logs'))
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() => _clearingActivityLogs = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Activity history cleared',
            style: TextStyle(color: Colors.greenAccent, fontSize: 13)),
        backgroundColor: Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ─── TAB 3: DIAGNOSTICS ─────────────────────────────────────────────────────
  Widget _buildDiagnosticsTab() {
    Color statusColor;
    IconData statusIcon;
    if (_connectionStatus == 'Online') {
      statusColor = Colors.greenAccent;
      statusIcon = LucideIcons.checkCircle;
    } else if (_connectionStatus == 'Offline' ||
        _connectionStatus.contains('Error')) {
      statusColor = Colors.redAccent;
      statusIcon = LucideIcons.alertTriangle;
    } else if (_connectionStatus == 'Testing...') {
      statusColor = _accent.primary;
      statusIcon = LucideIcons.refreshCw;
    } else {
      statusColor = Colors.white38;
      statusIcon = LucideIcons.helpCircle;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 44),
      children: [
        _sectionLabel('CONNECTIVITY', LucideIcons.radio),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _testingConnection
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _accent.primary))
                    : Icon(statusIcon, color: statusColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Server Health', style: TextStyle(
                      color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w600)),
                  Text(_backendUrlCtrl.text.trim(), style: const TextStyle(
                      color: Colors.white30, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_connectionStatus, style: TextStyle(
                    color: statusColor, fontSize: 13,
                    fontWeight: FontWeight.bold)),
                if (_connectionPing != null && !_testingConnection)
                  Text('${_connectionPing}ms', style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent.primary.withValues(alpha: 0.1),
                  foregroundColor: _accent.primary, elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: _accent.primary.withValues(alpha: 0.3)),
                  ),
                ),
                onPressed: _testingConnection ? null : _testConn,
                child: Text(
                    _testingConnection ? 'Pinging...' : 'Run Test',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 28),
        _sectionLabel('CACHE', LucideIcons.hardDrive),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Map Tile Cache', style: TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w600)),
                Text('${_cacheFootprint.toStringAsFixed(1)} / 100 MB',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _cacheFootprint / 100,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                color: _accent.primary,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.redAccent.withValues(alpha: 0.08),
                  foregroundColor: _cacheFootprint == 0
                      ? Colors.white24
                      : Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.redAccent.withValues(
                        alpha: _cacheFootprint == 0 ? 0.05 : 0.2)),
                  ),
                ),
                onPressed: _cacheFootprint == 0 ? null : _purgeCache,
                child: Text(
                    _purgingCache
                        ? 'Purging...'
                        : _cacheFootprint == 0
                            ? 'Cache Empty'
                            : 'Purge Cache',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 28),
        _sectionLabel('HARDWARE', LucideIcons.smartphone),
        _hardwareCard(),
      ],
    );
  }

  Widget _hardwareCard() {
    final rows = [
      ('Renderer', 'Impeller (Vulkan)'),
      ('Location', 'High Accuracy GPS'),
      ('Architecture', 'AArch64 ARMv8-A'),
      ('WebGL Tiles', 'Active — Cap @ 20'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: rows.map((r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.$1, style: const TextStyle(
                  color: Colors.white38, fontSize: 12)),
              Text(r.$2, style: const TextStyle(
                  color: Colors.white70, fontSize: 12,
                  fontWeight: FontWeight.w500)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Future<void> _testConn() async {
    setState(() {
      _testingConnection = true;
      _connectionStatus = 'Testing...';
    });
    final sw = Stopwatch()..start();
    try {
      final r = await http.get(Uri.parse(_backendUrlCtrl.text.trim()))
          .timeout(const Duration(seconds: 4));
      sw.stop();
      if (mounted) { setState(() {
        _testingConnection = false;
        _connectionPing = sw.elapsedMilliseconds;
        _connectionStatus = r.statusCode < 500 ? 'Online' : 'Server Error';
      }); }
    } catch (_) {
      sw.stop();
      if (mounted) { setState(() {
        _testingConnection = false;
        _connectionPing = null;
        _connectionStatus = 'Offline';
      }); }
    }
  }

  Future<void> _purgeCache() async {
    if (_purgingCache || _cacheFootprint == 0) return;
    setState(() => _purgingCache = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() { _purgingCache = false; _cacheFootprint = 0; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cache cleared', style: TextStyle(
            color: Colors.greenAccent, fontSize: 13)),
        backgroundColor: Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ─── TAB 4: NOTIFICATIONS ───────────────────────────────────────────────────
  Widget _buildNotificationsTab() {
    final styles = ['Banner', 'Heads-Up', 'Silent'];
    final freqs  = ['Real-time', 'Batched (15 min)', 'Digest (Daily)'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 44),
      children: [
        // Master toggle card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _accent.primary.withValues(alpha: 0.12),
              _accent.secondary.withValues(alpha: 0.06),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _accent.primary.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accent.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.bell,
                  color: _accent.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All Notifications', style: TextStyle(
                    color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700)),
                Text(_notifications ? 'Active' : 'Silenced',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            )),
            Switch.adaptive(
              value: _notifications,
              activeThumbColor: _accent.primary,
              activeTrackColor: _accent.primary.withValues(alpha: 0.25),
              onChanged: (v) => setState(() => _notifications = v),
            ),
          ]),
        ),
        _sectionLabel('CHANNELS', LucideIcons.layers),
        _switchTile(icon: LucideIcons.bot, title: 'ARIA Voice',
            value: _notifAria && _notifications,
            onChanged: (v) => setState(() => _notifAria = v)),
        _switchTile(icon: LucideIcons.mapPin, title: 'Navigation & Maps',
            value: _notifMap && _notifications,
            onChanged: (v) => setState(() => _notifMap = v)),
        _switchTile(icon: LucideIcons.users, title: 'Friend Activity',
            value: _notifFriend && _notifications,
            onChanged: (v) => setState(() => _notifFriend = v)),
        _switchTile(icon: LucideIcons.cpu, title: 'System Health',
            value: _notifSystem && _notifications,
            onChanged: (v) => setState(() => _notifSystem = v)),
        const SizedBox(height: 16),
        _sectionLabel('FEEDBACK', LucideIcons.volume2),
        _switchTile(icon: LucideIcons.volume2, title: 'Sound Alerts',
            value: _notifSound,
            onChanged: (v) => setState(() => _notifSound = v)),
        _switchTile(icon: LucideIcons.waves, title: 'Haptic Vibration',
            value: _notifVibration,
            onChanged: (v) => setState(() => _notifVibration = v)),
        _switchTile(icon: LucideIcons.badge, title: 'App Badge Counter',
            value: _notifBadge,
            onChanged: (v) => setState(() => _notifBadge = v)),
        const SizedBox(height: 16),
        _sectionLabel('SCHEDULE', LucideIcons.clock),
        _switchTile(icon: LucideIcons.moonStar, title: 'Do Not Disturb',
            value: _notifDoNotDisturb,
            onChanged: (v) => setState(() => _notifDoNotDisturb = v)),
        _dropdownTile(icon: LucideIcons.layout,
            title: 'Notification Style',
            desc: 'How alerts appear on screen',
            value: _notifStyle, items: styles,
            onChanged: (v) => setState(() => _notifStyle = v!)),
        _dropdownTile(icon: LucideIcons.refreshCw,
            title: 'Delivery Frequency',
            desc: 'Alert batching strategy',
            value: _notifFrequency, items: freqs,
            onChanged: (v) => setState(() => _notifFrequency = v!)),
      ],
    );
  }

  // ─── TAB 5: ABOUT ──────────────────────────────────────────────────────────
  Widget _buildAboutTab() {
    final storageItems = [
      ('App Core',    42.5,           _accent.primary),
      ('Map Cache',   _cacheFootprint, const Color(0xFF22D3EE)),
      ('ARIA Model',  28.0,           const Color(0xFFC084FC)),
      ('User Data',   5.2,            const Color(0xFF4ADE80)),
    ];
    final changelog = [
      ('v2.4.1', 'Current', [
        'Notifications & About tabs', 'Map speed HUD', '3D buildings']),
      ('v2.3.0', 'Jul 2026', [
        'Settings backend sync', 'Map tile caching', 'Geolocation mock']),
      ('v2.2.0', 'Jun 2026', [
        'Biometrics & auto-lock', 'Settings redesign', 'Diagnostics']),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 44),
      children: [
        // App hero card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accent.primary.withValues(alpha: 0.12),
                const Color(0xFF0A0F1E),
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _accent.primary.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [_accent.primary, _accent.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(
                    color: _accent.primary.withValues(alpha: 0.4),
                    blurRadius: 14)],
                ),
                child: const Center(child: Text('N', style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900,
                    color: Colors.black))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEXAL', style: TextStyle(
                      color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accent.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _accent.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(_releaseChannel, style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold,
                          color: _accent.primary)),
                    ),
                    const SizedBox(width: 8),
                    const Text('v$_appVersion', style: TextStyle(
                        color: Colors.white70, fontSize: 13,
                        fontWeight: FontWeight.w600)),
                  ]),
                ],
              )),
            ]),
            const SizedBox(height: 14),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _aboutStat('Build', _buildNumber),
                Container(width: 1, height: 24, color: Colors.white10),
                _aboutStat('Engine', 'Flutter 3.x'),
                Container(width: 1, height: 24, color: Colors.white10),
                _aboutStat('Platform', 'Android/iOS'),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Storage
        _sectionLabel('STORAGE', LucideIcons.database),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Used', style: TextStyle(
                    color: Colors.white70, fontSize: 13)),
                Text('${storageItems.fold(0.0, (s, e) => s + e.$2).toStringAsFixed(1)} MB',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 6,
                child: Row(children: storageItems.map((e) =>
                  Flexible(flex: (e.$2 * 10).toInt(),
                    child: Container(color: e.$3))).toList()),
              ),
            ),
            const SizedBox(height: 12),
            ...storageItems.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(
                    color: e.$3, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(e.$1, style: const TextStyle(
                    color: Colors.white60, fontSize: 12))),
                Text('${e.$2.toStringAsFixed(1)} MB',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        // Changelog
        _sectionLabel('CHANGELOG', LucideIcons.gitBranch),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: changelog.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final isFirst = i == 0;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: i < changelog.length - 1 ? 14 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(children: [
                      Container(width: 8, height: 8,
                          decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFirst
                            ? _accent.primary : Colors.white24,
                        boxShadow: isFirst ? [BoxShadow(
                          color: _accent.primary.withValues(alpha: 0.5),
                          blurRadius: 6)] : null,
                      )),
                      if (i < changelog.length - 1)
                        Container(width: 1, height: 56,
                            color: Colors.white10),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(e.$1, style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            color: isFirst
                                ? _accent.primary : Colors.white54,
                          )),
                          const SizedBox(width: 8),
                          Text(e.$2, style: const TextStyle(
                              fontSize: 10, color: Colors.white30)),
                        ]),
                        const SizedBox(height: 4),
                        ...e.$3.map((n) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(
                                  fontSize: 11, color: Colors.white30)),
                              Expanded(child: Text(n, style: const TextStyle(
                                  fontSize: 11, color: Colors.white54))),
                            ],
                          ),
                        )),
                      ],
                    )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Support links
        _sectionLabel('SUPPORT & LEGAL', LucideIcons.bookOpen),
        ...[
          (LucideIcons.helpCircle, 'Help Center',
              'Documentation, FAQs, tutorials',      null),
          (LucideIcons.code, 'Source Repository',
              'View source code',                    null),
          (LucideIcons.mail, 'Send Feedback',
              'Report bugs, suggest features',       'New'),
          (LucideIcons.fileText, 'Privacy Policy',
              'How your data is stored',             null),
          (LucideIcons.scale, 'Terms of Service',
              'End-user license agreement',          null),
        ].map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SettingsTile(
            icon: item.$1, title: item.$2,
            description: item.$3, accentColor: _accent.primary,
            onTap: () {},
            trailing: item.$4 != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accent.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.$4!, style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.bold,
                        color: _accent.primary)),
                  )
                : const Icon(LucideIcons.chevronRight,
                    color: Colors.white24, size: 16),
          ),
        )),
        const SizedBox(height: 24),
        const Center(child: Column(children: [
          Text('Built with \u2764\uFE0F by the Nexal Team',
              style: TextStyle(fontSize: 12, color: Colors.white24)),
          SizedBox(height: 3),
          Text('\u00A9 2026 Nexal Labs. All rights reserved.',
              style: TextStyle(fontSize: 10, color: Colors.white12)),
        ])),
      ],
    );
  }

  Widget _aboutStat(String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
          color: _accent.primary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(
          fontSize: 10, color: Colors.white38)),
    ]);
  }

  // ─── SAVE BAR ────────────────────────────────────────────────────────────────
  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF080C18),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 46,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: (_saved ? Colors.green : _accent.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 12, spreadRadius: 1,
                )],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _saved ? Colors.green : _accent.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _saveConfig,
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _saved ? LucideIcons.check : LucideIcons.save,
                            size: 15, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(_saved ? 'Saved!' : 'Save Changes',
                              style: const TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── ACCENT MODEL ────────────────────────────────────────────────────────────
class _AccentStyle {
  final String name;
  final Color primary;
  final Color secondary;

  const _AccentStyle({
    required this.name,
    required this.primary,
    required this.secondary,
  });
}
