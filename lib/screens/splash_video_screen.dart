import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';


class SplashVideoScreen extends StatefulWidget {
  const SplashVideoScreen({super.key});

  @override
  State<SplashVideoScreen> createState() => _SplashVideoScreenState();
}

class _SplashVideoScreenState extends State<SplashVideoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();

    // Force full-screen immersive mode for the splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Progress animation — purely visual, routing is handled by SplashRouter
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/starting_screen.png'), context);
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020105), // Pitch black background
      body: Stack(
        children: [
          // Background starting screen image
          Positioned.fill(
            child: Image.asset(
              'assets/starting_screen.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Custom Loading Bar and Percentage overlaid below "L O A D I N G" text
          Align(
            alignment: const Alignment(0, 0.52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: AnimatedBuilder(
                animation: _progressCtrl,
                builder: (context, _) {
                  final progress = _progressCtrl.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing golden progress bar matching the reference image
                      SizedBox(
                        width: 240,
                        height: 12,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final progressWidth = width * progress;
                            return Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.centerLeft,
                              children: [
                                // Background Track
                                Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: const Color(0x12FFA000), // Translucent gold track
                                    borderRadius: BorderRadius.circular(2.5),
                                    border: Border.all(
                                      color: const Color(0x28FFA000), // Dark gold border
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                // Glowing Progress Fill
                                if (progress > 0)
                                  Container(
                                    width: progressWidth,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFCC8F2B),
                                          Color(0xFFFFD56B),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF9E00).withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1.5,
                                        ),
                                      ],
                                    ),
                                  ),
                                // Glowing lens-flare style tip on the progress front
                                if (progress > 0)
                                  Positioned(
                                    left: progressWidth - 6,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFFFFF1C4),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                          BoxShadow(
                                            color: Color(0xFFFF9E00),
                                            blurRadius: 12,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Gold styled spaced-out percentage e.g., "7 6 %"
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFFD56B), // Golden text color
                          letterSpacing: 10.0, // Wide letter spacing for "7 6 %" visual
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFF9E00).withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
