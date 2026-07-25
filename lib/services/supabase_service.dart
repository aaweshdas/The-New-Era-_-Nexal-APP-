import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Service Manager for Nexal Mobile Client
class SupabaseService {
  static const String url = 'https://baynhfqvzhvrttrskevu.supabase.co';
  static const String publishableKey = 'sb_publishable_SRtHtAL89UNUo0eK4oB53g_sNkmzul9';
  static const String jwksUrl = 'https://baynhfqvzhvrttrskevu.supabase.co/auth/v1/.well-known/jwks.json';

  /// Initialize Supabase client on app launch
  static Future<void> initialize() async {
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
