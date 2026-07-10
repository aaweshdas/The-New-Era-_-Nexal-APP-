import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_video_screen.dart';

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
    return MaterialApp(
      title: 'Nexal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorObservers: [routeObserver],
      home: const SplashVideoScreen(),
    );
  }
}
