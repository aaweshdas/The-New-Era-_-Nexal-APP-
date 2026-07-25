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
// Star particle data (pre-computed, cheap to generate once)
// ──────────────────────────────────────────────────────────────────────────────
class _StarParticle {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double speed;
  final Color color;

  const _StarParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.color,
  });
}

List<_StarParticle> _buildStars(int count) {
  final rng = math.Random(42);
  const starColors = [
    Color(0xFFFFFFFF),
    Color(0xFF00E5FF),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF3B82F6),
  ];
  return List.generate(count, (_) {
    return _StarParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 0.5 + rng.nextDouble() * 2.0,
      opacity: 0.2 + rng.nextDouble() * 0.7,
      speed: 0.2 + rng.nextDouble() * 0.8,
      color: starColors[rng.nextInt(starColors.length)],
    );
  });
}

final _stars = _buildStars(80);

// ──────────────────────────────────────────────────────────────────────────────
// Nebula + Star background painter
// ──────────────────────────────────────────────────────────────────────────────
class _NebulaPainter extends CustomPainter {
  final double t; // 0..1 animation value

  _NebulaPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Nebula glow 1 – purple
    paint.shader = RadialGradient(
      center: const Alignment(-0.3, -0.6),
      radius: 0.7,
      colors: [
        const Color(0xFFA855F7).withValues(alpha: 0.18),
        Colors.transparent,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    // Nebula glow 2 – blue
    paint.shader = RadialGradient(
      center: const Alignment(0.7, 0.4),
      radius: 0.65,
      colors: [
        const Color(0xFF3B82F6).withValues(alpha: 0.12),
        Colors.transparent,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    // Nebula glow 3 – cyan (slow drift)
    final drift = math.sin(t * math.pi * 2) * 0.04;
    paint.shader = RadialGradient(
      center: Alignment(0.1 + drift, 0.8),
      radius: 0.5,
      colors: [
        const Color(0xFF00E5FF).withValues(alpha: 0.10),
        Colors.transparent,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    // Stars
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in _stars) {
      final twinkle = (math.sin((t * star.speed + star.x) * math.pi * 4) + 1) / 2;
      final alpha = (star.opacity * (0.5 + twinkle * 0.5)).clamp(0.0, 1.0);
      starPaint.color = star.color.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_NebulaPainter old) => old.t != t;
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
      duration: const Duration(seconds: 12),
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
    final launched = await AuthService.instance.loginWithGoogle();
    if (!mounted) return;
    if (!launched) {
      setState(() => _isGoogleLoading = false);
      _showSnackBar('Google Sign-In unavailable. Please try again.', isError: true);
      return;
    }
    // Listen for auth state change — Supabase will fire onAuthStateChange
    // once the OAuth redirect completes, which will update AuthService
    // We subscribe once and navigate when signed in
    AuthService.instance.authStateChanges.listen((session) {
      if (!mounted) return;
      if (session != null) {
        setState(() => _isGoogleLoading = false);
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
    // Safety timeout — if redirect takes too long, stop spinner
    await Future.delayed(const Duration(seconds: 60));
    if (mounted) setState(() => _isGoogleLoading = false);
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
            : const Color(0xFF06B6D4),
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
          // ── Animated nebula background ──────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, _) => CustomPaint(
                painter: _NebulaPainter(_bgCtrl.value),
              ),
            ),
          ),

          // ── Top gradient fade ───────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF050510).withValues(alpha: 0.55),
                    Colors.transparent,
                    const Color(0xFF05050F).withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // ── Logo / Brand ──────────────────────────────────────
                    _buildBrandHeader(),

                    const SizedBox(height: 44),

                    // ── Glass Login Card ──────────────────────────────────
                    _buildLoginCard(),

                    const SizedBox(height: 20),

                    // ── Google Sign-In ────────────────────────────────────
                    _buildGoogleButton(),

                    const SizedBox(height: 12),

                    // ── Divider ───────────────────────────────────────────
                    _buildDivider(),

                    const SizedBox(height: 12),

                    // ── Guest Button ──────────────────────────────────────
                    _buildGuestButton(),

                    const SizedBox(height: 32),

                    // ── Sign Up Link ──────────────────────────────────────
                    _buildSignupLink(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        // App logo with glow halo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.55),
                blurRadius: 40,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.30),
                blurRadius: 60,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: 0.20),
                blurRadius: 80,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/nexal_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut, duration: 900.ms),

        const SizedBox(height: 18),

        // Single line Title: "NEXAL THE NEW ERA" in uniform font & size
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF3B82F6), Color(0xFF00E5FF)],
              ).createShader(bounds),
              child: Text(
                'NEXAL THE NEW ERA',
                style: GoogleFonts.rye(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

        const SizedBox(height: 8),

        Text(
          'Enter the Quantum Nexus',
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.55),
            fontSize: 11,
            letterSpacing: 2.5,
          ),
        ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
      ],
    );
  }


  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFA855F7).withValues(alpha: 0.25),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF7C3AED).withValues(alpha: 0.08),
                const Color(0xFF3B82F6).withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
          ),
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFA855F7), Color(0xFF3B82F6)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign In',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Welcome back, explorer',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Email Field
              _buildTextField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                isFocused: _emailFocused,
                hint: 'Email address',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                accentColor: const Color(0xFF00E5FF),
              ),

              const SizedBox(height: 16),

              // Password Field
              _buildTextField(
                controller: _passCtrl,
                focusNode: _passFocus,
                isFocused: _passFocused,
                hint: 'Password',
                icon: LucideIcons.lock,
                obscure: _obscureText,
                accentColor: const Color(0xFFA855F7),
                onToggleObscure: () => setState(() => _obscureText = !_obscureText),
              ),

              const SizedBox(height: 10),

              // Forgot password
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
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // Login Button
              _buildPrimaryButton(
                label: 'SIGN IN',
                onPressed: _isLoading ? null : _handleLogin,
                isLoading: _isLoading,
                colors: const [Color(0xFF7C3AED), Color(0xFF3B82F6)],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 700.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: GoogleFonts.outfit(
              color: Colors.white24,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildGoogleButton() {
    final busy = _isGoogleLoading || _isLoading;
    return GestureDetector(
      onTap: busy ? null : _handleGoogleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: busy ? 0.03 : 0.07),
          border: Border.all(
            color: Colors.white.withValues(alpha: busy ? 0.08 : 0.18),
            width: 1.2,
          ),
          boxShadow: busy
              ? []
              : [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isGoogleLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white60,
                  strokeWidth: 2,
                ),
              )
            else
              // Google 'G' logo using colored text
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF4285F4),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Text(
              _isGoogleLoading ? 'Opening Google...' : 'Continue with Google',
              style: GoogleFonts.outfit(
                color: busy ? Colors.white38 : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 680.ms, duration: 500.ms);
  }

  Widget _buildGuestButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleDemoLogin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.zap, size: 14, color: Color(0xFF00E5FF)),
                const SizedBox(width: 8),
                Text(
                  'Continue as Guest',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 500.ms);
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?  ",
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, _) => const SignupScreen(),
                transitionsBuilder: (context, animation, _, child) => SlideTransition(
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
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
            ).createShader(bounds),
            child: Text(
              'Sign Up',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  // ── Shared input builder ─────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool? obscure,
    Color accentColor = const Color(0xFF00E5FF),
    VoidCallback? onToggleObscure,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
                  blurRadius: 20,
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
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              icon,
              size: 18,
              color: isFocused ? accentColor : Colors.white30,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure! ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: Colors.white24,
                    size: 18,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: Colors.white24,
            fontSize: 14,
          ),
          filled: true,
          fillColor: isFocused
              ? accentColor.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentColor.withValues(alpha: 0.6), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ── Primary gradient button ──────────────────────────────────────────────
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    required List<Color> colors,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: onPressed != null
              ? LinearGradient(colors: colors)
              : const LinearGradient(
                  colors: [Color(0xFF2D2D3A), Color(0xFF1A1A28)],
                ),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }
}
