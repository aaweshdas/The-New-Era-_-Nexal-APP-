import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  bool _is2FAEnabled = true;

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
                        'TWO-FACTOR AUTH (2FA)',
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

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.shieldCheck, color: Color(0xFF00E5FF), size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Quantum 2FA Protection',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Protect your account with biometric & authenticator token verification.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          activeColor: const Color(0xFF00E5FF),
                          title: Text('Enable 2FA Protection', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          value: _is2FAEnabled,
                          onChanged: (v) => setState(() => _is2FAEnabled = v),
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
