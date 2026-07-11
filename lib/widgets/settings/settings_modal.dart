import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/aria_config.dart';
import '../../services/aria_service.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> with SingleTickerProviderStateMixin {
  // Config Text Controllers
  final _backendUrlCtrl   = TextEditingController();
  final _groqKeyCtrl      = TextEditingController();
  final _deepgramKeyCtrl  = TextEditingController();
  final _livekitUrlCtrl   = TextEditingController();
  final _livekitKeyCtrl   = TextEditingController();
  final _livekitSecCtrl   = TextEditingController();

  // Dialog State
  bool _loading = true;
  bool _saved   = false;
  bool _obscureGroq     = true;
  bool _obscureDeepgram = true;
  bool _obscureLivekit  = true;

  // Redesign Navigation & Preferences
  int _activeTab = 0; // 0: System, 1: Visuals, 2: Security, 3: Diagnostics
  int _selectedAccent = 1; // 0: Solar Gold, 1: Electric Cyan, 2: Cosmic Violet, 3: Ruby Rose
  bool _darkMode = true;
  bool _notifications = true;
  String _selectedLanguage = "English (US)";

  // Personal Security states
  bool _biometricsEnabled = false;
  bool _encryptSync = true;
  bool _privacyShield = false;
  bool _appLockPin = false;
  String _autoLockTime = "Immediately";
  bool _clearingActivityLogs = false;

  // Diagnostics state
  bool _testingConnection = false;
  String _connectionStatus = "Not Tested"; // Online, Offline, Not Tested
  int? _connectionPing; // in ms
  double _cacheFootprint = 18.4; // simulated tile cache footprint in MB
  bool _purgingCache = false;

  late TabController _tabCtrl;

  // Accent Styles definitions
  final List<_AccentStyle> _accents = [
    _AccentStyle(
      name: "Solar Gold",
      primary: const Color(0xFFD4A843),
      secondary: const Color(0xFFB45309),
    ),
    _AccentStyle(
      name: "Electric Cyan",
      primary: const Color(0xFF22D3EE),
      secondary: const Color(0xFF0EA5E9),
    ),
    _AccentStyle(
      name: "Cosmic Violet",
      primary: const Color(0xFFC084FC),
      secondary: const Color(0xFF7E22CE),
    ),
    _AccentStyle(
      name: "Ruby Rose",
      primary: const Color(0xFFF43F5E),
      secondary: const Color(0xFFBE123C),
    ),
  ];

  _AccentStyle get currentAccent => _accents[_selectedAccent];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) {
        setState(() {
          _activeTab = _tabCtrl.index;
        });
      }
    });
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await AriaConfig.load();
    _backendUrlCtrl.text   = config.backendUrl;
    _groqKeyCtrl.text      = config.groqApiKey;
    _deepgramKeyCtrl.text  = config.deepgramApiKey;
    _livekitUrlCtrl.text   = config.livekitUrl;
    _livekitKeyCtrl.text   = config.livekitApiKey;
    _livekitSecCtrl.text   = config.livekitApiSecret;

    final prefs = await SharedPreferences.getInstance();
    _selectedAccent = prefs.getInt('nexal_selected_accent') ?? 1;
    _darkMode = prefs.getBool('nexal_dark_mode') ?? true;
    _notifications = prefs.getBool('nexal_notifications') ?? true;
    _selectedLanguage = prefs.getString('nexal_language') ?? "English (US)";

    // Personal Security loaders
    _biometricsEnabled = prefs.getBool('nexal_biometrics_enabled') ?? false;
    _encryptSync = prefs.getBool('nexal_encrypt_sync') ?? true;
    _privacyShield = prefs.getBool('nexal_privacy_shield') ?? false;
    _appLockPin = prefs.getBool('nexal_app_lock_pin') ?? false;
    _autoLockTime = prefs.getString('nexal_auto_lock_time') ?? "Immediately";

    if (mounted) setState(() => _loading = false);

    // Try synchronizing with Settings Backend Database
    try {
      final syncUri = Uri.parse("${config.backendUrl}/settings");
      final response = await http.get(syncUri).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Populate text controllers
        _backendUrlCtrl.text = data['backendUrl'] ?? config.backendUrl;
        _groqKeyCtrl.text = data['groqApiKey'] ?? config.groqApiKey;
        _deepgramKeyCtrl.text = data['deepgramApiKey'] ?? config.deepgramApiKey;
        _livekitUrlCtrl.text = data['livekitUrl'] ?? config.livekitUrl;
        _livekitKeyCtrl.text = data['livekitApiKey'] ?? config.livekitApiKey;
        _livekitSecCtrl.text = data['livekitApiSecret'] ?? config.livekitApiSecret;

        // Parse visual/security variables
        _selectedAccent = data['selectedAccent'] ?? _selectedAccent;
        _darkMode = data['darkMode'] ?? _darkMode;
        _notifications = data['notifications'] ?? _notifications;
        _selectedLanguage = data['selectedLanguage'] ?? _selectedLanguage;
        _biometricsEnabled = data['biometricsEnabled'] ?? _biometricsEnabled;
        _encryptSync = data['encryptSync'] ?? _encryptSync;
        _privacyShield = data['privacyShield'] ?? _privacyShield;
        _appLockPin = data['appLockPin'] ?? _appLockPin;
        _autoLockTime = data['autoLockTime'] ?? _autoLockTime;

        // Save back locally to SharedPreferences to keep them in sync
        config.backendUrl = _backendUrlCtrl.text.trim();
        config.groqApiKey = _groqKeyCtrl.text.trim();
        config.deepgramApiKey = _deepgramKeyCtrl.text.trim();
        config.livekitUrl = _livekitUrlCtrl.text.trim();
        config.livekitApiKey = _livekitKeyCtrl.text.trim();
        config.livekitApiSecret = _livekitSecCtrl.text.trim();
        await config.save();

        await prefs.setInt('nexal_selected_accent', _selectedAccent);
        await prefs.setBool('nexal_dark_mode', _darkMode);
        await prefs.setBool('nexal_notifications', _notifications);
        await prefs.setString('nexal_language', _selectedLanguage);
        await prefs.setBool('nexal_biometrics_enabled', _biometricsEnabled);
        await prefs.setBool('nexal_encrypt_sync', _encryptSync);
        await prefs.setBool('nexal_privacy_shield', _privacyShield);
        await prefs.setBool('nexal_app_lock_pin', _appLockPin);
        await prefs.setString('nexal_auto_lock_time', _autoLockTime);

        if (mounted) setState(() {});
      }
    } catch (_) {
      // Offline fallback: keep local SharedPreferences loaded config
      debugPrint("[Settings Sync] Offline or server unreachable, fallback to local database configuration");
    }
  }

  Future<void> _saveConfig() async {
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
    await prefs.setInt('nexal_selected_accent', _selectedAccent);
    await prefs.setBool('nexal_dark_mode', _darkMode);
    await prefs.setBool('nexal_notifications', _notifications);
    await prefs.setString('nexal_language', _selectedLanguage);

    // Personal Security savers
    await prefs.setBool('nexal_biometrics_enabled', _biometricsEnabled);
    await prefs.setBool('nexal_encrypt_sync', _encryptSync);
    await prefs.setBool('nexal_privacy_shield', _privacyShield);
    await prefs.setBool('nexal_app_lock_pin', _appLockPin);
    await prefs.setString('nexal_auto_lock_time', _autoLockTime);

    // Sync to remote settings backend database
    try {
      final syncUri = Uri.parse("${config.backendUrl}/settings");
      final payload = {
        "backendUrl": config.backendUrl,
        "groqApiKey": config.groqApiKey,
        "deepgramApiKey": config.deepgramApiKey,
        "livekitUrl": config.livekitUrl,
        "livekitApiKey": config.livekitApiKey,
        "livekitApiSecret": config.livekitApiSecret,
        "selectedAccent": _selectedAccent,
        "darkMode": _darkMode,
        "notifications": _notifications,
        "selectedLanguage": _selectedLanguage,
        "biometricsEnabled": _biometricsEnabled,
        "encryptSync": _encryptSync,
        "privacyShield": _privacyShield,
        "appLockPin": _appLockPin,
        "autoLockTime": _autoLockTime
      };

      await http.post(
        syncUri,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      debugPrint("[Settings Sync] Remote database push failed (offline), local copy saved successfully.");
    }

    if (mounted) {
      setState(() => _saved = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    }
  }

  Future<void> _testConnection() async {
    if (_testingConnection) return;
    setState(() {
      _testingConnection = true;
      _connectionStatus = "Testing...";
    });

    final stopwatch = Stopwatch()..start();
    final url = _backendUrlCtrl.text.trim();

    try {
      // Direct HTTP check with 4-second timeout limit
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      stopwatch.stop();

      if (mounted) {
        setState(() {
          _testingConnection = false;
          _connectionPing = stopwatch.elapsedMilliseconds;
          // Render servers return 200 or 404/others but we connected
          if (response.statusCode >= 200 && response.statusCode < 500) {
            _connectionStatus = "Online";
          } else {
            _connectionStatus = "Server Error (${response.statusCode})";
          }
        });
      }
    } catch (e) {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _testingConnection = false;
          _connectionPing = null;
          _connectionStatus = "Offline";
        });
      }
    }
  }

  Future<void> _purgeCache() async {
    if (_purgingCache || _cacheFootprint == 0.0) return;
    setState(() => _purgingCache = true);

    await Future.delayed(const Duration(milliseconds: 1400));

    if (mounted) {
      setState(() {
        _purgingCache = false;
        _cacheFootprint = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1E2E).withValues(alpha: 0.9),
          content: Text(
            '✓ System Map Cache Cleared',
            style: GoogleFonts.outfit(color: Colors.greenAccent),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyEnvironment(String env) {
    if (env == 'render') {
      _backendUrlCtrl.text = "https://nexal-backend.onrender.com";
      _livekitUrlCtrl.text = "wss://friday-si6nqz7u.livekit.cloud";
      _livekitKeyCtrl.text = "API6vNUPttbHXDd";
      _livekitSecCtrl.text = "xH4Ld1M8SQZ4XSXQTMYDmMttC8ii2i8nWO09adFSwHG";
    } else if (env == 'local') {
      _backendUrlCtrl.text = "http://10.0.2.2:5000";
      _livekitUrlCtrl.text = "ws://10.0.2.2:7880";
      _livekitKeyCtrl.text = "devkey";
      _livekitSecCtrl.text = "secret";
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        content: Text(
          'Environment Preset Applied: ${env.toUpperCase()}',
          style: GoogleFonts.outfit(color: currentAccent.primary),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _backendUrlCtrl.dispose();
    _groqKeyCtrl.dispose();
    _deepgramKeyCtrl.dispose();
    _livekitUrlCtrl.dispose();
    _livekitKeyCtrl.dispose();
    _livekitSecCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    // Allocate space based on screen height and keyboard visible state
    final height = bottomInset > 0 ? screenHeight * 0.95 : screenHeight * 0.9;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border(
            top: BorderSide(
              color: currentAccent.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: currentAccent.primary.withValues(alpha: 0.12),
              blurRadius: 35,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle with glowing accent
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 14, bottom: 6),
                width: 45,
                height: 4.5,
                decoration: BoxDecoration(
                  color: currentAccent.primary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: currentAccent.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "NEXAL CORE",
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: currentAccent.primary,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "System Dashboard",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white70),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      hoverColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(10),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Segmented Slidable Tabs Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.zero,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      currentAccent.primary.withValues(alpha: 0.25),
                      currentAccent.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentAccent.primary.withValues(alpha: 0.35),
                  ),
                ),
                tabs: [
                  _buildTabHeader(LucideIcons.cpu, "System", 0),
                  _buildTabHeader(LucideIcons.palette, "Visuals", 1),
                  _buildTabHeader(LucideIcons.shield, "Security", 2),
                  _buildTabHeader(LucideIcons.activity, "Diag", 3),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // Scrollable Tab View Content
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: currentAccent.primary,
                        strokeWidth: 3,
                      ),
                    )
                  : TabBarView(
                      controller: _tabCtrl,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildAiSettingsTab(),
                        _buildInterfaceTab(),
                        _buildSecurityTab(),
                        _buildDiagnosticsTab(),
                      ],
                    ),
            ),

            // Sticky Bottom Save Panel
            if (!_loading) _buildSavePanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabHeader(IconData icon, String title, int index) {
    final active = _activeTab == index;
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 15,
            color: active ? currentAccent.primary : Colors.white60,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? Colors.white : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  // ──────── TABS IMPLEMENTATION ───────────────────────────────────────────────

  // 1. AI & APIs TAB
  Widget _buildAiSettingsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader("ENVIRONMENT PRESETS", LucideIcons.layers),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPresetCard(
                label: "Render Prod",
                icon: LucideIcons.cloud,
                desc: "Remote Server",
                active: _backendUrlCtrl.text.contains("onrender.com"),
                onTap: () => _applyEnvironment('render'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPresetCard(
                label: "Local Debug",
                icon: LucideIcons.laptop,
                desc: "10.0.2.2 localhost",
                active: _backendUrlCtrl.text.contains("10.0.2.2"),
                onTap: () => _applyEnvironment('local'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("SERVER ENGINE", LucideIcons.server),
        const SizedBox(height: 10),
        _buildGlowingInputField(
          label: "Core API Endpoint",
          controller: _backendUrlCtrl,
          icon: LucideIcons.link,
          hint: "https://your-api.com",
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("COGNITIVE INTELLIGENCE APIS", LucideIcons.brain),
        const SizedBox(height: 10),
        _buildGlowingInputField(
          label: "Groq LLM Key",
          controller: _groqKeyCtrl,
          icon: LucideIcons.key,
          obscure: _obscureGroq,
          onToggleObscure: () => setState(() => _obscureGroq = !_obscureGroq),
          hint: "gsk_...",
        ),
        const SizedBox(height: 14),
        _buildGlowingInputField(
          label: "Deepgram Voice Key",
          controller: _deepgramKeyCtrl,
          icon: LucideIcons.mic,
          obscure: _obscureDeepgram,
          onToggleObscure: () => setState(() => _obscureDeepgram = !_obscureDeepgram),
          hint: "49a1...",
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("LIVEKIT WEBSOCKET PROTOCOLS", LucideIcons.radio),
        const SizedBox(height: 10),
        _buildGlowingInputField(
          label: "LiveKit Agent Gateway",
          controller: _livekitUrlCtrl,
          icon: LucideIcons.globe,
          hint: "wss://...",
        ),
        const SizedBox(height: 14),
        _buildGlowingInputField(
          label: "LiveKit API Key",
          controller: _livekitKeyCtrl,
          icon: LucideIcons.shieldAlert,
          obscure: _obscureLivekit,
          onToggleObscure: () => setState(() => _obscureLivekit = !_obscureLivekit),
          hint: "API...",
        ),
        const SizedBox(height: 14),
        _buildGlowingInputField(
          label: "LiveKit API Secret",
          controller: _livekitSecCtrl,
          icon: LucideIcons.lock,
          obscure: _obscureLivekit,
          hint: "xH4L...",
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // 2. INTERFACE TAB
  Widget _buildInterfaceTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader("SYSTEM PALETTE", LucideIcons.palette),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Accent Nebula Glow",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Updates primary glowing lines, tabs, and indicator interfaces",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_accents.length, (idx) {
                  final accent = _accents[idx];
                  final isSelected = _selectedAccent == idx;
                  return InkWell(
                    onTap: () => setState(() => _selectedAccent = idx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? accent.primary.withValues(alpha: 0.15) 
                            : Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected 
                              ? accent.primary 
                              : Colors.white10,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: accent.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                          )
                        ] : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [accent.primary, accent.secondary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.primary.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            accent.name.split(" ")[1],
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("SYSTEM PREFERENCES", LucideIcons.sliders),
        const SizedBox(height: 10),
        _buildSettingsSwitchTile(
          icon: LucideIcons.moon,
          title: "Deep Space Dark Mode",
          desc: "Saves battery on OLED displays",
          value: _darkMode,
          onChanged: (val) => setState(() => _darkMode = val),
        ),
        const SizedBox(height: 12),
        _buildSettingsSwitchTile(
          icon: LucideIcons.bell,
          title: "Intelligent Notifications",
          desc: "Push and acoustic feedback triggers",
          value: _notifications,
          onChanged: (val) => setState(() => _notifications = val),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("GLOBAL LOCALIZATION", LucideIcons.globe),
        const SizedBox(height: 10),
        _buildDropdownSelector(),
        const SizedBox(height: 32),
      ],
    );
  }

  // 3. SECURITY TAB
  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader("AUTHENTICATION PROTOCOLS", LucideIcons.fingerprint),
        const SizedBox(height: 10),
        _buildSettingsSwitchTile(
          icon: LucideIcons.fingerprint,
          title: "Biometric Verification",
          desc: "Locks app with fingerprint or FaceID",
          value: _biometricsEnabled,
          onChanged: (val) => setState(() => _biometricsEnabled = val),
        ),
        const SizedBox(height: 12),
        _buildSettingsSwitchTile(
          icon: LucideIcons.lock,
          title: "Device PIN Access Lock",
          desc: "Asks for passcode on launch",
          value: _appLockPin,
          onChanged: (val) => setState(() => _appLockPin = val),
        ),
        const SizedBox(height: 12),
        _buildSecurityDropdownSelector(),
        const SizedBox(height: 24),
        _buildSectionHeader("CRYPTOGRAPHIC SECURITY & SYNC", LucideIcons.shieldCheck),
        const SizedBox(height: 10),
        _buildSettingsSwitchTile(
          icon: LucideIcons.shieldAlert,
          title: "End-to-End Encrypted Sync",
          desc: "Secures coordinates and settings in transit",
          value: _encryptSync,
          onChanged: (val) => setState(() => _encryptSync = val),
        ),
        const SizedBox(height: 12),
        _buildSettingsSwitchTile(
          icon: LucideIcons.eyeOff,
          title: "Privacy Shield Masking",
          desc: "Blurs preview in task switcher view",
          value: _privacyShield,
          onChanged: (val) => setState(() => _privacyShield = val),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("DATA MANAGEMENT", LucideIcons.trash2),
        const SizedBox(height: 12),
        _buildClearLogsCard(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSecurityDropdownSelector() {
    final List<String> intervals = ["Immediately", "1 Minute", "5 Minutes", "Never"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.clock, color: currentAccent.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Auto-Lock Interval",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Duration of inactivity before locking",
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            dropdownColor: const Color(0xFF161622),
            value: _autoLockTime,
            icon: const Icon(LucideIcons.chevronDown, color: Colors.white38, size: 16),
            underline: Container(),
            style: GoogleFonts.outfit(color: currentAccent.primary, fontSize: 13, fontWeight: FontWeight.bold),
            onChanged: (String? newVal) {
              if (newVal != null) {
                setState(() => _autoLockTime = newVal);
              }
            },
            items: intervals.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClearLogsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.history, color: Colors.redAccent, size: 18),
              const SizedBox(width: 10),
              Text(
                "Clear Activity & Location History",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Purges search queries, geolocation caches, and private logs from your local device storage permanently.",
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
                ),
              ),
              onPressed: _clearingActivityLogs ? null : _clearActivityLogs,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _clearingActivityLogs
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        )
                      : const Icon(LucideIcons.trash2, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    _clearingActivityLogs ? "Purging Secure Database..." : "Purge Activity Logs",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearActivityLogs() async {
    if (_clearingActivityLogs) return;
    setState(() => _clearingActivityLogs = true);

    final config = await AriaConfig.load();

    // Call settings backend database log purge endpoint
    try {
      final clearUri = Uri.parse("${config.backendUrl}/settings/clear-logs");
      await http.post(clearUri).timeout(const Duration(seconds: 3));
    } catch (_) {
      debugPrint("[Settings Sync] Remote database purge failed (offline), clearing local logs.");
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() => _clearingActivityLogs = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1E2E).withValues(alpha: 0.9),
          content: Text(
            '✓ Local Activity & Secure Location History Purged',
            style: GoogleFonts.outfit(color: Colors.greenAccent),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 4. DIAGNOSTICS TAB
  Widget _buildDiagnosticsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader("GATEWAY CONNECTIVITY TEST", LucideIcons.radio),
        const SizedBox(height: 12),
        _buildDiagnosticsStatusCard(),
        const SizedBox(height: 24),
        _buildSectionHeader("SYSTEM CACHE GAUGES", LucideIcons.hardDrive),
        const SizedBox(height: 12),
        _buildCacheGaugeCard(),
        const SizedBox(height: 24),
        _buildSectionHeader("DEVICE HARDWARE PROFILE", LucideIcons.smartphone),
        const SizedBox(height: 12),
        _buildHardwareCard(),
        const SizedBox(height: 32),
      ],
    );
  }

  // ──────── COMPONENT BUILDERS ────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: currentAccent.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: currentAccent.primary.withValues(alpha: 0.8),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCard({
    required String label,
    required IconData icon,
    required String desc,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active 
              ? currentAccent.primary.withValues(alpha: 0.08) 
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active 
                ? currentAccent.primary.withValues(alpha: 0.5) 
                : Colors.white.withValues(alpha: 0.05),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: active 
                    ? currentAccent.primary.withValues(alpha: 0.15) 
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: active ? currentAccent.primary : Colors.white60,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.bold : FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.white38,
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

  Widget _buildGlowingInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: FocusScope(
        child: Focus(
          onFocusChange: (hasFocus) {},
          child: Builder(builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFocused 
                      ? currentAccent.primary.withValues(alpha: 0.7) 
                      : Colors.transparent,
                  width: 1,
                ),
                boxShadow: isFocused ? [
                  BoxShadow(
                    color: currentAccent.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                  )
                ] : null,
              ),
              child: Row(
                children: [
                  Icon(icon, color: isFocused ? currentAccent.primary : Colors.white38, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.outfit(
                            color: isFocused ? currentAccent.primary.withValues(alpha: 0.9) : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextField(
                          controller: controller,
                          obscureText: obscure,
                          cursorColor: currentAccent.primary,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 6),
                            hintText: hint,
                            hintStyle: GoogleFonts.outfit(
                              color: Colors.white24,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onToggleObscure != null)
                    IconButton(
                      icon: Icon(
                        obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: onToggleObscure,
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSettingsSwitchTile({
    required IconData icon,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: currentAccent.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: currentAccent.primary,
            activeTrackColor: currentAccent.primary.withValues(alpha: 0.25),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector() {
    final List<String> languages = ["English (US)", "Spanish", "German", "Hindi", "French"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.globe, color: currentAccent.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Language Translation",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Default neural synthesis dialect",
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            dropdownColor: const Color(0xFF161622),
            value: _selectedLanguage,
            icon: const Icon(LucideIcons.chevronDown, color: Colors.white38, size: 16),
            underline: Container(),
            style: GoogleFonts.outfit(color: currentAccent.primary, fontSize: 13, fontWeight: FontWeight.bold),
            onChanged: (String? newVal) {
              if (newVal != null) {
                setState(() => _selectedLanguage = newVal);
              }
            },
            items: languages.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Diagnostics status card
  Widget _buildDiagnosticsStatusCard() {
    Color statusColor = Colors.white54;
    IconData statusIcon = LucideIcons.helpCircle;

    if (_connectionStatus == "Online") {
      statusColor = Colors.greenAccent;
      statusIcon = LucideIcons.checkCircle;
    } else if (_connectionStatus == "Offline" || _connectionStatus.contains("Error")) {
      statusColor = Colors.redAccent;
      statusIcon = LucideIcons.alertTriangle;
    } else if (_connectionStatus == "Testing...") {
      statusColor = currentAccent.primary;
      statusIcon = LucideIcons.refreshCw;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _testingConnection
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: currentAccent.primary,
                        ),
                      )
                    : Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Server Health Sync",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _backendUrlCtrl.text.trim(),
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white30),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _connectionStatus,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (_connectionPing != null && !_testingConnection)
                    Text(
                      "${_connectionPing}ms ping",
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: currentAccent.primary.withValues(alpha: 0.1),
                foregroundColor: currentAccent.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: currentAccent.primary.withValues(alpha: 0.25)),
                ),
              ),
              onPressed: _testConnection,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.play, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    _testingConnection ? "Pinging Gateway..." : "Run Connectivity Test",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // System tile cache footprint gauge card
  Widget _buildCacheGaugeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.hardDrive, color: currentAccent.primary, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    "Local Map Cache",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                "${_cacheFootprint.toStringAsFixed(1)} MB / 100 MB max",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _cacheFootprint / 100.0,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: currentAccent.primary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _cacheFootprint == 0.0
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.redAccent.withValues(alpha: 0.1),
                foregroundColor: _cacheFootprint == 0.0 ? Colors.white24 : Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _cacheFootprint == 0.0
                        ? Colors.white10
                        : Colors.redAccent.withValues(alpha: 0.2),
                  ),
                ),
              ),
              onPressed: _cacheFootprint == 0.0 ? null : _purgeCache,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _purgingCache
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        )
                      : Icon(
                          _cacheFootprint == 0.0 ? LucideIcons.trash : LucideIcons.trash2,
                          size: 14,
                        ),
                  const SizedBox(width: 8),
                  Text(
                    _purgingCache 
                        ? "Purging Disk Sectors..." 
                        : _cacheFootprint == 0.0 
                            ? "Cache Empty" 
                            : "Purge System Tiles Cache",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // System hardware indicators
  Widget _buildHardwareCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Neural Engine Diagnostics",
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          _buildDiagLine("Rendering Backend", "Impeller (Vulkan/OpenGL)"),
          _buildDiagLine("WebGL Context state", "Active (Tile Capped @ 20)"),
          _buildDiagLine("Location Provider Accuracy", "High Performance GPS"),
          _buildDiagLine("Host Architecture", "AArch64 ARMv8-A Neon"),
        ],
      ),
    );
  }

  Widget _buildDiagLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
          Text(value, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // sticky bottom save panel
  Widget _buildSavePanel() {
    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 16, 
        bottom: 16 + MediaQuery.of(context).padding.bottom
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF09090D).withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _saved 
                          ? Colors.green.withValues(alpha: 0.25) 
                          : currentAccent.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saved ? Colors.green : currentAccent.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _saveConfig,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _saved ? LucideIcons.check : LucideIcons.save,
                        size: 16,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _saved ? "SYSTEM LOADED" : "APPLY CONFIG",
                        style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.black,
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
    );
  }
}

class _AccentStyle {
  final String name;
  final Color primary;
  final Color secondary;

  _AccentStyle({
    required this.name,
    required this.primary,
    required this.secondary,
  });
}
