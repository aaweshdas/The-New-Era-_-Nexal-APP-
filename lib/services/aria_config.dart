import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Manages ARIA AI backend configuration (API keys, server URL).
///
/// API keys (Groq, Deepgram, LiveKit) are stored in flutter_secure_storage
/// which is backed by Android Keystore / iOS Keychain — they are NOT stored
/// in plaintext SharedPreferences. The backend URL (not sensitive) remains
/// in SharedPreferences for performance.
class AriaConfig {
  // ─── Storage Keys ────────────────────────────────────────────────
  static const _keyGroqApiKey      = 'aria_groq_api_key';
  static const _keyDeepgramApiKey  = 'aria_deepgram_api_key';
  static const _keyLivekitUrl      = 'aria_livekit_url';
  static const _keyLivekitApiKey   = 'aria_livekit_api_key';
  static const _keyLivekitSecret   = 'aria_livekit_api_secret';
  static const _keyBackendUrl      = 'aria_backend_url';

  // ─── Secure storage instance ─────────────────────────────────────
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Default values (from build-time environment) ─────────────────
  static const _defaultGroqKey     = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const _defaultDeepgramKey = String.fromEnvironment('DEEPGRAM_API_KEY', defaultValue: '');
  static const _defaultLivekitUrl  = String.fromEnvironment('LIVEKIT_URL', defaultValue: '');
  static const _defaultLivekitKey  = String.fromEnvironment('LIVEKIT_API_KEY', defaultValue: '');
  static const _defaultLivekitSec  = String.fromEnvironment('LIVEKIT_API_SECRET', defaultValue: '');
  static String get _defaultBackendUrl => AppConfig.gatewayUrl;

  // ─── Instance fields ─────────────────────────────────────────────
  String groqApiKey;
  String deepgramApiKey;
  String livekitUrl;
  String livekitApiKey;
  String livekitApiSecret;
  String backendUrl;

  AriaConfig({
    required this.groqApiKey,
    required this.deepgramApiKey,
    required this.livekitUrl,
    required this.livekitApiKey,
    required this.livekitApiSecret,
    required this.backendUrl,
  });

  AriaConfig._({
    required this.groqApiKey,
    required this.deepgramApiKey,
    required this.livekitUrl,
    required this.livekitApiKey,
    required this.livekitApiSecret,
    required this.backendUrl,
  });

  /// Load config: API keys from flutter_secure_storage, URL from SharedPreferences.
  static Future<AriaConfig> load() async {
    final prefs = await SharedPreferences.getInstance();

    // API keys loaded from secure encrypted storage
    final groq     = await _secureStorage.read(key: _keyGroqApiKey)     ?? _defaultGroqKey;
    final deepgram = await _secureStorage.read(key: _keyDeepgramApiKey) ?? _defaultDeepgramKey;
    final lkUrl    = await _secureStorage.read(key: _keyLivekitUrl)     ?? _defaultLivekitUrl;
    final lkKey    = await _secureStorage.read(key: _keyLivekitApiKey)  ?? _defaultLivekitKey;
    final lkSec    = await _secureStorage.read(key: _keyLivekitSecret)  ?? _defaultLivekitSec;

    // Backend URL is not sensitive — stored in SharedPreferences for fast access
    final backend  = prefs.getString(_keyBackendUrl) ?? _defaultBackendUrl;

    return AriaConfig._(
      groqApiKey:       groq,
      deepgramApiKey:   deepgram,
      livekitUrl:       lkUrl,
      livekitApiKey:    lkKey,
      livekitApiSecret: lkSec,
      backendUrl:       backend,
    );
  }

  /// Save current values: API keys to secure storage, URL to SharedPreferences.
  Future<void> save() async {
    // Sensitive API keys → secure encrypted storage
    await _secureStorage.write(key: _keyGroqApiKey,     value: groqApiKey);
    await _secureStorage.write(key: _keyDeepgramApiKey, value: deepgramApiKey);
    await _secureStorage.write(key: _keyLivekitUrl,     value: livekitUrl);
    await _secureStorage.write(key: _keyLivekitApiKey,  value: livekitApiKey);
    await _secureStorage.write(key: _keyLivekitSecret,  value: livekitApiSecret);

    // Non-sensitive URL → regular SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBackendUrl, backendUrl);
  }

  /// Reset all keys to factory defaults.
  Future<void> resetToDefaults() async {
    groqApiKey       = _defaultGroqKey;
    deepgramApiKey   = _defaultDeepgramKey;
    livekitUrl       = _defaultLivekitUrl;
    livekitApiKey    = _defaultLivekitKey;
    livekitApiSecret = _defaultLivekitSec;
    backendUrl       = _defaultBackendUrl;
    await save();
  }
}
