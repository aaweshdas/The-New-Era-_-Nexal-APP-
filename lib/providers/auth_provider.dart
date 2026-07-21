import 'package:flutter/material.dart';
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
    AuthService.instance.authStateChanges.listen((session) {
      if (session != null) {
        _user = UserModel(
          uid: session.uid,
          name: session.name,
          username: session.username,
          email: session.email,
          avatarUrl: session.avatarUrl,
        );
      } else {
        _user = null;
      }
      notifyListeners();
    });
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
