import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
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
  final String bio;

  String get handle => username;

  UserSession({
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
    required this.avatarUrl,
    this.bio = '',
  });

  UserSession copyWith({
    String? name,
    String? username,
    String? avatarUrl,
    String? bio,
  }) {
    return UserSession(
      uid: uid,
      name: name ?? this.name,
      email: email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }
}

enum GoogleAuthStatus {
  success,
  cancelled,
  pendingBrowserOAuth,
  error,
}

class GoogleAuthResult {
  final GoogleAuthStatus status;
  final String? message;
  final UserSession? user;

  const GoogleAuthResult({
    required this.status,
    this.message,
    this.user,
  });

  factory GoogleAuthResult.success(UserSession user) =>
      GoogleAuthResult(status: GoogleAuthStatus.success, user: user);

  factory GoogleAuthResult.cancelled() =>
      const GoogleAuthResult(status: GoogleAuthStatus.cancelled, message: 'Google Sign-In was cancelled.');

  factory GoogleAuthResult.pendingBrowserOAuth() =>
      const GoogleAuthResult(status: GoogleAuthStatus.pendingBrowserOAuth, message: 'OAuth launched in browser. Awaiting authentication response...');

  factory GoogleAuthResult.error(String message) =>
      GoogleAuthResult(status: GoogleAuthStatus.error, message: message);
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  void updateProfile({String? name, String? handle, String? avatarUrl, String? bio}) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        username: handle,
        avatarUrl: avatarUrl,
        bio: bio,
      );
      _authStateController.add(_currentUser);
    }
  }

  UserSession? _currentUser;
  UserSession? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  final StreamController<UserSession?> _authStateController =
      StreamController<UserSession?>.broadcast();
  Stream<UserSession?> get authStateChanges => _authStateController.stream;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> init() async {
    await _registerWindowsProtocol();
    _initDeepLinks();
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

  Future<void> _registerWindowsProtocol() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      final exePath = Platform.resolvedExecutable;
      const regPath = r'HKCU\Software\Classes\io.nexal.app';
      await Process.run('reg', ['add', regPath, '/ve', '/d', 'URL:Nexal App Protocol', '/f']);
      await Process.run('reg', ['add', regPath, '/v', 'URL Protocol', '/d', '', '/f']);
      await Process.run('reg', ['add', '$regPath\\shell\\open\\command', '/ve', '/d', '"$exePath" "%1"', '/f']);
      debugPrint('[AuthService] Windows protocol io.nexal.app:// registered successfully to $exePath');
    } catch (e) {
      debugPrint('[AuthService] Windows protocol registration notice: $e');
    }
  }

  Future<UserSession> _buildSessionFromSupabaseUser(User u) async {
    final meta = u.userMetadata ?? {};
    final email = u.email ?? '';
    final name = (meta['full_name'] ?? meta['name'] ?? (email.isNotEmpty ? email.split('@').first : 'Nexal User')) as String;
    final username = (meta['user_name'] ?? (email.isNotEmpty ? email.split('@').first.toLowerCase() : 'user')) as String;
    final avatar = (meta['avatar_url'] ?? meta['picture'] ?? 'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200') as String;

    _currentUser = UserSession(
      uid: u.id,
      name: name,
      email: email,
      username: username,
      avatarUrl: avatar,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_uid', _currentUser!.uid);
    await prefs.setString('profileName', _currentUser!.name);
    await prefs.setString('user_email', _currentUser!.email);
    await prefs.setString('user_username', _currentUser!.username);
    await prefs.setString('user_avatar', _currentUser!.avatarUrl);

    try {
      await _supabase.from('profiles').upsert({
        'id': u.id,
        'name': name,
        'username': username,
        'avatar_url': avatar,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  void _initDeepLinks() {
    try {
      final appLinks = AppLinks();

      // Handle initial link when app opens from protocol scheme
      appLinks.getInitialLink().then((uri) async {
        if (uri != null) {
          debugPrint('[AuthService] Initial deep link captured: $uri');
          await handleAuthCallbackUrl(uri.toString());
        }
      }).catchError((e) {
        debugPrint('[AuthService] Initial deep link error: $e');
      });

      // Handle stream links
      appLinks.uriLinkStream.listen((uri) async {
        debugPrint('[AuthService] Deep link stream captured: $uri');
        await handleAuthCallbackUrl(uri.toString());
      });
    } catch (e) {
      debugPrint('[AuthService] AppLinks init notice: $e');
    }
  }

  /// Exchanges redirect URL or raw authorization code for an active session.
  Future<bool> handleAuthCallbackUrl(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty) return false;

    try {
      Uri? uri;
      try {
        if (input.contains('://') || input.contains('?') || input.contains('#')) {
          uri = Uri.parse(input);
        }
      } catch (_) {}

      String? code;
      if (uri != null) {
        code = uri.queryParameters['code'];
        if (code == null && uri.fragment.isNotEmpty) {
          final fragParams = Uri.splitQueryString(uri.fragment);
          code = fragParams['code'];
        }
      }

      code ??= input.split('code=').last.split('&').first.trim();

      if (code.isNotEmpty) {
        debugPrint('[AuthService] Exchanging auth code for session: $code');
        try {
          final res = await _supabase.auth.exchangeCodeForSession(code);
          await _buildSessionFromSupabaseUser(res.session.user);
          return true;
        } catch (err) {
          debugPrint('[AuthService] exchangeCodeForSession notice: $err');
          final supaUser = _supabase.auth.currentUser;
          if (supaUser != null) {
            await _buildSessionFromSupabaseUser(supaUser);
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Auth callback exchange error: $e');
    }
    return false;
  }

  /// Listens for a valid authenticated session until [timeout].
  Future<UserSession?> waitForAuthSession({Duration timeout = const Duration(seconds: 35)}) async {
    if (_currentUser != null) return _currentUser;
    final end = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(end)) {
      if (_currentUser != null) return _currentUser;

      // 1. Check active Supabase session
      final supaSession = _supabase.auth.currentSession;
      final supaUser = _supabase.auth.currentUser;
      if (supaSession != null && supaUser != null && _isSessionValid(supaSession)) {
        await _buildSessionFromSupabaseUser(supaUser);
        return _currentUser;
      }

      // 2. Check SharedPreferences (in case another process / deep-link handler saved session)
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('is_logged_in') == true) {
        final uid = prefs.getString('user_uid') ?? '';
        final name = prefs.getString('profileName') ?? 'Nexal User';
        final email = prefs.getString('user_email') ?? '';
        final username = prefs.getString('user_username') ?? 'user';
        final avatar = prefs.getString('user_avatar') ?? '';
        if (uid.isNotEmpty) {
          _currentUser = UserSession(
            uid: uid,
            name: name,
            email: email,
            username: username,
            avatarUrl: avatar,
          );
          _authStateController.add(_currentUser);
          return _currentUser;
        }
      }

      await Future.delayed(const Duration(milliseconds: 1000));
    }
    return _currentUser;
  }

  // ── Google OAuth / Native Sign-In ─────────────────────────────────────────
  Future<GoogleAuthResult> loginWithGoogle() async {
    // 1. Try native Google Sign-In with configured Client ID
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? googleClientId : null,
        serverClientId: googleClientId,
        scopes: ['email', 'profile'],
      );

      // Clear previous account state to ensure fresh account selection prompt
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AuthService] Google Sign-In cancelled by user.');
        return GoogleAuthResult.cancelled();
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
        final u = res.session?.user ?? res.user;
        if (u != null) {
          final meta = u.userMetadata ?? {};
          final name = googleUser.displayName ?? (meta['full_name'] ?? meta['name'] ?? googleUser.email.split('@').first);
          final avatar = googleUser.photoUrl ?? (meta['avatar_url'] ?? meta['picture'] ?? 'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200');
          final email = googleUser.email;
          final username = googleUser.email.split('@').first.toLowerCase();

          _currentUser = UserSession(
            uid: u.id,
            name: name,
            email: email,
            username: username,
            avatarUrl: avatar,
          );
          final p = await SharedPreferences.getInstance();
          await p.setBool('is_logged_in', true);
          await p.setString('user_uid', _currentUser!.uid);
          await p.setString('profileName', _currentUser!.name);
          await p.setString('user_email', _currentUser!.email);
          await p.setString('user_username', _currentUser!.username);
          await p.setString('user_avatar', _currentUser!.avatarUrl);

          // Upsert Google user profile into Supabase profiles database
          try {
            await _supabase.from('profiles').upsert({
              'id': u.id,
              'name': name,
              'username': username,
              'avatar_url': avatar,
              'email': email,
              'updated_at': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            debugPrint('[AuthService] Profile upsert notice: $e');
          }

          _authStateController.add(_currentUser);
          debugPrint('[AuthService] Native Google Sign-In successful for ${_currentUser!.email}!');
          return GoogleAuthResult.success(_currentUser!);
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Native Google Sign-In notice: $e. Falling back to Supabase OAuth browser flow...');
    }

    // 2. Fallback to Supabase OAuth browser flow (Desktop / Web / Unsupported native)
    try {
      final launched = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.nexal.app://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (launched) {
        return GoogleAuthResult.pendingBrowserOAuth();
      } else {
        return GoogleAuthResult.error('Failed to launch browser authentication');
      }
    } catch (err) {
      debugPrint('[AuthService] Google OAuth fallback failed: $err');
      return GoogleAuthResult.error(err.toString());
    }
  }

  // ── Facebook OAuth Sign-In ────────────────────────────────────────────────
  Future<bool> loginWithFacebook() async {
    try {
      final res = await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'io.nexal.app://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      debugPrint('[AuthService] Facebook OAuth launch result: $res');
      return res;
    } catch (err) {
      debugPrint('[AuthService] Facebook OAuth failed: $err');
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
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? googleClientId : null,
        serverClientId: googleClientId,
      );
      await googleSignIn.signOut();
    } catch (_) {}
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_uid');
    await prefs.remove('user_email');
    await prefs.remove('user_username');
    await prefs.remove('user_avatar');
    await prefs.remove('profileName');
    _currentUser = null;
    _authStateController.add(null);
  }
}
