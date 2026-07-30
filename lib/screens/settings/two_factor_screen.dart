import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:otp/otp.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  bool _is2FAEnabled = false;
  bool _isLoading = false;
  bool _showSetup = false;
  String? _totpSecret;
  String? _totpUri;
  final _verifyCtrl = TextEditingController();
  bool _setupComplete = false;

  // Secure storage — TOTP secrets are stored in Android Keystore / iOS Keychain
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _is2FAEnabled = prefs.getBool('2fa_enabled_$uid') ?? false);
  }

  String _generateSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final rng = Random.secure();
    return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _toggle2FA(bool value) async {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    if (value && !_is2FAEnabled) {
      final secret = _generateSecret();
      final uri = 'otpauth://totp/Nexal:${AuthService.instance.currentUser?.email ?? "user"}?secret=$secret&issuer=Nexal&algorithm=SHA1&digits=6&period=30';
      setState(() { _totpSecret = secret; _totpUri = uri; _showSetup = true; });
    } else if (!value) {
      setState(() => _isLoading = true);
      if (uid.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('2fa_enabled_$uid', false);
        // Remove secret from SECURE storage
        await _secureStorage.delete(key: '2fa_secret_$uid');
      }
      if (!mounted) return;
      setState(() { _is2FAEnabled = false; _isLoading = false; _setupComplete = false; _showSetup = false; _totpSecret = null; _totpUri = null; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('2FA disabled', style: TextStyle(fontSize: 14)),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _verifyAndEnable() async {
    final code = _verifyCtrl.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter the 6-digit code from your authenticator app', style: TextStyle(fontSize: 14)),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    if (_totpSecret == null) return;
    setState(() => _isLoading = true);

    // ── Real TOTP Verification using HMAC-SHA1 ──────────────────────────────
    // Allow ±1 time-step tolerance for clock drift
    bool isValid = false;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (int offset in [-1, 0, 1]) {
      final expectedCode = OTP.generateTOTPCodeString(
        _totpSecret!,
        now + (offset * 30000),
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (expectedCode == code) {
        isValid = true;
        break;
      }
    }

    if (!isValid) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Invalid code. Please try again.', style: TextStyle(fontSize: 14)),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    // ── Persist 2FA state ──────────────────────────────────────────────────
    final uid = AuthService.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('2fa_enabled_$uid', true);
      // Store TOTP secret in SECURE storage (Android Keystore / iOS Keychain)
      await _secureStorage.write(key: '2fa_secret_$uid', value: _totpSecret!);
    }

    if (!mounted) return;
    setState(() { _is2FAEnabled = true; _setupComplete = true; _isLoading = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 2FA enabled successfully!', style: TextStyle(fontSize: 14)),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
  }

  @override
  void dispose() { _verifyCtrl.dispose(); super.dispose(); }

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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Two-Factor Auth (2FA)',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Status card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _is2FAEnabled ? LucideIcons.shieldCheck : LucideIcons.shield,
                            color: _is2FAEnabled ? const Color(0xFF00E5FF) : Colors.white38,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Two-Factor Authentication',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _is2FAEnabled
                                ? 'Your account is protected with TOTP authentication.'
                                : 'Enable 2FA with an authenticator app for maximum security.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          SwitchListTile(
                            activeThumbColor: const Color(0xFF00E5FF),
                            title: Text(
                              _is2FAEnabled ? 'Disable 2FA' : 'Enable 2FA Protection',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            value: _is2FAEnabled,
                            onChanged: _isLoading ? null : _toggle2FA,
                          ),
                        ],
                      ),
                    ),

                    // Setup flow
                    if (_showSetup && !_setupComplete) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Setup Authenticator',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Scan this QR code in Google Authenticator, Authy, or any TOTP app.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: QrImageView(
                                data: _totpUri!,
                                version: QrVersions.auto,
                                size: 180,
                                gapless: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Or enter manually:',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _totpSecret!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Secret copied!', style: TextStyle(fontSize: 13)),
                                    backgroundColor: Color(0xFF1E293B),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _totpSecret!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(LucideIcons.copy, color: Colors.white38, size: 14),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Enter the 6-digit code from your app to verify:',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _verifyCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                letterSpacing: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                hintText: '000000',
                                hintStyle: const TextStyle(color: Colors.white12, letterSpacing: 10),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00E5FF),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _verifyAndEnable,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Verify & Enable 2FA',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_is2FAEnabled && _setupComplete) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.checkCircle2, color: Color(0xFF00E5FF), size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '2FA is active. You will need your authenticator app to sign in.',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
