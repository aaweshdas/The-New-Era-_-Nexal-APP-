import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Quantum Arc Navigation',
      'subtitle': 'Explore the cosmos of Nexal with orbital gesture controls and 3D parallax effects.',
      'icon': 'sparkles',
      'image': 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=800',
    },
    {
      'title': 'Aria AI Companion',
      'subtitle': 'Your real-time neural intelligence assistant powered by next-gen language models.',
      'icon': 'cpu',
      'image': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
    },
    {
      'title': 'Immersive Memory Vault',
      'subtitle': 'Store your digital footprint across timeline galleries and deep space visual domes.',
      'icon': 'globe',
      'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
    },
  ];

  void _finishOnboarding() async {
    await AuthService.instance.setOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D0015), Colors.black, Color(0xFF000A14)],
                ),
              ),
            ),
          ),

          // Slides PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Image Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        height: 320,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF135BEC).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              slide['image']!,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.85),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                    const SizedBox(height: 40),

                    // Title
                    Text(
                      slide['title']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rye(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 14),

                    // Subtitle
                    Text(
                      slide['subtitle']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              );
            },
          ),

          // Top Skip Button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                'SKIP',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // Bottom Controls (Dots & Button)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Indicator Dots
                Row(
                  children: List.generate(
                    _slides.length,
                    (idx) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      width: _currentPage == idx ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == idx
                            ? const Color(0xFF00E5FF)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Next / Get Started Button
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135BEC).withValues(alpha: 0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finishOnboarding();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _slides.length - 1
                                ? 'GET STARTED'
                                : 'NEXT',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.arrowRight, size: 16),
                        ],
                      ),
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
}
