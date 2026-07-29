import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();
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
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Check error: $e');
      return false;
    }
  }

  /// Get list of available biometric hardware types (fingerprint, face, iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Get available biometrics error: $e');
      return [];
    }
  }

  /// Trigger biometric authentication prompt
  Future<bool> authenticate({String reason = 'Authenticate to unlock Nexal App'}) async {
    try {
      final bool canAuth = await canCheckBiometrics();
      if (!canAuth) return true; // Fallback for unsupported devices

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
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
