import 'package:flutter/material.dart';
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
    await AuthService.instance.init();
    final onboardingDone = await AuthService.instance.isOnboardingComplete();
    final isLoggedIn = AuthService.instance.isLoggedIn;

    // Small delay to let splash animation settle
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;

    Widget nextScreen;
    if (!onboardingDone) {
      nextScreen = const OnboardingScreen();
    } else if (!isLoggedIn) {
      nextScreen = const LoginScreen();
    } else {
      nextScreen = const HomeScreen();
    }

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

  @override
  Widget build(BuildContext context) {
    return const SplashVideoScreen();
  }
}
