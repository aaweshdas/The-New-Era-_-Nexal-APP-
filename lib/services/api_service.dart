import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  final http.Client _client = http.Client();

  Map<String, String> get _defaultHeaders {
    final supaToken = Supabase.instance.client.auth.currentSession?.accessToken;
    final uid = AuthService.instance.currentUser?.uid ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (supaToken != null && supaToken.isNotEmpty) 'Authorization': 'Bearer $supaToken',
      if (uid.isNotEmpty) 'X-User-Id': uid,
    };
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    try {
      final response = await _client
          .get(url, headers: _defaultHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    try {
      final response = await _client
          .post(
            url,
            headers: _defaultHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
