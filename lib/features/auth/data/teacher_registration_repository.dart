import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:http/http.dart' as http;

class TeacherRegistrationRepository {
  TeacherRegistrationRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<RegistrationDepartment>> departments() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/register/options'),
      headers: const {'Accept': 'application/json'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['message'] as String? ?? 'Could not load departments.',
        statusCode: response.statusCode,
      );
    }

    final departments = decoded['departments'];
    if (departments is! List) return const [];

    return departments
        .whereType<Map>()
        .map(
          (item) =>
              RegistrationDepartment.fromJson(item.cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> sendEmailOtp(String email) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/register/teacher/email-otp'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email.trim()}),
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode == 429
            ? 'Too many verification code requests. Please wait a minute and try again.'
            : decoded['message'] as String? ??
                  'Could not send verification code.',
        statusCode: response.statusCode,
        errors: _extractErrors(decoded),
      );
    }
  }

  Future<void> registerTeacher({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String emailOtp,
    int? departmentId,
    String? specialization,
  }) async {
    final trimmedSpecialization = specialization?.trim();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/register/teacher'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
        'email_otp': emailOtp.trim(),
        'department_id': ?departmentId,
        'specialization': ?(trimmedSpecialization?.isEmpty ?? true
            ? null
            : trimmedSpecialization),
      }),
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode == 429
            ? 'Too many registration attempts. Please wait and try again.'
            : decoded['message'] as String? ?? 'Registration failed.',
        statusCode: response.statusCode,
        errors: _extractErrors(decoded),
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        'The server returned an invalid registration response.',
        statusCode: response.statusCode,
      );
    }
  }

  Map<String, List<String>> _extractErrors(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is! Map<String, dynamic>) return const {};

    return errors.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.map((item) => '$item').toList());
      }
      return MapEntry(key, ['$value']);
    });
  }
}

class RegistrationDepartment {
  const RegistrationDepartment({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory RegistrationDepartment.fromJson(Map<String, dynamic> json) {
    return RegistrationDepartment(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Department',
      code: json['code'] as String? ?? '',
    );
  }
}
