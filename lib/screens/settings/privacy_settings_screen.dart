import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isPrivateAccount = false;
  bool _allowDirectMessages = true;
  bool _showOnlineStatus = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isPrivateAccount = prefs.getBool('privacy_private_$uid') ?? false;
        _allowDirectMessages = prefs.getBool('privacy_dms_$uid') ?? true;
        _showOnlineStatus = prefs.getBool('privacy_online_$uid') ?? true;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${key}_$uid', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white70),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Privacy Controls',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeThumbColor: const Color(0xFF00E5FF),
                          title: const Text(
                            'Private Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: const Text(
                            'Only approved connections can view your posts and gallery',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          value: _isPrivateAccount,
                          onChanged: (v) { setState(() => _isPrivateAccount = v); _updateSetting('privacy_private', v); },
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        SwitchListTile(
                          activeThumbColor: const Color(0xFF00E5FF),
                          title: const Text(
                            'Allow Direct Messages',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: const Text(
                            'Receive messages from anyone on Nexal',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          value: _allowDirectMessages,
                          onChanged: (v) { setState(() => _allowDirectMessages = v); _updateSetting('privacy_dms', v); },
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        SwitchListTile(
                          activeThumbColor: const Color(0xFF00E5FF),
                          title: const Text(
                            'Show Active Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: const Text(
                            'Let your connections see when you are online in Quantum Space',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          value: _showOnlineStatus,
                          onChanged: (v) { setState(() => _showOnlineStatus = v); _updateSetting('privacy_online', v); },
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
    );
  }
}
