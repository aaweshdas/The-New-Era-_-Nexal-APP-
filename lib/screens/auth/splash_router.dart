import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../splash_video_screen.dart';
import '../home_screen.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    // Initialize auth service (checks Supabase session)
    await AuthService.instance.init();

    // Small delay to let splash animation settle
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;

    // ── Routing logic ────────────────────────────────────────────────────────
    // ALWAYS check the live Supabase session to decide auth state.
    // Never rely solely on SharedPreferences — it can be stale.
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    final bool hasValidSession = session != null &&
        !_isSessionExpired(session);

    final onboardingDone = await AuthService.instance.isOnboardingComplete();

    Widget nextScreen;
    if (!onboardingDone) {
      nextScreen = const OnboardingScreen();
    } else if (!hasValidSession) {
      // No valid session → always show login
      nextScreen = const LoginScreen();
    } else {
      nextScreen = const HomeScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  /// Returns true if the session's access token has expired.
  bool _isSessionExpired(Session session) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true;
    // expiresAt is in seconds since epoch
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return DateTime.now().isAfter(expiry);
  }

  @override
  Widget build(BuildContext context) {
    return const SplashVideoScreen();
  }
}
