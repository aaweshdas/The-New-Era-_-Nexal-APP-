import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/cached_styles.dart';
import '../widgets/background/smart_background.dart';
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
import 'settings/dashboard_background_screen.dart';
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

  bool _assetsPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the global route observer only when inside a proper PageRoute
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
    // Precache nav icon assets to avoid micro-stutter on first navigation
    if (!_assetsPrecached) {
      _assetsPrecached = true;
      const navIcons = [
        'assets/nav_icons/home.png',
        'assets/nav_icons/reel.png',
        'assets/nav_icons/Camera.png',
        'assets/nav_icons/Gallery.png',
        'assets/nav_icons/Long Video.png',
        'assets/nav_icons/Message.png',
        'assets/nav_icons/map.png',
        'assets/nav_icons/notification.png',
        'assets/nav_icons/profile.png',
        'assets/nav_icons/saved_icon.png',
        'assets/nav_icons/settings.png',
      ];
      for (final path in navIcons) {
        precacheImage(AssetImage(path), context);
      }
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
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 220),
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
            child: SmartBackground(
              opacity: 0.8,
              isPaused: _isVideoPaused,
            ),
          ),

          // 2. Orbital Navigation (Visible ONLY in Galaxy mode)
          Positioned.fill(
            child: RepaintBoundary(
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
            top: 48,
            right: 10,
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
                    openSettings(context);
                  },
                ),
              ),
            ),
          ),
          // 4.5 Change Background Icon (Bottom Left)
          Positioned(
            bottom: 30,
            left: 20,
            child: AnimatedOpacity(
              opacity: _showIcons ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.purple500.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Image.asset(
                    'assets/nav_icons/Gallery.png',
                    width: 28,
                    height: 28,
                  ),
                  onPressed: () {
                    debugPrint("Navigate: DashboardBackgroundScreen");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardBackgroundScreen(),
                      ),
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
class _StarData {
  final double normX;
  final double normY;
  final int tier;
  final double baseSize;
  final double phase;
  final double speed;
  final Color color;

  const _StarData({
    required this.normX,
    required this.normY,
    required this.tier,
    required this.baseSize,
    required this.phase,
    required this.speed,
    required this.color,
  });
}

// ── Celestial Text Painter (Masks dynamic twinkling stars inside text letters) ──
class _CelestialTextPainter extends CustomPainter {
  final double animationValue;
  final String text;
  final TextStyle style;

  static final List<_StarData> _cachedStars = _generateStars();
  static final Paint _sharedFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _sharedStrokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _sharedSrcInPaint = Paint()..blendMode = BlendMode.srcIn;

  static List<_StarData> _generateStars() {
    final rng = math.Random(42);
    const starColors = [
      Color(0xFFFFFFFF), // white
      Color(0xFF22D3EE), // cyan
      Color(0xFFFDE047), // gold
      Color(0xFFC4B5FD), // lavender
      Color(0xFFF9A8D4), // pink
    ];

    final list = <_StarData>[];
    for (int i = 0; i < 90; i++) {
      final tier = rng.nextInt(3);
      final baseSize = tier == 2
          ? 1.8 + rng.nextDouble() * 0.8
          : tier == 1
              ? 1.0 + rng.nextDouble() * 0.7
              : 0.4 + rng.nextDouble() * 0.5;
      list.add(_StarData(
        normX: rng.nextDouble(),
        normY: rng.nextDouble(),
        tier: tier,
        baseSize: baseSize,
        phase: rng.nextDouble() * math.pi * 2,
        speed: 1.2 + rng.nextDouble() * 1.8,
        color: starColors[rng.nextInt(starColors.length)],
      ));
    }
    return list;
  }

  _CelestialTextPainter({
    required this.animationValue,
    required this.text,
    required this.style,
  });

  static TextPainter? _cachedMaskPainter;
  static TextPainter? _cachedOutlinePainter;
  static TextPainter? _cachedReadablePainter;
  static String? _cachedText;
  static double? _cachedWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Save outer layer for letter-mask clipping
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(rect, _sharedFillPaint);

    // 2. Draw solid white text as the clip mask
    if (_cachedMaskPainter == null || _cachedText != text || _cachedWidth != size.width) {
      _cachedText = text;
      _cachedWidth = size.width;
      
      _cachedMaskPainter = TextPainter(
        text: TextSpan(text: text, style: style.copyWith(color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);

      _cachedOutlinePainter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.8
              ..color = const Color(0xFFD4A843).withValues(alpha: 0.75),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);

      _cachedReadablePainter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(
            color: Colors.white.withValues(alpha: 0.45),
            shadows: null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
    }

    final textPainter = _cachedMaskPainter!;
    final textWidth  = textPainter.width;
    final textHeight = textPainter.height;
    final x = (size.width  - textWidth)  / 2;
    final y = (size.height - textHeight) / 2;
    textPainter.paint(canvas, Offset(x, y));

    // 3. SrcIn layer: everything painted here is clipped to the letter shapes
    canvas.saveLayer(rect, _sharedSrcInPaint);

    // 4. Deep-space base gradient (midnight → indigo → violet → royal purple)
    const baseGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF000011),
        Color(0xFF0D0030),
        Color(0xFF1A0050),
        Color(0xFF3D006E),
        Color(0xFF0D0030),
        Color(0xFF000820),
      ],
      stops: [0.0, 0.18, 0.38, 0.58, 0.80, 1.0],
    );
    _sharedFillPaint.shader = baseGrad.createShader(rect);
    canvas.drawRect(rect, _sharedFillPaint);
    _sharedFillPaint.shader = null;

    // 5. Nebula colour blobs — softer, less blur so letter edges stay sharp
    const nebulaData = [
      [0.15, 0.50, 1.4, 0xFF7B2FBE, 0.32, 8.0],
      [0.45, 0.35, 1.2, 0xFF22D3EE, 0.18, 10.0],
      [0.72, 0.60, 1.2, 0xFFA855F7, 0.25, 8.0],
      [0.30, 0.70, 0.9, 0xFFEC4899, 0.16, 9.0],
      [0.60, 0.25, 1.1, 0xFF6366F1, 0.22, 7.0],
      [0.85, 0.50, 1.0, 0xFFD4A843, 0.14, 8.0],
    ];
    for (final b in nebulaData) {
      _sharedFillPaint.color = Color(b[3] as int).withValues(alpha: b[4] as double);
      _sharedFillPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, b[5] as double);
      canvas.drawCircle(
        Offset(x + textWidth * (b[0] as double), y + textHeight * (b[1] as double)),
        textHeight * (b[2] as double),
        _sharedFillPaint,
      );
    }
    _sharedFillPaint.maskFilter = null;

    // 6. Animated golden shimmer sweep
    final sweepX = -size.width * 0.3 + animationValue * size.width * 1.6;
    const shimmerGrad = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        Color(0x1FFFFFFF),
        Color(0x33D4A843),
        Color(0x1FFFFFFF),
        Colors.transparent,
      ],
      stops: [0.0, 0.35, 0.50, 0.65, 1.0],
    );
    final shimmerRect = Rect.fromLTWH(sweepX, 0, size.width * 0.6, size.height);
    _sharedFillPaint.shader = shimmerGrad.createShader(shimmerRect);
    canvas.drawRect(shimmerRect, _sharedFillPaint);
    _sharedFillPaint.shader = null;

    // 7. Pre-generated 90 twinkling stars
    for (int i = 0; i < _cachedStars.length; i++) {
      final star = _cachedStars[i];
      final sx = star.normX * textWidth + x;
      final sy = star.normY * textHeight + y;
      final twinkle = (0.25 + 0.75 * math.sin(animationValue * math.pi * 2 * star.speed + star.phase).abs()).clamp(0.0, 1.0);

      _sharedFillPaint.color = star.color.withValues(alpha: twinkle * (star.tier == 0 ? 0.7 : 1.0));

      // Tier-2: 4-point sparkle
      if (star.tier == 2 && twinkle > 0.5) {
        final armLen = star.baseSize * 3.5;
        _sharedStrokePaint.color = star.color.withValues(alpha: twinkle * 0.55);
        _sharedStrokePaint.strokeWidth = 0.8;
        canvas.drawLine(Offset(sx - armLen, sy), Offset(sx + armLen, sy), _sharedStrokePaint);
        canvas.drawLine(Offset(sx, sy - armLen), Offset(sx, sy + armLen), _sharedStrokePaint);

        final diagLen = armLen * 0.55;
        _sharedStrokePaint.color = star.color.withValues(alpha: twinkle * 0.28);
        _sharedStrokePaint.strokeWidth = 0.5;
        canvas.drawLine(Offset(sx - diagLen, sy - diagLen), Offset(sx + diagLen, sy + diagLen), _sharedStrokePaint);
        canvas.drawLine(Offset(sx - diagLen, sy + diagLen), Offset(sx + diagLen, sy - diagLen), _sharedStrokePaint);

        _sharedFillPaint.color = star.color.withValues(alpha: twinkle * 0.18);
        _sharedFillPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(sx, sy), star.baseSize * 2.8, _sharedFillPaint);
        _sharedFillPaint.maskFilter = null;
        _sharedFillPaint.color = star.color.withValues(alpha: twinkle);
      }

      // Tier-1: soft glow halo
      if (star.tier == 1 && twinkle > 0.55) {
        _sharedFillPaint.color = star.color.withValues(alpha: twinkle * 0.22);
        _sharedFillPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(sx, sy), star.baseSize * 2.2, _sharedFillPaint);
        _sharedFillPaint.maskFilter = null;
        _sharedFillPaint.color = star.color.withValues(alpha: twinkle);
      }

      canvas.drawCircle(Offset(sx, sy), star.baseSize * (0.75 + 0.25 * twinkle), _sharedFillPaint);
    }

    // 8. Two animated shooting star streaks
    const shootDefs = [
      [0.08, 0.3, 0.55, 0.0,  0.9],
      [0.60, 0.7, 0.38, 0.5,  1.3],
    ];
    for (final s in shootDefs) {
      final progress = ((animationValue * s[4] + s[3]) % 1.0);
      final tailAlpha = (1.0 - progress) * 0.70;
      if (tailAlpha < 0.05) continue;
      final sx0 = x + textWidth  * s[0] + progress * textWidth  * s[2];
      final sy0 = y + textHeight * s[1] + progress * textHeight * 0.25;
      final tailLen = textWidth * s[2] * 0.3;
      final shootGrad = LinearGradient(colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: tailAlpha),
      ]);
      final shootRect = Rect.fromLTWH(sx0 - tailLen, sy0 - 0.5, tailLen, 1.0);
      _sharedFillPaint.shader = shootGrad.createShader(shootRect);
      canvas.drawRect(shootRect, _sharedFillPaint);
      _sharedFillPaint.shader = null;
    }

    // 9. Restore SrcIn + outer layers
    canvas.restore();
    canvas.restore();

    // 10. Crisp golden stroke outline
    _cachedOutlinePainter?.paint(canvas, Offset(x, y));

    // 11. Semi-transparent white fill
    _cachedReadablePainter?.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(_CelestialTextPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.text != text;
  }
}



