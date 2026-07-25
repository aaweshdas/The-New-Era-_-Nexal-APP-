import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // ── Check real Supabase session first ──────────────────────────────────
    final supaSession = _supabase.auth.currentSession;
    final supaUser = _supabase.auth.currentUser;

    // Check that session exists AND is not expired
    final bool sessionValid = supaSession != null &&
        supaUser != null &&
        _isSessionValid(supaSession);

    if (sessionValid) {
      // Valid, non-expired Supabase session → build UserSession from it
      final meta = supaUser.userMetadata ?? {};
      _currentUser = UserSession(
        uid: supaUser.id,
        name: (meta['full_name'] ?? meta['name'] ??
            supaUser.email?.split('@').first ?? 'Nexal User') as String,
        email: supaUser.email ?? '',
        username: (meta['user_name'] ??
            supaUser.email!.split('@').first.toLowerCase()) as String,
        avatarUrl: (meta['avatar_url'] ?? meta['picture'] ??
            'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200') as String,
      );
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_uid', _currentUser!.uid);
      await prefs.setString('profileName', _currentUser!.name);
      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_username', _currentUser!.username);
      await prefs.setString('user_avatar', _currentUser!.avatarUrl);
    } else {
      // No valid / expired session → always clear local flag → login shown
      await prefs.setBool('is_logged_in', false);
      _currentUser = null;
    }

    _authStateController.add(_currentUser);

    // Listen for Supabase auth state changes (token refresh, sign-out, OAuth callback)
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        final u = session.user;
        final meta = u.userMetadata ?? {};
        _currentUser = UserSession(
          uid: u.id,
          name: (meta['full_name'] ?? meta['name'] ?? u.email?.split('@').first ?? 'Nexal User') as String,
          email: u.email ?? '',
          username: (meta['user_name'] ?? u.email!.split('@').first.toLowerCase()) as String,
          avatarUrl: (meta['avatar_url'] ?? meta['picture'] ??
              'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200') as String,
        );
        final p = await SharedPreferences.getInstance();
        await p.setBool('is_logged_in', true);
        await p.setString('user_uid', _currentUser!.uid);
        await p.setString('profileName', _currentUser!.name);
        await p.setString('user_email', _currentUser!.email);
        await p.setString('user_username', _currentUser!.username);
        await p.setString('user_avatar', _currentUser!.avatarUrl);
        _authStateController.add(_currentUser);
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        final p = await SharedPreferences.getInstance();
        await p.setBool('is_logged_in', false);
        _authStateController.add(null);
      }
    });
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  /// Returns true if the Supabase session token has NOT expired.
  bool _isSessionValid(Session session) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    // expiresAt is Unix timestamp in seconds
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return DateTime.now().isBefore(expiry);
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  // ── Email / Password Login ──────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session != null) return true;
      return false;
    } on AuthException {
      // Fallback: allow demo guest login
      if (email == 'guest@nexal.space') {
        return _createLocalSession(email);
      }
      return false;
    } catch (_) {
      if (email == 'guest@nexal.space') {
        return _createLocalSession(email);
      }
      return false;
    }
  }

  Future<bool> _createLocalSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = UserSession(
      uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Guest Explorer',
      email: email,
      username: 'guest_explorer',
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

  static const String googleClientId = '851929744766-b1fadinn47jjmu1mhap34knlc9h0i2tu.apps.googleusercontent.com';

  // ── Google OAuth / Native Sign-In ─────────────────────────────────────────
  Future<bool> loginWithGoogle() async {
    // 1. Try native Google Sign-In with configured Client ID
    try {
      final googleSignIn = GoogleSignIn(
        clientId: googleClientId,
        serverClientId: googleClientId,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User explicitly cancelled the Google prompt
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken != null) {
        final res = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
        if (res.session != null) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Native Google Sign-In not supported or error: $e. Using Supabase OAuth fallback...');
    }

    // 2. Fallback to Supabase OAuth browser flow (Desktop / Web / Unsupported native)
    try {
      final res = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.nexal.app://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return res;
    } catch (err) {
      debugPrint('[AuthService] Google OAuth fallback failed: $err');
      return false;
    }
  }

  // ── Signup ────────────────────────────────────────────────────────────────
  Future<bool> signup(String name, String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'user_name': name.replaceAll(' ', '').toLowerCase(),
        },
      );
      if (response.user != null) return true;
      return false;
    } on AuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    _currentUser = null;
    _authStateController.add(null);
  }
}
