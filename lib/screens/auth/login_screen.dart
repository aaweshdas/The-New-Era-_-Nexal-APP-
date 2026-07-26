import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'signup_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Chamfered Cyber Polygon Clipper & Border Painter (Exact Match to Reference UI)
// ──────────────────────────────────────────────────────────────────────────────
class _CyberCardClipper extends CustomClipper<Path> {
  final double topChamfer;
  final double bottomChamfer;

  _CyberCardClipper({this.topChamfer = 56.0, this.bottomChamfer = 56.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    // Top-Left corner
    path.moveTo(0, 0);
    // Top edge to top-right chamfer
    path.lineTo(size.width - topChamfer, 0);
    // Top-Right chamfer cut
    path.lineTo(size.width, topChamfer);
    // Right edge down
    path.lineTo(size.width, size.height);
    // Bottom edge to bottom-left chamfer
    path.lineTo(bottomChamfer, size.height);
    // Bottom-Left chamfer cut
    path.lineTo(0, size.height - bottomChamfer);
    // Close back to top-left
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CyberCardBorderPainter extends CustomPainter {
  final double topChamfer;
  final double bottomChamfer;
  final Color borderColor;

  _CyberCardBorderPainter({
    this.topChamfer = 56.0,
    this.bottomChamfer = 56.0,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - topChamfer, 0)
      ..lineTo(size.width, topChamfer)
      ..lineTo(size.width, size.height)
      ..lineTo(bottomChamfer, size.height)
      ..lineTo(0, size.height - bottomChamfer)
      ..close();

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CyberCardBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}

// ──────────────────────────────────────────────────────────────────────────────
// Login Screen Component
// ──────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscureText = true;
  bool _emailFocused = false;
  bool _passFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passFocus.addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

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
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const HomeScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      _showSnackBar('Invalid credentials. Please try again.', isError: true);
    }
  }

  Future<void> _handleDemoLogin() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    await AuthService.instance.login('guest@nexal.space', 'demo1234');
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const HomeScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    HapticFeedback.lightImpact();
    setState(() => _isGoogleLoading = true);

    final success = await AuthService.instance.loginWithGoogle();
    if (!mounted) return;

    if (AuthService.instance.isLoggedIn) {
      setState(() => _isGoogleLoading = false);
      HapticFeedback.mediumImpact();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const HomeScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    if (!success) {
      setState(() => _isGoogleLoading = false);
      _showSnackBar('Google Sign-In cancelled or unavailable.', isError: true);
      return;
    }

    StreamSubscription? sub;
    sub = AuthService.instance.authStateChanges.listen((session) {
      if (!mounted) return;
      if (session != null) {
        sub?.cancel();
        setState(() => _isGoogleLoading = false);
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const HomeScreen(),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });

    await Future.delayed(const Duration(seconds: 45));
    if (mounted && _isGoogleLoading) {
      sub.cancel();
      setState(() => _isGoogleLoading = false);
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
            ? const Color(0xFF7C3AED)
            : const Color(0xFF00E5FF),
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
        fit: StackFit.expand,
        children: [
          // ── 3D Cyber Blue Radial Background ──────────────────────────────
          Image.asset(
            'assets/images/cyber_login_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, 0.5),
                  radius: 0.9,
                  colors: [Color(0xFF0088CC), Color(0xFF020914), Colors.black],
                ),
              ),
            ),
          ),

          // ── Dark Edge Vignette Overlay ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),

          // ── Main Content Container ─────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: SizedBox(
                  width: 390,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Top-Left Metallic Bracket Tabs (3 Tabs)
                      Positioned(
                        left: -14,
                        top: 48,
                        child: Column(
                          children: List.generate(
                            3,
                            (i) => Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              width: 14,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E1A2A),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom-Right Metallic Bracket Tabs (3 Tabs)
                      Positioned(
                        right: -14,
                        bottom: 60,
                        child: Column(
                          children: List.generate(
                            3,
                            (i) => Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              width: 14,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E1A2A),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Main Cyber Polygon Glass Card
                      _buildCyberGlassCard(),
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

  Widget _buildCyberGlassCard() {
    const topChamfer = 56.0;
    const bottomChamfer = 56.0;
    final borderColor = Colors.white.withValues(alpha: 0.22);

    return CustomPaint(
      foregroundPainter: _CyberCardBorderPainter(
        topChamfer: topChamfer,
        bottomChamfer: bottomChamfer,
        borderColor: borderColor,
      ),
      child: ClipPath(
        clipper: _CyberCardClipper(
          topChamfer: topChamfer,
          bottomChamfer: bottomChamfer,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 34),
            decoration: BoxDecoration(
              color: const Color(0xFF061122).withValues(alpha: 0.68),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0B213D).withValues(alpha: 0.72),
                  const Color(0xFF06152B).withValues(alpha: 0.65),
                  const Color(0xFF030B18).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Brand Logo Header (INTECH) ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INTECH',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        'NEXAL v2.0',
                        style: GoogleFonts.shareTechMono(
                          color: const Color(0xFF00E5FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 34),

                // ── Title & Subtitle ─────────────────────────────────────────
                Text(
                  'Login with',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Option Pills Side-by-Side ────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionPill(
                        label: 'Option 1',
                        iconWidget: const Icon(LucideIcons.code2, size: 15, color: Colors.white),
                        isLoading: _isGoogleLoading,
                        onTap: (_isGoogleLoading || _isLoading) ? null : _handleGoogleLogin,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildOptionPill(
                        label: 'Option 2',
                        iconWidget: const Icon(LucideIcons.code2, size: 15, color: Colors.white),
                        isLoading: false,
                        onTap: _isLoading ? null : _handleDemoLogin,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Translucent Horizontal Divider ───────────────────────────
                Divider(
                  color: Colors.white.withValues(alpha: 0.15),
                  thickness: 1,
                ),

                const SizedBox(height: 24),

                // ── Email Input Field ────────────────────────────────────────
                _buildFieldLabel('Email'),
                const SizedBox(height: 8),
                _buildPillInputField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  isFocused: _emailFocused,
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 18),

                // ── Password Input Field ─────────────────────────────────────
                _buildFieldLabel('Password'),
                const SizedBox(height: 8),
                _buildPillInputField(
                  controller: _passCtrl,
                  focusNode: _passFocus,
                  isFocused: _passFocused,
                  hint: 'Enter your password',
                  obscure: _obscureText,
                  onToggleObscure: () => setState(() => _obscureText = !_obscureText),
                ),

                const SizedBox(height: 10),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Solid Bright White Primary CTA Button ────────────────────
                _buildWhiteLoginButton(),

                const SizedBox(height: 20),

                // ── Sign Up Footer ───────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?  ",
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, _) => const SignupScreen(),
                              transitionsBuilder: (context, animation, _, child) =>
                                  SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                )),
                                child: child,
                              ),
                              transitionDuration: const Duration(milliseconds: 400),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF00E5FF),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.04, curve: Curves.easeOutCubic);
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildOptionPill({
    required String label,
    required Widget iconWidget,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              iconWidget,
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPillInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool? obscure,
    VoidCallback? onToggleObscure,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure ?? false,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.28),
            fontSize: 13,
          ),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure! ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: Colors.white38,
                    size: 18,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          filled: true,
          fillColor: isFocused
              ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildWhiteLoginButton() {
    final busy = _isLoading || _isGoogleLoading;
    return GestureDetector(
      onTap: busy ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF061122),
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Login',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF061122),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
