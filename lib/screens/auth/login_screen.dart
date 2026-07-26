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

    final success = await AuthService.instance.loginWithGoogle();
    if (!mounted) return;

    // Check if user is already logged in (native ID token flow)
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

    // Subscribe to auth state changes for browser OAuth redirect flow
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

    // Safety timeout
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
          // ── Full-Screen Background Image (assets/login BG.png) ───────────
          Positioned.fill(
            child: Image.asset(
              'assets/login BG.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // ── Subtle dark vignette overlay for optimal contrast ─────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.45),
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
        // Liquid glass orb logo container
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA855F7).withValues(alpha: 0.50),
                blurRadius: 36,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                blurRadius: 50,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gel blur backing
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          const Color(0xFFA855F7).withValues(alpha: 0.20),
                          const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.65),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/nexal_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Upper specular liquid highlight lens
              Positioned(
                top: 2,
                left: 12,
                right: 12,
                height: 38,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut, duration: 900.ms),

        const SizedBox(height: 18),

        // Brand Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFD8B4FE), Color(0xFF67E8F9)],
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
          'Liquid Glass Quantum Portal',
          style: GoogleFonts.outfit(
            color: const Color(0xFF67E8F9).withValues(alpha: 0.75),
            fontSize: 12,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3D Liquid Glass Panel Container
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
            blurRadius: 50,
            spreadRadius: 1,
            offset: const Offset(-6, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Stack(
            children: [
              // Liquid Gel Gradient Fill
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(38),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      const Color(0xFF311B92).withValues(alpha: 0.25),
                      const Color(0xFF0D47A1).withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                    stops: const [0.0, 0.35, 0.70, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.6,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Glowing Gel Dot Indicator
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E5FF),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sign In',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Text(
                        'Welcome to the liquid glass era',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
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

                    const SizedBox(height: 18),

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

                    const SizedBox(height: 12),

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
                            color: const Color(0xFF67E8F9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // 3D Liquid Gem Login Button
                    _buildPrimaryButton(
                      label: 'LOGIN',
                      onPressed: _isLoading ? null : _handleLogin,
                      isLoading: _isLoading,
                      colors: const [Color(0xFFA855F7), Color(0xFF3B82F6), Color(0xFF00E5FF)],
                    ),
                  ],
                ),
              ),

              // Upper Specular Gel Lens Arc (Top Glass Specular Highlight)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 70,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
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

  // ──────────────────────────────────────────────────────────────────────────
  // Liquid Glass Pill Buttons
  // ──────────────────────────────────────────────────────────────────────────
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
              color: Colors.white.withValues(alpha: busy ? 0.06 : 0.14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.50),
                width: 1.4,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
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
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'G',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF4285F4),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                // Top Gloss Reflection Highlight
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
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.zap, size: 16, color: Color(0xFF67E8F9)),
                const SizedBox(width: 8),
                Text(
                  'Continue as Guest',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
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

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?  ",
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
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
              colors: [Color(0xFF67E8F9), Color(0xFFD8B4FE)],
            ).createShader(bounds),
            child: Text(
              'Sign Up',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Liquid Bubble TextField Pill
  // ──────────────────────────────────────────────────────────────────────────
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isFocused
                ? accentColor.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: isFocused
                  ? accentColor.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.40),
              width: isFocused ? 1.8 : 1.2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 20,
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
                      color: isFocused ? accentColor : Colors.white70,
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
              // Top Glass Specular Arc Highlight
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
  // 3D Liquid Gem CTA Button
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    required List<Color> colors,
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
                  ? LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF2D2D3A), Color(0xFF1A1A28)],
                    ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1.5,
              ),
              boxShadow: onPressed != null
                  ? [
                      BoxShadow(
                        color: colors.first.withValues(alpha: 0.50),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: colors.last.withValues(alpha: 0.35),
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
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          label,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                          ),
                        ),
                ),
                // Top Gloss Gel Specular Arc
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
                          Colors.white.withValues(alpha: 0.50),
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
