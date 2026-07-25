import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
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

    if (!mounted) return;

    // ── Routing logic ────────────────────────────────────────────────────────
    // ALWAYS check the live Supabase session to decide auth state.
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    final bool hasValidSession = session != null &&
        !_isSessionExpired(session);

    // Direct routing: No slides, no onboarding delay, no video player before login
    final Widget nextScreen = hasValidSession ? const HomeScreen() : const LoginScreen();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  /// Returns true if the session's access token has expired.
  bool _isSessionExpired(Session session) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return DateTime.now().isAfter(expiry);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF060913),
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF7C3AED),
          ),
        ),
      ),
    );
  }
}
