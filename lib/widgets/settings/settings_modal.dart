import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/aria_config.dart';
import '../../services/aria_service.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final _backendUrlCtrl   = TextEditingController();
  final _groqKeyCtrl      = TextEditingController();
  final _deepgramKeyCtrl  = TextEditingController();
  final _livekitUrlCtrl   = TextEditingController();
  final _livekitKeyCtrl   = TextEditingController();
  final _livekitSecCtrl   = TextEditingController();
  bool _loading = true;
  bool _saved   = false;
  bool _obscureGroq     = true;
  bool _obscureDeepgram = true;

  @override
  void initState() {
    super.initState();
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
    if (mounted) setState(() => _loading = false);
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
    if (mounted) {
      setState(() => _saved = true);
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
  @override
  Widget build(BuildContext context) {
    // Determine height based on screen size (e.g., 90% of screen height)
    final height = MediaQuery.of(context).size.height * 0.9;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Modal Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Settings",
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white70),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // Settings List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  _SettingsCategory(
                    title: "ACCOUNT",
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.user,
                        title: "Edit Profile",
                        subtitle: "Update your personal info",
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: LucideIcons.shieldCheck,
                        title: "Privacy & Security",
                        subtitle: "Manage your data",
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsCategory(
                    title: "PREFERENCES",
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.bell,
                        title: "Notifications",
                        subtitle: "Push, email, and sound alerts",
                        trailing: Switch.adaptive(
                          value: true,
                          onChanged: (val) {},
                          activeThumbColor: AppTheme.cyan500,
                        ),
                      ),
                      _SettingsTile(
                        icon: LucideIcons.moon,
                        title: "Dark Mode",
                        subtitle: "System default",
                        trailing: Switch.adaptive(
                          value: true,
                          onChanged: (val) {},
                          activeThumbColor: AppTheme.cyan500,
                        ),
                      ),
                      _SettingsTile(
                        icon: LucideIcons.globe,
                        title: "Language",
                        subtitle: "English (US)",
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsCategory(
                    title: "NEXAL AI",
                    children: [
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.cyan500,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        _ApiKeyField(
                          icon: LucideIcons.server,
                          label: "Backend URL",
                          controller: _backendUrlCtrl,
                          obscure: false,
                        ),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                          indent: 56,
                          endIndent: 16,
                        ),
                        _ApiKeyField(
                          icon: LucideIcons.brain,
                          label: "Groq API Key",
                          controller: _groqKeyCtrl,
                          obscure: _obscureGroq,
                          onToggleObscure: () =>
                              setState(() => _obscureGroq = !_obscureGroq),
                        ),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                          indent: 56,
                          endIndent: 16,
                        ),
                        _ApiKeyField(
                          icon: LucideIcons.mic,
                          label: "Deepgram API Key",
                          controller: _deepgramKeyCtrl,
                          obscure: _obscureDeepgram,
                          onToggleObscure: () =>
                              setState(() => _obscureDeepgram = !_obscureDeepgram),
                        ),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                          indent: 56,
                          endIndent: 16,
                        ),
                        // Save button
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _saved
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : AppTheme.cyan500.withValues(alpha: 0.2),
                                foregroundColor: _saved
                                    ? Colors.greenAccent
                                    : AppTheme.cyan500,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _saved
                                        ? Colors.greenAccent.withValues(alpha: 0.4)
                                        : AppTheme.cyan500.withValues(alpha: 0.3),
                                  ),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _saveConfig,
                              child: Text(
                                _saved ? '✓  Saved' : 'Save & Apply',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsCategory(
                    title: "ABOUT",
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.helpCircle,
                        title: "Help & Support",
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: LucideIcons.info,
                        title: "About Nexal",
                        subtitle: "Version 1.0.0",
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 48), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCategory extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCategory({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.cyan500.withValues(alpha: 0.8),
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    color: Colors.white.withValues(alpha: 0.05),
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: trailing == null
          ? onTap
          : null, // Only tap if no switch/trailing exists
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
              ),
            )
          : null,
      trailing:
          trailing ??
          const Icon(LucideIcons.chevronRight, color: Colors.white30, size: 20),
    );
  }
}

class _ApiKeyField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  const _ApiKeyField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.obscure,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    hintText: 'Enter $label',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white30,
                      fontSize: 15,
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
                color: Colors.white30,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
        ],
      ),
    );
  }
}
