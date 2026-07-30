import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

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
    if (kIsWeb) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] canCheckBiometrics error: $e');
      return false;
    }
  }

  /// Returns available biometric types on this device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Trigger REAL biometric authentication prompt via local_auth.
  /// Returns true only if the platform confirms biometric identity.
  Future<bool> authenticate({String reason = 'Authenticate to unlock Nexal App'}) async {
    if (kIsWeb) return false;

    try {
      HapticFeedback.mediumImpact();

      final bool deviceSupported = await _localAuth.isDeviceSupported();
      if (!deviceSupported) {
        debugPrint('[BiometricService] Device does not support biometrics.');
        return false;
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN/pattern fallback
          stickyAuth: true,     // Preserve auth state across brief app switches
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Authentication error: $e');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Unexpected authentication error: $e');
      return false;
    }
  }

  /// Cancel any in-progress authentication
  Future<void> cancelAuthentication() async {
    if (kIsWeb) return;
    try {
      await _localAuth.stopAuthentication();
    } catch (_) {}
  }

  /// Toggle biometric lock preference
  Future<bool> setBiometricsEnabled(bool enabled) async {
    if (enabled) {
      final bool supported = await canCheckBiometrics();
      if (!supported) {
        debugPrint('[BiometricService] Biometrics not supported on this device.');
        return false;
      }
      final bool authenticated = await authenticate(
        reason: 'Verify biometric identity to enable App Lock',
      );
      if (!authenticated) return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
    _isBiometricsEnabled = enabled;
    return true;
  }
}
