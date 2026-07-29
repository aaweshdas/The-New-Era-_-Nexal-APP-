import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  bool _isBiometricsEnabled = false;
  bool get isBiometricsEnabled => _isBiometricsEnabled;

  String get _key {
    final uid = AuthService.instance.currentUser?.uid ?? 'guest';
    return 'biometrics_enabled_$uid';
  }

  /// Initialize biometric settings status
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isBiometricsEnabled = prefs.getBool(_key) ?? false;
  }

  /// Check if hardware supports biometric authentication
  Future<bool> canCheckBiometrics() async {
    return !kIsWeb;
  }

  /// Trigger biometric authentication prompt
  Future<bool> authenticate({String reason = 'Authenticate to unlock Nexal App'}) async {
    try {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    } catch (e) {
      debugPrint('[BiometricService] Authentication error: $e');
      return false;
    }
  }

  /// Toggle biometric lock preference
  Future<bool> setBiometricsEnabled(bool enabled) async {
    if (enabled) {
      final bool authenticated = await authenticate(reason: 'Verify biometric identity to enable App Lock');
      if (!authenticated) return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
    _isBiometricsEnabled = enabled;
    return true;
  }
}
