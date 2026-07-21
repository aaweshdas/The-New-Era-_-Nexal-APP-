import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'screens/auth/splash_router.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/user_provider.dart';
import 'providers/notifications_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
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
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
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
