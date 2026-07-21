import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PRIVACY CONTROLS',
                        style: GoogleFonts.rye(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SwitchListTile(
                    activeColor: const Color(0xFF00E5FF),
                    title: Text('Private Account', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Only approved connections can view your posts and gallery', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                    value: _isPrivateAccount,
                    onChanged: (v) => setState(() => _isPrivateAccount = v),
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    activeColor: const Color(0xFF00E5FF),
                    title: Text('Allow Direct Messages', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Receive messages from anyone on Nexal', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                    value: _allowDirectMessages,
                    onChanged: (v) => setState(() => _allowDirectMessages = v),
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    activeColor: const Color(0xFF00E5FF),
                    title: Text('Show Active Status', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Let your connections see when you are online in Quantum Space', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                    value: _showOnlineStatus,
                    onChanged: (v) => setState(() => _showOnlineStatus = v),
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
