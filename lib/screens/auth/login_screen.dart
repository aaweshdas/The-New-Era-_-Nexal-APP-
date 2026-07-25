import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'signup_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Cyber Blue Background Painter (Metallic Ray Burst & Particles)
// ──────────────────────────────────────────────────────────────────────────────
class _CyberBackgroundPainter extends CustomPainter {
  final double t; // 0..1 animation value

  _CyberBackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Deep space dark blue background base
    paint.color = const Color(0xFF030712);
    canvas.drawRect(Offset.zero & size, paint);

    // Cyan/Blue light burst from center bottom
    paint.shader = RadialGradient(
      center: const Alignment(0.0, 0.6),
      radius: 0.95,
      colors: [
        const Color(0xFF00B4D8).withValues(alpha: 0.28),
        const Color(0xFF0077B6).withValues(alpha: 0.15),
        const Color(0xFF030712).withValues(alpha: 0.95),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    // Glowing electric blue light rays
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width * 0.5, size.height * 0.7);
    for (int i = 0; i < 16; i++) {
      final angle = (i * math.pi / 8) + (math.sin(t * math.pi * 2) * 0.05);
      final rayLength = size.width * (0.8 + 0.2 * math.sin(i + t * 5));
      final endOffset = Offset(
        center.dx + math.cos(angle) * rayLength,
        center.dy - math.sin(angle) * rayLength,
      );

      rayPaint.shader = LinearGradient(
        colors: [
          const Color(0xFF00F0FF).withValues(alpha: 0.18),
          const Color(0xFF0055FF).withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(center, endOffset));

      canvas.drawLine(center, endOffset, rayPaint);
    }
  }

  @override
  bool shouldRepaint(_CyberBackgroundPainter old) => old.t != t;
}

// ──────────────────────────────────────────────────────────────────────────────
// Chamfered Cyber Polygon Card Clipper & Painter
// ──────────────────────────────────────────────────────────────────────────────
class _CyberCardClipper extends CustomClipper<Path> {
  final double chamfer;
  _CyberCardClipper({this.chamfer = 42.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    // Top-Left
    path.moveTo(0, 0);
    // Top line to chamfer start
    path.lineTo(size.width - chamfer, 0);
    // Top-Right chamfer cut
    path.lineTo(size.width, chamfer);
    // Right edge down
    path.lineTo(size.width, size.height);
    // Bottom edge to chamfer start
    path.lineTo(chamfer, size.height);
    // Bottom-Left chamfer cut
    path.lineTo(0, size.height - chamfer);
    // Close back to top-left
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CyberCardBorderPainter extends CustomPainter {
  final double chamfer;
  final Color color;

  _CyberCardBorderPainter({this.chamfer = 42.0, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - chamfer, 0)
      ..lineTo(size.width, chamfer)
      ..lineTo(size.width, size.height)
      ..lineTo(chamfer, size.height)
      ..lineTo(0, size.height - chamfer)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CyberCardBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ──────────────────────────────────────────────────────────────────────────────
// Login Screen
// ──────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  late AnimationController _bgCtrl;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscureText = true;
  bool _emailFocused = false;
  bool _passFocused = false;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passFocus.addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
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
      backgroundColor: const Color(0xFF030712),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Cyber Ray Background ──────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, _) => CustomPaint(
                painter: _CyberBackgroundPainter(_bgCtrl.value),
              ),
            ),
          ),

          // ── Content Container ─────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Left side metallic bracket tabs
                    Positioned(
                      left: 0,
                      top: 40,
                      child: Column(
                        children: List.generate(
                          3,
                          (i) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            width: 8,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Main Cyber Chamfered Glass Card
                    Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: _buildCyberGlassCard(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberGlassCard() {
    const chamfer = 46.0;
    final borderColor = const Color(0xFF00F0FF).withValues(alpha: 0.35);

    return CustomPaint(
      foregroundPainter: _CyberCardBorderPainter(chamfer: chamfer, color: borderColor),
      child: ClipPath(
        clipper: _CyberCardClipper(chamfer: chamfer),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1428).withValues(alpha: 0.70),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F2B4A).withValues(alpha: 0.75),
                  const Color(0xFF06152B).withValues(alpha: 0.65),
                  const Color(0xFF020914).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Brand Header (INTECH / NEXAL) ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INTECH',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'NEXAL v2.0',
                        style: GoogleFonts.shareTechMono(
                          color: const Color(0xFF00F0FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── "Login with" Title & Subtitle ────────────────────────────
                Text(
                  'Login with',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Access the quantum network through your secure credentials.',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Quick Option Pills (Option 1 / Option 2) ────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionPill(
                        label: 'Google',
                        icon: LucideIcons.code2,
                        isLoading: _isGoogleLoading,
                        onTap: (_isGoogleLoading || _isLoading) ? null : _handleGoogleLogin,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildOptionPill(
                        label: 'Guest',
                        icon: LucideIcons.zap,
                        isLoading: false,
                        onTap: _isLoading ? null : _handleDemoLogin,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Translucent Divider Line ─────────────────────────────────
                Divider(
                  color: Colors.white.withValues(alpha: 0.12),
                  thickness: 1,
                ),

                const SizedBox(height: 24),

                // ── Email Input Section ──────────────────────────────────────
                _buildFieldLabel('Email'),
                const SizedBox(height: 8),
                _buildPillTextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  isFocused: _emailFocused,
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // ── Password Input Section ───────────────────────────────────
                _buildFieldLabel('Password'),
                const SizedBox(height: 8),
                _buildPillTextField(
                  controller: _passCtrl,
                  focusNode: _passFocus,
                  isFocused: _passFocused,
                  hint: 'Enter your password',
                  obscure: _obscureText,
                  onToggleObscure: () => setState(() => _obscureText = !_obscureText),
                ),

                const SizedBox(height: 10),

                // Forgot Password link right aligned
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Solid Bright White Primary Login CTA Button ──────────────
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
                            color: const Color(0xFF00F0FF),
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
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildOptionPill({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
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
                  color: Colors.white70,
                ),
              )
            else ...[
              Icon(icon, size: 16, color: Colors.white70),
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

  Widget _buildPillTextField({
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
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
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
            color: Colors.white.withValues(alpha: 0.3),
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
              ? const Color(0xFF00F0FF).withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.05),
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
            borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
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
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.35),
              blurRadius: 20,
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
                    color: Color(0xFF0A1428),
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Login',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0A1428),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
