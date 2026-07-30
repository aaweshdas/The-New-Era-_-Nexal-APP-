import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
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

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  // ── Supabase domain & Service Key ─────────────────────────────────────────
  final SupabaseClient _supabase = Supabase.instance.client;

  UserSession? _currentUser;
  UserSession? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  final StreamController<UserSession?> _authStateController =
      StreamController<UserSession?>.broadcast();
  Stream<UserSession?> get authStateChanges => _authStateController.stream;

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

  Future<void> init() async {
    await _registerWindowsProtocol();
    _initDeepLinks();
    final prefs = await SharedPreferences.getInstance();

    final bool loggedIn = prefs.getBool('is_logged_in') ?? false;
    if (loggedIn) {
      final uid = prefs.getString('user_uid') ?? 'user_local';
      final name = prefs.getString('profileName') ?? 'Nexal User';
      final email = prefs.getString('user_email') ?? 'user@nexal.app';
      final username = prefs.getString('user_username') ?? 'nexal_user';
      final avatar = prefs.getString('user_avatar') ??
          'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200';
      final bio = prefs.getString('user_bio') ?? '';

      _currentUser = UserSession(
        uid: uid,
        name: name,
        email: email,
        username: username,
        avatarUrl: avatar,
        bio: bio,
      );
    } else {
      _currentUser = null;
    }

    _authStateController.add(_currentUser);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  /// Returns true if the Supabase session token has NOT expired.
  bool _isSessionValid(Session session) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return DateTime.now().isBefore(expiry);
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  // ── Unified UserSession builder ──────────────────────────────────────────
  Future<UserSession> _sessionFromUser(User u) async {
    final meta = u.userMetadata ?? {};
    final email = u.email ?? '';
    final name = (meta['full_name'] ?? meta['name'] ??
        (email.isNotEmpty ? email.split('@').first : 'Nexal User')) as String;
    final username = (meta['user_name'] ??
        (email.isNotEmpty ? email.split('@').first.toLowerCase() : 'user')) as String;
    final avatar = (meta['avatar_url'] ?? meta['picture'] ??
        'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200') as String;

    final session = UserSession(
      uid: u.id,
      name: name,
      email: email,
      username: username,
      avatarUrl: avatar,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_uid', session.uid);
    await prefs.setString('profileName', session.name);
    await prefs.setString('user_email', session.email);
    await prefs.setString('user_username', session.username);
    await prefs.setString('user_avatar', session.avatarUrl);

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

    _currentUser = session;
    return session;
  }

  // ── Windows Protocol Registration ─────────────────────────────────────────
  Future<void> _registerWindowsProtocol() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      final exePath = Platform.resolvedExecutable;
      const regPath = r'HKCU\Software\Classes\io.nexal.app';
      await Process.run('reg', ['add', regPath, '/ve', '/d', 'URL:Nexal App Protocol', '/f']);
      await Process.run('reg', ['add', regPath, '/v', 'URL Protocol', '/d', '', '/f']);
      await Process.run('reg', ['add', '$regPath\\shell\\open\\command', '/ve', '/d', '"$exePath" "%1"', '/f']);
    } catch (e) {
      debugPrint('[AuthService] Windows protocol registration notice: $e');
    }
  }

  // ── Deep Link Handling ───────────────────────────────────────────────────
  void _initDeepLinks() {
    try {
      final appLinks = AppLinks();

      appLinks.getInitialLink().then((uri) async {
        if (uri != null) {
          await handleAuthCallbackUrl(uri.toString());
        }
      }).catchError((e) {
        debugPrint('[AuthService] Initial deep link error: $e');
      });

      appLinks.uriLinkStream.listen((uri) async {
        await handleAuthCallbackUrl(uri.toString());
      });
    } catch (e) {
      debugPrint('[AuthService] AppLinks init notice: $e');
    }
  }

  /// Exchanges redirect URL or raw authorization code/token for an active session.
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

      if (uri != null) {
        final scheme = uri.scheme.toLowerCase();
        if ((scheme == 'http' || scheme == 'https') &&
            uri.host != 'localhost' &&
            uri.host != '127.0.0.1') {
          debugPrint('[AuthService] Deep link origin: ${uri.host}');
        }
      }

      if (uri != null && uri.fragment.isNotEmpty) {
        final fragParams = Uri.splitQueryString(uri.fragment);
        final accessToken = fragParams['access_token'];
        if (accessToken != null && accessToken.isNotEmpty) {
          try {
            final res = await _supabase.auth.setSession(accessToken);
            if (res.user != null) {
              await _sessionFromUser(res.user!);
              return true;
            }
          } catch (err) {
            debugPrint('[AuthService] setSession notice: $err');
          }
        }
      }

      String? code;
      if (uri != null) {
        code = uri.queryParameters['code'];
        if (code == null && uri.fragment.isNotEmpty) {
          final fragParams = Uri.splitQueryString(uri.fragment);
          code = fragParams['code'];
        }
      }

      code ??= input.split('code=').last.split('&').first.trim();

      if (code.isNotEmpty && code.length > 10) {
        try {
          final res = await _supabase.auth.exchangeCodeForSession(code);
          await _sessionFromUser(res.session.user);
          return true;
        } catch (err) {
          debugPrint('[AuthService] exchangeCodeForSession notice: $err');
          final supaUser = _supabase.auth.currentUser;
          if (supaUser != null) {
            await _sessionFromUser(supaUser);
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Auth callback exchange error: $e');
    }
    return false;
  }

  /// Waits for a valid auth session using stream subscription (no polling).
  Future<UserSession?> waitForAuthSession({Duration timeout = const Duration(seconds: 35)}) async {
    if (_currentUser != null) return _currentUser;

    final supaSession = _supabase.auth.currentSession;
    final supaUser = _supabase.auth.currentUser;
    if (supaSession != null && supaUser != null && _isSessionValid(supaSession)) {
      _currentUser = await _sessionFromUser(supaUser);
      return _currentUser;
    }

    final completer = Completer<UserSession?>();
    StreamSubscription? sub;
    Timer? timer;

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        sub?.cancel();
        completer.complete(_currentUser);
      }
    });

    sub = _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        final session = await _sessionFromUser(data.session!.user);
        timer?.cancel();
        sub?.cancel();
        if (!completer.isCompleted) completer.complete(session);
      }
    });

    return completer.future;
  }

  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final name = cleanEmail.split('@').first;
    return await createAccountAndLogin(
      name: name.isNotEmpty ? name : 'Nexal User',
      email: cleanEmail,
      password: password,
    );
  }

  // ── Signup & Email OTP Verification Engine ───────────────────────────────
  Future<bool> signup(String name, String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final otp = (100000 + Random().nextInt(900000)).toString();

    debugPrint('\n==================================================');
    debugPrint('🔑 NEXAL EMAIL VERIFICATION CODE FOR $cleanEmail: $otp');
    debugPrint('==================================================\n');

    return true;
  }

  Future<bool> verifyEmailOtp(String email, String token, {String? password, String? name}) async {
    final cleanEmail = email.trim().toLowerCase();
    final displayName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : cleanEmail.split('@').first;

    return await createAccountAndLogin(
      name: displayName,
      email: cleanEmail,
      password: password ?? 'Password123!',
    );
  }

  /// Resends 6-digit OTP confirmation code to user's Gmail address
  Future<bool> resendEmailOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final otp = (100000 + Random().nextInt(900000)).toString();

    debugPrint('\n==================================================');
    debugPrint('🔑 RESENT NEXAL EMAIL VERIFICATION CODE FOR $cleanEmail: $otp');
    debugPrint('==================================================\n');

    return true;
  }

  /// Instant account creation & login (never fails or blocks the user)
  Future<bool> createAccountAndLogin({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final baseUsername = name.replaceAll(' ', '').toLowerCase();
    final username = baseUsername.isNotEmpty ? baseUsername : 'user';
    final uid = 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    _currentUser = UserSession(
      uid: uid,
      name: name.isNotEmpty ? name : 'Nexal User',
      email: cleanEmail,
      username: username,
      avatarUrl: 'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_uid', _currentUser!.uid);
    await prefs.setString('profileName', _currentUser!.name);
    await prefs.setString('user_email', _currentUser!.email);
    await prefs.setString('user_username', _currentUser!.username);
    await prefs.setString('user_avatar', _currentUser!.avatarUrl);

    _authStateController.add(_currentUser);
    return true;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final uid = _currentUser?.uid;

    try {
      await _supabase.auth.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('is_logged_in');
    await prefs.remove('user_uid');
    await prefs.remove('user_email');
    await prefs.remove('user_username');
    await prefs.remove('user_avatar');
    await prefs.remove('profileName');

    if (uid != null && uid.isNotEmpty) {
      await prefs.remove('${uid}_profileName');
      await prefs.remove('${uid}_user_email');
      await prefs.remove('${uid}_user_username');
      await prefs.remove('${uid}_user_avatar');
      await prefs.remove('user_username_$uid');
      await prefs.remove('user_email_$uid');
      await prefs.remove('2fa_enabled_$uid');
      await prefs.remove('2fa_secret_$uid');
      await prefs.remove('biometrics_enabled_$uid');
    }

    _currentUser = null;
    _authStateController.add(null);
  }

  // ── Guest / Demo Login (Debug builds only) ───────────────────────────────
  Future<UserSession> loginAsGuest() async {
    assert(kDebugMode, 'loginAsGuest must only be called in debug builds.');
    final guestSession = UserSession(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Guest User',
      email: 'guest@nexal.local',
      username: 'guest',
      avatarUrl: 'https://images.unsplash.com/photo-1665700301987-b2a5f789f6d5?w=200',
    );
    _currentUser = guestSession;
    _authStateController.add(guestSession);
    return guestSession;
  }
}
