import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';

// Re-use the same nebula painter from login_screen
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
  final rng = math.Random(99);
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
      size: 0.5 + rng.nextDouble() * 1.8,
      opacity: 0.2 + rng.nextDouble() * 0.7,
      speed: 0.2 + rng.nextDouble() * 0.8,
      color: starColors[rng.nextInt(starColors.length)],
    );
  });
}

final _stars = _buildStars(80);

class _NebulaPainter extends CustomPainter {
  final double t;
  _NebulaPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.shader = RadialGradient(
      center: const Alignment(0.4, -0.5),
      radius: 0.75,
      colors: [
        const Color(0xFFEC4899).withValues(alpha: 0.14),
        Colors.transparent,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    paint.shader = RadialGradient(
      center: const Alignment(-0.6, 0.5),
      radius: 0.6,
      colors: [
        const Color(0xFFA855F7).withValues(alpha: 0.12),
        Colors.transparent,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    final drift = math.sin(t * math.pi * 2) * 0.05;
    paint.shader = RadialGradient(
      center: Alignment(0.2, 0.9 + drift),
      radius: 0.45,
      colors: [
        const Color(0xFF3B82F6).withValues(alpha: 0.10),
        Colors.transparent,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in _stars) {
      final twinkle = (math.sin((t * star.speed + star.x) * math.pi * 4) + 1) / 2;
      final alpha = (star.opacity * (0.4 + twinkle * 0.6)).clamp(0.0, 1.0);
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
// Signup Screen
// ──────────────────────────────────────────────────────────────────────────────
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
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
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _passFocused = false;
  bool _confirmFocused = false;

  // Password strength (0..4)
  int _passStrength = 0;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _nameFocus.addListener(() => setState(() => _nameFocused = _nameFocus.hasFocus));
    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passFocus.addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
    _confirmPassFocus.addListener(() => setState(() => _confirmFocused = _confirmPassFocus.hasFocus));

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

  Future<void> _handleSignup() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
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
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const HomeScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    } else {
      _showSnackBar('Signup failed. Please try again.', isError: true);
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
            ? const Color(0xFFEC4899)
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

          // ── Overlay gradient ────────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF060510).withValues(alpha: 0.55),
                    Colors.transparent,
                    const Color(0xFF05050F).withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Back arrow
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: IconButton(
                      icon: const Icon(LucideIcons.arrowLeft,
                          color: Colors.white60, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
                    child: Column(
                      children: [
                        // ── Brand Header ────────────────────────────────
                        _buildBrandHeader(),

                        const SizedBox(height: 32),

                        // ── Glass Signup Card ───────────────────────────
                        _buildSignupCard(),

                        const SizedBox(height: 30),

                        // ── Login Link ──────────────────────────────────
                        _buildLoginLink(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
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
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: 0.45),
                blurRadius: 36,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFFA855F7).withValues(alpha: 0.30),
                blurRadius: 55,
                spreadRadius: 2,
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
            .fadeIn(duration: 700.ms)
            .scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut, duration: 850.ms),

        const SizedBox(height: 16),

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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

        const SizedBox(height: 8),

        Text(
          'Create your quantum identity',
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFFEC4899).withValues(alpha: 0.55),
            fontSize: 11,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: 450.ms),
      ],
    );
  }


  Widget _buildSignupCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFEC4899).withValues(alpha: 0.22),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFEC4899).withValues(alpha: 0.06),
                const Color(0xFFA855F7).withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
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
                        colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Create Account',
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
                  'Join the next era of social connection',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Full Name
              _buildTextField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                isFocused: _nameFocused,
                hint: 'Full Name',
                icon: LucideIcons.user,
                accentColor: const Color(0xFFEC4899),
              ),

              const SizedBox(height: 14),

              // Email
              _buildTextField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                isFocused: _emailFocused,
                hint: 'Email address',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                accentColor: const Color(0xFF00E5FF),
              ),

              const SizedBox(height: 14),

              // Password
              _buildTextField(
                controller: _passCtrl,
                focusNode: _passFocus,
                isFocused: _passFocused,
                hint: 'Password (min 6 characters)',
                icon: LucideIcons.lock,
                obscure: _obscurePass,
                accentColor: const Color(0xFFA855F7),
                onToggleObscure: () =>
                    setState(() => _obscurePass = !_obscurePass),
              ),

              // Password strength bar
              if (_passCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildStrengthBar(),
              ],

              const SizedBox(height: 14),

              // Confirm Password
              _buildTextField(
                controller: _confirmPassCtrl,
                focusNode: _confirmPassFocus,
                isFocused: _confirmFocused,
                hint: 'Confirm password',
                icon: LucideIcons.shieldCheck,
                obscure: _obscureConfirm,
                accentColor: const Color(0xFF3B82F6),
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 28),

              // Create Account Button
              _buildPrimaryButton(
                label: 'CREATE ACCOUNT',
                onPressed: _isLoading ? null : _handleSignup,
                isLoading: _isLoading,
                colors: const [Color(0xFFEC4899), Color(0xFFA855F7)],
              ),

              const SizedBox(height: 16),

              // Terms text
              Center(
                child: Text(
                  'By signing up you agree to our Terms of Service\nand Privacy Policy',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white24,
                    fontSize: 11,
                    height: 1.5,
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
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: filled
                    ? colors[idx]
                    : Colors.white.withValues(alpha: 0.08),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?  ',
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop();
          },
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF00E5FF)],
            ).createShader(bounds),
            child: Text(
              'Sign In',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }

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
          hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
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
            borderSide:
                BorderSide(color: accentColor.withValues(alpha: 0.6), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

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
