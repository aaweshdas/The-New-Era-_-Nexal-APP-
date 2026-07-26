import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Manages ARIA AI backend configuration (API keys, server URL).
/// All values are persisted via SharedPreferences and can be changed
/// from the Nexal app Settings screen at runtime.
class AriaConfig {
  // ─── Storage Keys ───────────────────────────────────────────────
  static const _keyGroqApiKey      = 'aria_groq_api_key';
  static const _keyDeepgramApiKey  = 'aria_deepgram_api_key';
  static const _keyLivekitUrl      = 'aria_livekit_url';
  static const _keyLivekitApiKey   = 'aria_livekit_api_key';
  static const _keyLivekitSecret   = 'aria_livekit_api_secret';
  static const _keyBackendUrl      = 'aria_backend_url';

  // ─── Default values (first-run) ─────────────────────────────────
  static const _defaultGroqKey     = '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';
  static const _defaultDeepgramKey = '49a17d5b3050b8e5498aa595f9888f4f19950955';
  static const _defaultLivekitUrl  = 'wss://friday-si6nqz7u.livekit.cloud';
  static const _defaultLivekitKey  = 'API6vNUPttbHXDd';
  static const _defaultLivekitSec  = 'xH4Ld1M8SQZ4XSXQTMYDmMttC8ii2i8nWO09adFSwHG';
  static String get _defaultBackendUrl => AppConfig.gatewayUrl;

  // ─── Instance fields ────────────────────────────────────────────
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

  /// Load config from SharedPreferences (with defaults on first run).
  static Future<AriaConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AriaConfig._(
      groqApiKey:      prefs.getString(_keyGroqApiKey)      ?? _defaultGroqKey,
      deepgramApiKey:  prefs.getString(_keyDeepgramApiKey)   ?? _defaultDeepgramKey,
      livekitUrl:      prefs.getString(_keyLivekitUrl)       ?? _defaultLivekitUrl,
      livekitApiKey:   prefs.getString(_keyLivekitApiKey)    ?? _defaultLivekitKey,
      livekitApiSecret:prefs.getString(_keyLivekitSecret)    ?? _defaultLivekitSec,
      backendUrl:      prefs.getString(_keyBackendUrl)       ?? _defaultBackendUrl,
    );
  }

  /// Save all current values to SharedPreferences.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGroqApiKey,      groqApiKey);
    await prefs.setString(_keyDeepgramApiKey,   deepgramApiKey);
    await prefs.setString(_keyLivekitUrl,       livekitUrl);
    await prefs.setString(_keyLivekitApiKey,    livekitApiKey);
    await prefs.setString(_keyLivekitSecret,    livekitApiSecret);
    await prefs.setString(_keyBackendUrl,       backendUrl);
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
