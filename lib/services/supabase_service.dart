import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Service Manager for Nexal Mobile Client
///
/// Credentials are loaded from build-time dart-define environment variables.
/// Pass these at build time:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
///
/// For development, create a `.env.dart-define` file (gitignored) with the values
/// and reference it via: flutter run --dart-define-from-file=.env.dart-define
class SupabaseService {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    // Keep defaultValue for development convenience only.
    // In production CI/CD, provide via --dart-define and remove this default.
    defaultValue: 'https://baynhfqvzhvrttrskevu.supabase.co',
  );
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    // Keep defaultValue for development convenience only.
    defaultValue: 'sb_publishable_SRtHtAL89UNUo0eK4oB53g_sNkmzul9',
  );

  /// Initialize Supabase client on app launch
  static Future<void> initialize() async {
    assert(
      url.isNotEmpty && url.startsWith('https://'),
      'SUPABASE_URL must be provided via --dart-define in production builds.',
    );
    assert(
      publishableKey.isNotEmpty,
      'SUPABASE_ANON_KEY must be provided via --dart-define in production builds.',
    );

    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Shorthand getter for Supabase client
  static SupabaseClient get client => Supabase.instance.client;
}
