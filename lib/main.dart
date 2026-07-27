import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'screens/auth/splash_router.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/user_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/background_provider.dart';
import 'services/socket_service.dart';

import 'services/supabase_service.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Ultra-Smooth Performance: Expand Image Cache & prevent rendering jank
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100 MB cache limit
  PaintingBinding.instance.imageCache.maximumSize = 200;

  // 🌐 Resolve active backend Gateway URL (Render Cloud -> Saved -> Local)
  await AppConfig.resolveGatewayUrl();

  await SupabaseService.initialize();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 🖥️ Full-screen edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 🛡️ Global Error Boundary
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[Nexal Global Error] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Nexal Async Error] $error\n$stack');
    return true;
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const NexalApp());
}

// Global route observer for managing background video state
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class NexalApp extends StatelessWidget {
  const NexalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) {
          final mp = MessagesProvider();
          return mp;
        }),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) {
          final p = BackgroundProvider();
          p.load(); // load persisted background on startup
          return p;
        }),
        // Wire AuthProvider changes → connect Socket.IO
        ChangeNotifierProxyProvider<AuthProvider, MessagesProvider>(
          create: (_) => MessagesProvider(),
          update: (ctx, auth, prev) {
            if (auth.user != null) {
              SocketService.instance.connect(auth.user!.uid);
            }
            return prev ?? MessagesProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'Nexal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorObservers: [routeObserver],
        home: const SplashRouter(),
      ),
    );
  }
}
