import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  final String uid;
  final String name;
  final String email;
  final String username;
  final String avatarUrl;

  UserSession({
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
    required this.avatarUrl,
  });
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  UserSession? _currentUser;
  UserSession? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  final StreamController<UserSession?> _authStateController =
      StreamController<UserSession?>.broadcast();
  Stream<UserSession?> get authStateChanges => _authStateController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    if (loggedIn) {
      _currentUser = UserSession(
        uid: prefs.getString('user_uid') ?? 'user_101',
        name: prefs.getString('profileName') ?? 'Neural Nexus',
        email: prefs.getString('user_email') ?? 'nexus@nexal.space',
        username: prefs.getString('user_username') ?? 'neuralnexus',
        avatarUrl: prefs.getString('user_avatar') ??
            'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200',
      );
    }
    _authStateController.add(_currentUser);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final prefs = await SharedPreferences.getInstance();
    _currentUser = UserSession(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first,
      email: email,
      username: email.split('@').first.toLowerCase(),
      avatarUrl:
          'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200',
    );
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_uid', _currentUser!.uid);
    await prefs.setString('profileName', _currentUser!.name);
    await prefs.setString('user_email', _currentUser!.email);
    await prefs.setString('user_username', _currentUser!.username);
    await prefs.setString('user_avatar', _currentUser!.avatarUrl);

    _authStateController.add(_currentUser);
    return true;
  }

  Future<bool> signup(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final prefs = await SharedPreferences.getInstance();
    _currentUser = UserSession(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      username: name.replaceAll(' ', '').toLowerCase(),
      avatarUrl:
          'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200',
    );
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_uid', _currentUser!.uid);
    await prefs.setString('profileName', _currentUser!.name);
    await prefs.setString('user_email', _currentUser!.email);
    await prefs.setString('user_username', _currentUser!.username);
    await prefs.setString('user_avatar', _currentUser!.avatarUrl);

    _authStateController.add(_currentUser);
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    _currentUser = null;
    _authStateController.add(null);
  }
}
