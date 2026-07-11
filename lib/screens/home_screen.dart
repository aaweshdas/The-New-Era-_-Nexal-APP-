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
    // A sub-screen was pushed over the home screen — pause the video
    if (!_isVideoPaused) {
      setState(() => _isVideoPaused = true);
    }
  }

  @override
  void didPopNext() {
    // The sub-screen was popped — resume the video
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
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: const [
                                Color(0xFFD4A843),  // Gold
                                Color(0xFFC084FC),  // Purple
                                Color(0xFF22D3EE),  // Cyan
                                Color(0xFFEC4899),  // Pink
                                Color(0xFFD4A843),  // Gold again
                              ],
                              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                              begin: Alignment(-2.0 + 4.0 * _shimmerCtrl.value, 0),
                              end: Alignment(-1.0 + 4.0 * _shimmerCtrl.value, 0),
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            "NEXAL GALAXY",
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

