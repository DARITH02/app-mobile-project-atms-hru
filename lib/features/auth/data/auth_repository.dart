import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:hru_atms/features/auth/domain/models/auth_session.dart';
import 'package:http/http.dart' as http;

class AuthRepository {
  AuthRepository({http.Client? client, AuthSessionStore? sessionStore})
    : _client = client ?? http.Client(),
      _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<AuthSession> login({
    required String login,
    required String role,
    String? password,
    String? studentCode,
  }) async {
    final trimmedLogin = login.trim();
    final body = <String, Object?>{
      if (role == 'student' && trimmedLogin.contains('@'))
        'email': trimmedLogin
      else if (role == 'student')
        'phone': trimmedLogin
      else
        'login': trimmedLogin,
      if (password != null && password.isNotEmpty) 'password': password,
      'role': role,
      'device_name': 'hru-atms-mobile',
      if (studentCode != null && studentCode.trim().isNotEmpty)
        'student_code': studentCode.trim(),
    };

    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errors = _extractErrors(decoded);
      throw ApiException(
        _firstError(errors) ?? decoded['message'] as String? ?? 'Login failed.',
        statusCode: response.statusCode,
        errors: errors,
      );
    }

    final data = decoded['data'] as Map<String, dynamic>? ?? decoded;
    final session = AuthSession.fromJson(data);
    if (session.token.isEmpty) {
      throw const ApiException('The server did not return an auth token.');
    }

    await _sessionStore.save(session);
    return session;
  }

  Future<void> logout() async {
    final token = await _sessionStore.token();

    if (token != null && token.isNotEmpty) {
      try {
        await _client.post(
          Uri.parse('${ApiConfig.baseUrl}/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {
        // Local logout should still succeed if the token is expired or offline.
      }
    }

    await _sessionStore.clear();
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }
  }

  Map<String, List<String>> _extractErrors(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is! Map<String, dynamic>) {
      return const {};
    }

    return errors.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.map((item) => '$item').toList());
      }
      return MapEntry(key, ['$value']);
    });
  }

  String? _firstError(Map<String, List<String>> errors) {
    for (final messages in errors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return null;
  }
}
