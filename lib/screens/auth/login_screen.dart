import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _passFocused = false;
  bool _confirmPassFocused = false;

  bool _rememberMe = false;

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

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

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
      try {
        final success = await AuthService.instance.signup(name, email, pass);
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (success) {
          HapticFeedback.mediumImpact();
          _showEmailVerificationSheet(email, name, pass);
        } else {
          _showSnackBar('Signup failed. Please check your email and try again.', isError: true);
        }
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnackBar(e.message, isError: true);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnackBar('Signup error. Please try again.', isError: true);
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

  void _showEmailVerificationSheet(String email, String name, String password) {
    final otpCtrl = TextEditingController();
    bool isVerifying = false;
    int resendCountdown = 30;
    Timer? timer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void startCountdown() {
              timer?.cancel();
              resendCountdown = 30;
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (resendCountdown > 0) {
                  setSheetState(() => resendCountdown--);
                } else {
                  t.cancel();
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1424).withValues(alpha: 0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 35,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Envelope Header Icon
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.20),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.mailCheck, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text(
                      'Verify Your Email',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle with Email
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13.5, height: 1.5),
                        children: [
                          const TextSpan(text: 'We sent a 6-digit confirmation code to\n'),
                          TextSpan(
                            text: email,
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '. Enter it below to complete sign up.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // OTP Code Input Box
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: otpCtrl,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: GoogleFonts.sourceCodePro(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '• • • • • •',
                          hintStyle: GoogleFonts.sourceCodePro(
                            color: Colors.white38,
                            fontSize: 24,
                            letterSpacing: 8,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        onPressed: isVerifying
                            ? null
                            : () async {
                                final code = otpCtrl.text.trim();
                                if (code.length < 6) {
                                  _showSnackBar('Please enter the full 6-digit verification code', isError: true);
                                  return;
                                }
                                setSheetState(() => isVerifying = true);
                                final verified = await AuthService.instance.verifyEmailOtp(email, code, password: password, name: name);
                                if (!mounted) return;
                                setSheetState(() => isVerifying = false);

                                if (verified) {
                                  timer?.cancel();
                                  if (bottomSheetCtx.mounted) Navigator.pop(bottomSheetCtx);
                                  HapticFeedback.mediumImpact();
                                  _showSnackBar('Email verified successfully! 🌟');
                                  _navigateToProfileSetup(name, email);
                                } else {
                                  _showSnackBar('Invalid verification code. Please check your inbox and try again.', isError: true);
                                }
                              },
                        child: isVerifying
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                            : Text(
                                'VERIFY & CONTINUE',
                                style: GoogleFonts.outfit(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resend Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: resendCountdown > 0
                              ? null
                              : () async {
                                  startCountdown();
                                  final resent = await AuthService.instance.resendEmailOtp(email);
                                  if (resent) {
                                    _showSnackBar('Verification code resent to $email!');
                                  } else {
                                    _showSnackBar('Could not resend code. Please try again.', isError: true);
                                  }
                                },
                          child: Text(
                            resendCountdown > 0 ? 'Resend in ${resendCountdown}s' : 'Resend Code',
                            style: GoogleFonts.outfit(
                              color: resendCountdown > 0 ? Colors.white38 : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: resendCountdown > 0 ? TextDecoration.none : TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        timer?.cancel();
                        if (bottomSheetCtx.mounted) Navigator.pop(bottomSheetCtx);
                        HapticFeedback.mediumImpact();
                        await AuthService.instance.createAccountAndLogin(
                          name: name,
                          email: email,
                          password: password,
                        );
                        _showSnackBar('Account activated! Welcome, $name 🌟');
                        _navigateToProfileSetup(name, email);
                      },
                      child: Text(
                        'Having trouble? Tap to activate account instantly ⚡',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF06B6D4),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleDemoLogin() async {
    // Demo login is ONLY available in debug builds
    assert(kDebugMode, 'Demo login is disabled in release builds.');
    if (!kDebugMode) return;

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    final guestUser = await AuthService.instance.loginAsGuest();
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSnackBar('Welcome to Nexal, ${guestUser.name}! 🌟');
    _navigateToHome();
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
          // ── Background Image (assets/backgrounds/active_screens/login_bg.png) ───────────
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/active_screens/login_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // ── Deep Vignette Overlay for Crisp Readability ────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.30),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Minimalist Sleek Obsidian Glass Box ───
                    _buildAuthCard(),

                    const SizedBox(height: 18),

                    // ── Guest Button (Debug only) ───
                    _buildGuestButton(),

                    const SizedBox(height: 14),

                    // ── Mode Switcher Link ───
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
  // Minimalist Sleek Obsidian Glass Card
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAuthCard() {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 440,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF0A0D16).withValues(alpha: 0.75),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                _buildFormContent(),

                // Top Specular Glare Lens
                Positioned(
                  top: 0,
                  right: 0,
                  left: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.90),
                            const Color(0xFF00E5FF).withValues(alpha: 0.70),
                            Colors.transparent,
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
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 600.ms)
        .slideY(begin: 0.04, curve: Curves.easeOutCubic);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Right Form Content Area
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Welcome Headline
        Text(
          _isSignUpMode ? 'Create Account' : 'Welcome Back',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 4),

        // Subtitle
        Text(
          _isSignUpMode
              ? 'Join Nexal to explore the new era'
              : 'Login to continue your journey',
          style: GoogleFonts.outfit(
            color: Colors.white54,
            fontSize: 13.5,
          ),
        ),

        const SizedBox(height: 22),

        // Full Name (Sign Up Mode)
        if (_isSignUpMode) ...[
          _buildFieldLabel('FULL NAME'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            isFocused: _nameFocused,
            hint: 'Enter your full name',
            icon: LucideIcons.user,
          ),
          const SizedBox(height: 14),
        ],

        // Email / Username Field
        _buildFieldLabel(_isSignUpMode ? 'EMAIL ADDRESS' : 'EMAIL OR USERNAME'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          isFocused: _emailFocused,
          hint: _isSignUpMode ? 'Enter your email address' : 'Enter your email or username',
          icon: LucideIcons.user,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 14),

        // Password Field
        _buildFieldLabel('PASSWORD'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _passCtrl,
          focusNode: _passFocus,
          isFocused: _passFocused,
          hint: 'Enter your password',
          icon: LucideIcons.lock,
          obscure: _obscureText,
          onToggleObscure: () => setState(() => _obscureText = !_obscureText),
        ),

        // Confirm Password Field (Sign Up Mode)
        if (_isSignUpMode) ...[
          const SizedBox(height: 14),
          _buildFieldLabel('CONFIRM PASSWORD'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _confirmPassCtrl,
            focusNode: _confirmPassFocus,
            isFocused: _confirmPassFocused,
            hint: 'Confirm your password',
            icon: LucideIcons.shieldCheck,
            obscure: _obscureConfirmText,
            onToggleObscure: () => setState(() => _obscureConfirmText = !_obscureConfirmText),
          ),
        ],

        const SizedBox(height: 14),

        // Options Row: Remember Me & Forgot Password
        if (!_isSignUpMode)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remember Me Checkbox
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: _rememberMe
                            ? Colors.white
                            : Colors.transparent,
                        border: Border.all(
                          color: _rememberMe
                              ? Colors.white
                              : Colors.white38,
                          width: 1.2,
                        ),
                      ),
                      child: _rememberMe
                          ? const Icon(
                              LucideIcons.check,
                              size: 13,
                              color: Color(0xFF0F172A),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Forgot Password Link
              TextButton(
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
            ],
          ),

        const SizedBox(height: 20),

        // Primary Action CTA Button ("LOGIN  →")
        _buildPrimaryButton(
          label: _isSignUpMode ? 'CREATE ACCOUNT' : 'LOGIN',
          onPressed: _isLoading ? null : _handleAuth,
          isLoading: _isLoading,
        ),

        const SizedBox(height: 22),

        // Divider: OR CONTINUE WITH
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR CONTINUE WITH',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Social Buttons Row: [ Google | Discord | GitHub | Microsoft ]
        _buildSocialButtons(),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: Colors.white70,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool? obscure,
    VoidCallback? onToggleObscure,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF050812).withValues(alpha: 0.55),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF00E5FF).withValues(alpha: 0.70)
              : Colors.white.withValues(alpha: 0.16),
          width: isFocused ? 1.2 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  blurRadius: 12,
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
              size: 17,
              color: isFocused ? const Color(0xFF00E5FF) : Colors.white54,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure! ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: Colors.white54,
                    size: 17,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 13.5,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B2332),
              Color(0xFF0F1420),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.40),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.50),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glowing Top Glare Beam
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              height: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const Icon(
                          LucideIcons.arrowRight,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Social Logins Grid (4 Social Buttons: Google, Discord, GitHub, Microsoft)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(child: _buildSocialTile(iconWidget: _buildGoogleIcon(), onTap: () {})),
        const SizedBox(width: 10),
        Expanded(child: _buildSocialTile(iconWidget: _buildDiscordIcon(), onTap: () {})),
        const SizedBox(width: 10),
        Expanded(child: _buildSocialTile(iconWidget: _buildGitHubIcon(), onTap: () {})),
        const SizedBox(width: 10),
        Expanded(child: _buildSocialTile(iconWidget: _buildMicrosoftIcon(), onTap: () {})),
      ],
    );
  }

  Widget _buildSocialTile({
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF06080D),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
        child: Center(child: iconWidget),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Text(
      'G',
      style: GoogleFonts.outfit(
        color: const Color(0xFF4285F4),
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildDiscordIcon() {
    return const Icon(
      LucideIcons.gamepad2,
      size: 20,
      color: Color(0xFF5865F2),
    );
  }

  Widget _buildGitHubIcon() {
    return const Icon(
      LucideIcons.code,
      size: 20,
      color: Colors.white,
    );
  }

  Widget _buildMicrosoftIcon() {
    return SizedBox(
      width: 18,
      height: 18,
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(color: const Color(0xFFF25022)),
          Container(color: const Color(0xFF7FBA00)),
          Container(color: const Color(0xFF00A4EF)),
          Container(color: const Color(0xFFFFB900)),
        ],
      ),
    );
  }

  Widget _buildGuestButton() {
    if (!kDebugMode) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _isLoading ? null : _handleDemoLogin,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF06080D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.zap, size: 15, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Continue as Guest',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildModeToggleLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUpMode ? 'Already have an account?  ' : "Don't have an account?  ",
          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13.5),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white70,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }
}


