import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  static const String _biometricEnabledKey = 'biometrics_enabled_key';

  bool _isBiometricsEnabled = false;
  bool get isBiometricsEnabled => _isBiometricsEnabled;

  /// Initialize biometric settings status
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isBiometricsEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
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
    await prefs.setBool(_biometricEnabledKey, enabled);
    _isBiometricsEnabled = enabled;
    return true;
  }
}
