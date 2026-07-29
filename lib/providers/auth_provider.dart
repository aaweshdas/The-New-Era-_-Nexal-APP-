import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  void _init() {
    AuthService.instance.authStateChanges.listen((session) async {
      if (session != null) {
        await _fetchProfile(session.uid, session.name, session.username, session.email, session.avatarUrl);
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchProfile(String uid, String fallbackName, String fallbackUsername, String fallbackEmail, String fallbackAvatar) async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.from('profiles').select().eq('id', uid).maybeSingle();

      if (res != null) {
        _user = UserModel(
          uid: uid,
          name: (res['name'] as String?)?.isNotEmpty == true ? res['name'] : fallbackName,
          username: (res['username'] as String?)?.isNotEmpty == true ? res['username'] : fallbackUsername,
          email: (res['email'] as String?)?.isNotEmpty == true ? res['email'] : fallbackEmail,
          avatarUrl: (res['avatar_url'] as String?)?.isNotEmpty == true ? res['avatar_url'] : fallbackAvatar,
          coverUrl: (res['cover_url'] as String?) ?? '',
          bio: (res['bio'] as String?) ?? '',
          location: (res['location'] as String?) ?? '',
          website: (res['website'] as String?) ?? '',
          badge: (res['badge'] as String?) ?? '',
          postsCount: (res['posts_count'] as int?) ?? 0,
          followersCount: (res['followers_count'] as int?) ?? 0,
          followingCount: (res['following_count'] as int?) ?? 0,
          isVerified: (res['is_verified'] as bool?) ?? false,
        );
      } else {
        _user = UserModel(
          uid: uid,
          name: fallbackName,
          username: fallbackUsername,
          email: fallbackEmail,
          avatarUrl: fallbackAvatar,
        );
      }
    } catch (e) {
      _user = UserModel(
        uid: uid,
        name: fallbackName,
        username: fallbackUsername,
        email: fallbackEmail,
        avatarUrl: fallbackAvatar,
      );
    }
    notifyListeners();
  }

  Future<void> reloadProfile() async {
    final current = AuthService.instance.currentUser;
    if (current != null) {
      await _fetchProfile(current.uid, current.name, current.handle, current.email, current.avatarUrl);
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final res = await AuthService.instance.login(email, password);
    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _user = null;
    notifyListeners();
  }
}
