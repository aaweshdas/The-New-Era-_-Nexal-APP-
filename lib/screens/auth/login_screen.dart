import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'profile_setup_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Unified Auth Screen - Monochrome Black & White Glassmorphism
// ──────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Mode toggle: false = Sign In, true = Sign Up
  bool _isSignUpMode = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  late AnimationController _bgCtrl;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _passFocused = false;
  bool _confirmPassFocused = false;

  int _passStrength = 0;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _nameFocus.addListener(() => setState(() => _nameFocused = _nameFocus.hasFocus));
    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passFocus.addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
    _confirmPassFocus.addListener(() => setState(() => _confirmPassFocused = _confirmPassFocus.hasFocus));

    _passCtrl.addListener(_evaluateStrength);
  }

  void _evaluateStrength() {
    final pass = _passCtrl.text;
    int score = 0;
    if (pass.length >= 6) score++;
    if (pass.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score++;
    if (RegExp(r'[0-9!@#\$%^&*]').hasMatch(pass)) score++;
    setState(() => _passStrength = score);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (_isSignUpMode) {
      final name = _nameCtrl.text.trim();
      final confirm = _confirmPassCtrl.text.trim();

      if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
        _showSnackBar('Please fill in all required fields', isError: true);
        return;
      }
      if (pass.length < 6) {
        _showSnackBar('Password must be at least 6 characters', isError: true);
        return;
      }
      if (pass != confirm) {
        _showSnackBar('Passwords do not match', isError: true);
        return;
      }

      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);
      final success = await AuthService.instance.signup(name, email, pass);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        HapticFeedback.mediumImpact();
        _navigateToProfileSetup(name, email);
      } else {
        _showSnackBar('Signup failed. Please try again.', isError: true);
      }
    } else {
      if (email.isEmpty || pass.isEmpty) {
        _showSnackBar('Please enter your email and password', isError: true);
        return;
      }

      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);
      final success = await AuthService.instance.login(email, pass);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        HapticFeedback.mediumImpact();
        _navigateToHome();
      } else {
        _showSnackBar('Invalid credentials. Please try again.', isError: true);
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const HomeScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToProfileSetup(String name, String email) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => ProfileSetupScreen(
          initialName: name,
          initialEmail: email,
        ),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _handleDemoLogin() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    await AuthService.instance.login('guest@nexal.space', 'demo1234');
    if (!mounted) return;
    setState(() => _isLoading = false);
    _navigateToHome();
  }

  Future<void> _handleGoogleLogin() async {
    HapticFeedback.lightImpact();
    setState(() => _isGoogleLoading = true);

    final success = await AuthService.instance.loginWithGoogle();
    if (!mounted) return;

    if (success || AuthService.instance.isLoggedIn) {
      setState(() => _isGoogleLoading = false);
      HapticFeedback.mediumImpact();
      _navigateToHome();
      return;
    }

    // Attach stream listener if browser redirect is still pending
    StreamSubscription? sub;
    sub = AuthService.instance.authStateChanges.listen((session) {
      if (!mounted) return;
      if (session != null) {
        sub?.cancel();
        setState(() => _isGoogleLoading = false);
        HapticFeedback.mediumImpact();
        _navigateToHome();
      }
    });

    await Future.delayed(const Duration(seconds: 15));
    if (mounted && _isGoogleLoading) {
      sub.cancel();
      setState(() => _isGoogleLoading = false);
      if (!AuthService.instance.isLoggedIn) {
        _showSnackBar('Google Sign-In cancelled or timed out.', isError: true);
      }
    }
  }

  Future<void> _handleFacebookLogin() async {
    HapticFeedback.lightImpact();
    setState(() => _isFacebookLoading = true);

    final success = await AuthService.instance.loginWithFacebook();
    if (!mounted) return;

    if (success || AuthService.instance.isLoggedIn) {
      setState(() => _isFacebookLoading = false);
      HapticFeedback.mediumImpact();
      _navigateToHome();
      return;
    }

    StreamSubscription? sub;
    sub = AuthService.instance.authStateChanges.listen((session) {
      if (!mounted) return;
      if (session != null) {
        sub?.cancel();
        setState(() => _isFacebookLoading = false);
        HapticFeedback.mediumImpact();
        _navigateToHome();
      }
    });

    await Future.delayed(const Duration(seconds: 15));
    if (mounted && _isFacebookLoading) {
      sub.cancel();
      setState(() => _isFacebookLoading = false);
      if (!AuthService.instance.isLoggedIn) {
        _showSnackBar('Facebook Sign-In cancelled or timed out.', isError: true);
      }
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF38BDF8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background Image (assets/login BG.png) ─────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/login BG.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // ── Black & White Glass Vignette Overlay ────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),

          // ── Main Content (Compact & Centered Screen Flow) ──────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // ── Brand Logo Header (Shifted upwards without moving login panel) ──
                    Transform.translate(
                      offset: const Offset(0, -45.0),
                      child: _buildBrandHeader(),
                    ),

                    const SizedBox(height: 12), // Gap maintained, login panel stays fixed

                    // ── Black & White Glassmorphism Combined Auth Card ─────
                    _buildAuthCard(),

                            const SizedBox(height: 18),

                            // ── Google Sign-In ────────────────────────────────────
                            _buildGoogleButton(),

                            const SizedBox(height: 12),

                            // ── Facebook Sign-In ──────────────────────────────────
                            _buildFacebookButton(),

                            const SizedBox(height: 12),

                            // ── Divider ───────────────────────────────────────────
                            _buildDivider(),

                            const SizedBox(height: 12),

                            // ── Guest Button ──────────────────────────────────────
                            _buildGuestButton(),

                            const SizedBox(height: 20),

                            // ── Mode Switcher Link ─────────────────────────────────
                            _buildModeToggleLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Brand Header (Black & White Glassmorphism Squircle Logo)
  // ──────────────────────────────────────────────────────────────────────────
  // Brand Header (Black & White Glassmorphism Squircle Logo + Main Dashboard Font Headline)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildBrandHeader() {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Brightened Logo Container (ColorFilter Brightness + Glow Shadow) ──
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 3,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  1.25, 0,    0,    0, 15,
                  0,    1.25, 0,    0, 15,
                  0,    0,    1.25, 0, 15,
                  0,    0,    0,    1, 0,
                ]),
                child: Image.asset(
                  'assets/nexal_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 700.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 800.ms),

          const SizedBox(width: 20),

          // ── Right Side Typography: Nexal & The New Era (Rye Font Indented Layout) ─
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Line 1: NEXAL (Uppercase Rye Font - size 56)
              Text(
                'NEXAL',
                style: GoogleFonts.rye(
                  color: Colors.white,
                  fontSize: 56,
                  height: 1.05,
                  letterSpacing: 2.0,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(
                    duration: 3.seconds,
                    colors: const [
                      Colors.white,
                      Color(0xFFA855F7),
                      Color(0xFF06B6D4),
                      Color(0xFFEC4899),
                      Colors.white,
                    ],
                  )
                  .fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 4),

              // Line 2: The New Era (Indented 82px Right under NEXAL, size 22)
              Padding(
                padding: const EdgeInsets.only(left: 82.0),
                child: Text(
                  'The New Era',
                  style: GoogleFonts.rye(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 22,
                    letterSpacing: 2.0,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Black & White Glassmorphism Auth Card Body
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAuthCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.60),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Stack(
            children: [
              // Sleek Dark Obsidian Glassmorphism Fill (Pure Matte Obsidian Glass, Zero White Glare)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(38),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.70),
                      Colors.black.withValues(alpha: 0.80),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Segmented Black & White Tab Controller ──────────────
                    _buildSegmentedTabBar(),

                    const SizedBox(height: 24),

                    // Full Name (Sign Up Mode)
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: _isSignUpMode
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildTextField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          isFocused: _nameFocused,
                          hint: 'Full Name',
                          icon: LucideIcons.user,
                          accentColor: Colors.white,
                        ),
                      ),
                    ),

                    // Email Field
                    _buildTextField(
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      isFocused: _emailFocused,
                      hint: 'Email address',
                      icon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      accentColor: Colors.white,
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    _buildTextField(
                      controller: _passCtrl,
                      focusNode: _passFocus,
                      isFocused: _passFocused,
                      hint: _isSignUpMode ? 'Password (min 6 chars)' : 'Password',
                      icon: LucideIcons.lock,
                      obscure: _obscureText,
                      accentColor: Colors.white,
                      onToggleObscure: () => setState(() => _obscureText = !_obscureText),
                    ),

                    // Password Strength bar (Sign Up Mode)
                    if (_isSignUpMode && _passCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildStrengthBar(),
                    ],

                    // Confirm Password Field (Sign Up Mode)
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: _isSignUpMode
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildTextField(
                          controller: _confirmPassCtrl,
                          focusNode: _confirmPassFocus,
                          isFocused: _confirmPassFocused,
                          hint: 'Confirm Password',
                          icon: LucideIcons.shieldCheck,
                          obscure: _obscureConfirmText,
                          accentColor: Colors.white,
                          onToggleObscure: () => setState(() => _obscureConfirmText = !_obscureConfirmText),
                        ),
                      ),
                    ),

                    // Forgot Password (Sign In Mode)
                    if (!_isSignUpMode) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {},
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Black & White High-Contrast Liquid Primary CTA Button
                    _buildPrimaryButton(
                      label: _isSignUpMode ? 'CREATE ACCOUNT' : 'SIGN IN',
                      onPressed: _isLoading ? null : _handleAuth,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),

              // Upper Soft Ambient Arc (Minimal 4% Tint, Zero White Glare)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 35,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 700.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Segmented Black & White Liquid Glass Tab Bar [ Sign In | Sign Up ]
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSegmentedTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              title: 'Sign In',
              isSelected: !_isSignUpMode,
              onTap: () {
                if (_isSignUpMode) {
                  HapticFeedback.selectionClick();
                  setState(() => _isSignUpMode = false);
                }
              },
            ),
          ),
          Expanded(
            child: _buildTabItem(
              title: 'Sign Up',
              isSelected: _isSignUpMode,
              onTap: () {
                if (!_isSignUpMode) {
                  HapticFeedback.selectionClick();
                  setState(() => _isSignUpMode = true);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.80),
                  ],
                )
              : null,
          border: isSelected
              ? Border.all(color: Colors.white, width: 1.2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: isSelected ? const Color(0xFF0F172A) : Colors.white60,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthBar() {
    const labels = ['Weak', 'Fair', 'Good', 'Strong'];
    const colors = [
      Color(0xFFEF4444),
      Color(0xFFF97316),
      Color(0xFFEAB308),
      Color(0xFF22C55E),
    ];
    final idx = (_passStrength - 1).clamp(0, 3);
    return Row(
      children: [
        ...List.generate(4, (i) {
          final filled = i < _passStrength;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: filled
                    ? colors[idx]
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _passStrength > 0 ? labels[idx] : '',
            key: ValueKey(_passStrength),
            style: GoogleFonts.outfit(
              color: _passStrength > 0 ? colors[idx] : Colors.transparent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 650.ms);
  }

  Widget _buildGoogleButton() {
    final busy = _isGoogleLoading || _isLoading;
    return GestureDetector(
      onTap: busy ? null : _handleGoogleLogin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.black.withValues(alpha: busy ? 0.20 : 0.40),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.50),
                width: 1.4,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.30),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isGoogleLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: GoogleGIcon(size: 16),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Text(
                        _isGoogleLoading ? 'Opening Google...' : 'Continue with Google',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.40),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 680.ms, duration: 500.ms);
  }

  Widget _buildFacebookButton() {
    final busy = _isLoading || _isGoogleLoading || _isFacebookLoading;
    return GestureDetector(
      onTap: busy ? null : _handleFacebookLogin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.black.withValues(alpha: busy ? 0.20 : 0.40),
              border: Border.all(
                color: const Color(0xFF1877F2).withValues(alpha: 0.60),
                width: 1.4,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1877F2).withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.30),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1877F2).withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isFacebookLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1877F2),
                          ),
                          child: const Center(
                            child: Text(
                              'f',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Text(
                        _isFacebookLoading ? 'Opening Facebook...' : 'Continue with Facebook',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.40),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 710.ms, duration: 500.ms);
  }

  Widget _buildGuestButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleDemoLogin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.25),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.zap, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Continue as Guest',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 750.ms, duration: 500.ms);
  }

  Widget _buildModeToggleLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUpMode ? 'Already have an account?  ' : "Don't have an account?  ",
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isSignUpMode = !_isSignUpMode);
          },
          child: Text(
            _isSignUpMode ? 'Sign In' : 'Sign Up',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white70,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool? obscure,
    Color accentColor = Colors.white,
    VoidCallback? onToggleObscure,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isFocused
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.40),
            border: Border.all(
              color: isFocused
                  ? Colors.white.withValues(alpha: 0.90)
                  : Colors.white.withValues(alpha: 0.35),
              width: isFocused ? 1.8 : 1.2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 18,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Stack(
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscure ?? false,
                keyboardType: keyboardType,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      icon,
                      size: 19,
                      color: isFocused ? Colors.white : Colors.white70,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 54),
                  suffixIcon: onToggleObscure != null
                      ? IconButton(
                          icon: Icon(
                            obscure! ? LucideIcons.eyeOff : LucideIcons.eye,
                            color: Colors.white60,
                            size: 19,
                          ),
                          onPressed: onToggleObscure,
                        )
                      : null,
                  hintText: hint,
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 20,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Black & White Glassmorphism Liquid Primary CTA Button
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: onPressed != null
                  ? const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF334155), Color(0xFF1E293B)],
                    ),
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: onPressed != null
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.40),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.40),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Color(0xFF0F172A),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          label,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0F172A), // Obsidian text on liquid white glass
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.70),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Custom 4-Color Official Google 'G' Logo Painter (Blue, Red, Yellow, Green)
// ──────────────────────────────────────────────────────────────────────────────
class GoogleGIcon extends StatelessWidget {
  final double size;
  const GoogleGIcon({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleGLogoPainter(),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w * 0.42;
    final double strokeWidth = w * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // 1. Red Top Arc (#EA4335)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -1.95, 1.9, false, paint);

    // 2. Yellow Left Arc (#FBBC05)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -0.05, 1.15, false, paint);

    // 3. Green Bottom Arc (#34A853)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.1, 1.25, false, paint);

    // 4. Blue Right Arc (#4285F4)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.7, 0.75, false, paint);

    // Horizontal crossbar of 'G' (#4285F4)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(cx - strokeWidth * 0.1, cy - strokeWidth / 2, cx + radius + strokeWidth * 0.4, cy + strokeWidth / 2),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
