import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/cached_styles.dart';
import '../widgets/background/video_background.dart';
import '../widgets/effects/gyro_parallax.dart';
import '../widgets/navigation/quantum_arc_menu.dart';
import '../widgets/settings/settings_modal.dart';
import '../widgets/notifications/notification_view.dart';
import 'home_view.dart';
import 'feels_view.dart';
import 'profile_view.dart';
import 'messages_view.dart';
import 'video_view.dart';
import 'camera_view.dart';
import 'search_view.dart';
import 'ai_assist_view.dart';
import 'gallery_view.dart';
import 'open_world_games_view.dart';
import 'map_view.dart';
import '../main.dart'; // Import to access routeObserver
import '../services/map_video_preloader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware, TickerProviderStateMixin {
  bool _isVideoPaused = false;
  late AnimationController _shimmerCtrl;
  bool _showIcons = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Trigger one-shot fade in of icons after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _showIcons = true;
        });
      }
      // Pre-warm the map loading video codec in the background
      // so it plays with ZERO delay the moment the user opens Maps.
      MapVideoPreloader.instance.preload();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the global route observer only when inside a proper PageRoute
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    // A sub-screen was pushed over the home screen â€” pause the video
    if (!_isVideoPaused) {
      setState(() => _isVideoPaused = true);
    }
  }

  @override
  void didPopNext() {
    // The sub-screen was popped â€” resume the video
    if (_isVideoPaused) {
      setState(() => _isVideoPaused = false);
    }
  }

  void _navigateToDestination(String tab) {
    Widget destination;
    switch (tab) {
      case 'home':
        destination = const HomeView();
        break;
      case 'feels':
        destination = const FeelsView();
        break;
      case 'profile':
        destination = const ProfileView();
        break;
      case 'messages':
        destination = const MessagesView();
        break;
      case 'video':
        destination = const VideoView();
        break;
      case 'camera':
        destination = const CameraView();
        break;
      case 'search':
        destination = const SearchView();
        break;
      case 'ai':
        destination = const AIAssistView();
        break;
      case 'gallery':
        destination = const GalleryView();
        break;
      case 'arcade':
        destination = const OpenWorldGamesView();
        break;
      case 'maps':
        destination = const MapView();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Map gets a premium slide-up + fade. All other screens get a plain fade.
          if (tab == 'maps') {
            final slide = Tween<Offset>(
              begin: const Offset(0.0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.16, 1.0, 0.3, 1.0), // iOS spring-like
            ));
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: SlideTransition(position: slide, child: child),
            );
          }
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Animated Video Background
          Positioned.fill(
            child: VideoBackground(
              opacity: 0.8, // Slightly dimmed for better content contrast
              isPaused: _isVideoPaused,
            ),
          ),

          // 2. Orbital Navigation (Visible ONLY in Galaxy mode)
          Positioned.fill(
            child: GyroParallax(
              intensity: 1.5,
              child: Center(
                child: QuantumArcMenu(
                  activeTab: 'galaxy', // Always 'galaxy' when visible
                  onTabChange: (tab) {
                    debugPrint("Navigate: $tab");
                    _navigateToDestination(tab);
                  },
                  onCameraOpen: () {
                    debugPrint("Navigate: camera");
                    _navigateToDestination('camera');
                  },
                  onSearchOpen: () {
                    debugPrint("Navigate: search");
                    _navigateToDestination('search');
                  },
                ),
              ),
            ),
          ),

          // 3. Header/Logo
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(360, 48),
                          painter: _CelestialTextPainter(
                            animationValue: _shimmerCtrl.value,
                            text: "NEXAL GALAXY",
                            style: CachedStyles.ryeBoldSize32L4White.copyWith(
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFD4A843).withValues(alpha: 0.5),
                                  blurRadius: 16,
                                ),
                                Shadow(
                                  color: const Color(0xFFC084FC).withValues(alpha: 0.3),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a star to explore",
                    style: CachedStyles.outfitW400Size14L1White54,
                  ),
                ],
              ),
            ),
          ),

          // 4. Notification Icon (Top Right)
          Positioned(
            top: 80, // Moved down slightly
            right: 20,
            child: AnimatedOpacity(
              opacity: _showIcons ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cyan500.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Image.asset(
                    'assets/nav_icons/notification.png',
                    width: 28,
                    height: 28,
                  ),
                  onPressed: () {
                    debugPrint("Navigate: Notifications");
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const NotificationView(),
                    );
                  },
                ),
              ),
            ),
          ),

          // 5. Settings Icon (Bottom Right)
          Positioned(
            bottom: 30,
            right: 20,
            child: AnimatedOpacity(
              opacity: _showIcons ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cyan500.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Image.asset(
                    'assets/nav_icons/settings.png',
                    width: 28,
                    height: 28,
                  ),
                  onPressed: () {
                    debugPrint("Navigate: Settings");
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const SettingsModal(),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Celestial Text Painter (Masks dynamic twinkling stars inside text letters) ──
class _CelestialTextPainter extends CustomPainter {
  final double animationValue;
  final String text;
  final TextStyle style;

  _CelestialTextPainter({
    required this.animationValue,
    required this.text,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Save layer for masking
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 2. Draw text as the source mask (solid white)
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    // Center the text horizontally and vertically in the box
    final textWidth = textPainter.width;
    final textHeight = textPainter.height;
    final x = (size.width - textWidth) / 2;
    final y = (size.height - textHeight) / 2;
    textPainter.paint(canvas, Offset(x, y));

    // 3. Set blend mode to SrcIn so next drawings clip exactly to the text letters
    final maskPaint = Paint()..blendMode = BlendMode.srcIn;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), maskPaint);

    // 4. Draw the celestial space background (indigo-violet-magenta space nebula gradient)
    final spaceRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Create space nebula gradient
    final spaceGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF03001e), // deep space black-purple
        Color(0xFF7303c0), // nebula magenta
        Color(0xFFec38bc), // hot nebula pink
        Color(0xFF03001e), // dark blue
      ],
      stops: const [0.0, 0.45, 0.75, 1.0],
    );
    canvas.drawRect(spaceRect, Paint()..shader = spaceGradient.createShader(spaceRect));

    // Draw additional deep space color spots
    canvas.drawCircle(
      Offset(x + textWidth * 0.2, y + textHeight * 0.5),
      textHeight * 1.5,
      Paint()
        ..color = const Color(0xFF22D3EE).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    canvas.drawCircle(
      Offset(x + textWidth * 0.7, y + textHeight * 0.3),
      textHeight * 1.8,
      Paint()
        ..color = const Color(0xFFC084FC).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // 5. Draw dynamic twinkling stars inside the letters!
    final rng = math.Random(108); // Seeded random for consistent star placements
    final starPaint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < 45; i++) {
      // Place stars within text bounding box coordinates
      final sx = rng.nextDouble() * textWidth + x;
      final sy = rng.nextDouble() * textHeight + y;
      final baseSize = rng.nextDouble() * 2.2 + 0.6;
      
      // Compute twinkle sine wave
      final phase = rng.nextDouble() * math.pi * 2;
      final twinkle = 0.2 + 0.8 * math.sin(animationValue * math.pi * 2 + phase).abs();
      
      // Star Color (white, electric cyan, golden yellow)
      Color starColor = Colors.white;
      final colorType = rng.nextInt(3);
      if (colorType == 1) {
        starColor = const Color(0xFF22D3EE); // Cyan
      } else if (colorType == 2) {
        starColor = const Color(0xFFFDE047); // Gold
      }
      
      starPaint.color = starColor.withValues(alpha: twinkle);
      
      // Draw cross-hair/glow for bright twinkling stars
      if (baseSize > 1.8 && twinkle > 0.65) {
        final glowPaint = Paint()
          ..color = starColor.withValues(alpha: twinkle * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawLine(Offset(sx - 4, sy), Offset(sx + 4, sy), glowPaint);
        canvas.drawLine(Offset(sx, sy - 4), Offset(sx, sy + 4), glowPaint);
      }
      
      canvas.drawCircle(Offset(sx, sy), baseSize * (0.8 + 0.2 * twinkle), starPaint);
    }

    // 6. Restore layers
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CelestialTextPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.text != text;
  }
}

