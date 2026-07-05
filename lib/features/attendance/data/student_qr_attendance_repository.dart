import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class StudentQrAttendanceRepository {
  StudentQrAttendanceRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<StudentQrCheckInResult> verify({
    required int sessionId,
    required String qrToken,
  }) async {
    final token = await _token();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/student/verify'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'session_id': sessionId, 'qr_token': qrToken}),
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _asMap(decoded);
      throw ApiException(
        body['message'] as String? ??
            body['error'] as String? ??
            _firstValidationError(body) ??
            'Could not verify attendance QR.',
        statusCode: response.statusCode,
        errors: _validationErrors(body),
      );
    }

    return StudentQrCheckInResult.fromJson(_asMap(decoded));
  }

  Future<String> _token() async {
    final token = await _sessionStore.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again.');
    }
    return token;
  }

  Object? _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The server returned an invalid QR attendance response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class StudentQrCheckInResult {
  const StudentQrCheckInResult({
    required this.message,
    required this.status,
    required this.scanTime,
    required this.subject,
    required this.teacher,
    required this.room,
  });

  final String message;
  final String status;
  final String scanTime;
  final String subject;
  final String teacher;
  final String room;

  factory StudentQrCheckInResult.fromJson(Map<String, dynamic> json) {
    final attendance = _asMap(json['attendance']);
    final session = _asMap(json['session']);
    return StudentQrCheckInResult(
      message: json['message'] as String? ?? 'Check-in successful!',
      status:
          json['status'] as String? ?? attendance['status'] as String? ?? '',
      scanTime: attendance['scan_time'] as String? ?? '',
      subject: session['subject'] as String? ?? '',
      teacher: session['teacher'] as String? ?? '',
      room: session['room'] as String? ?? '',
    );
  }
}

class StudentQrPayload {
  const StudentQrPayload({required this.sessionId, required this.token});

  final int sessionId;
  final String token;
}

StudentQrPayload? parseStudentQrPayload(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    final token = uri.queryParameters['token'] ?? '';
    final segments = uri.pathSegments;

    final checkInIndex = segments.indexWhere((part) => part == 'checkin');
    if (checkInIndex >= 0 &&
        checkInIndex + 3 < segments.length &&
        segments[checkInIndex + 1] == 'confirm') {
      final sessionId = int.tryParse(segments[checkInIndex + 2]) ?? 0;
      final token = Uri.decodeComponent(
        segments.sublist(checkInIndex + 3).join('/'),
      );
      if (_isValidSessionQr(sessionId, token)) {
        return StudentQrPayload(sessionId: sessionId, token: token);
      }
    }

    final scanIndex = segments.lastIndexWhere((part) => part == 'scan');
    if (scanIndex >= 0 && scanIndex + 1 < segments.length) {
      final sessionId = int.tryParse(segments[scanIndex + 1]) ?? 0;
      if (_isValidSessionQr(sessionId, token)) {
        return StudentQrPayload(sessionId: sessionId, token: token);
      }
    }

    final apiStudentIndex = segments.indexWhere((part) => part == 'student');
    if (apiStudentIndex >= 0 &&
        apiStudentIndex + 2 < segments.length &&
        segments[apiStudentIndex + 1] == 'scan') {
      final sessionId = int.tryParse(segments[apiStudentIndex + 2]) ?? 0;
      if (_isValidSessionQr(sessionId, token)) {
        return StudentQrPayload(sessionId: sessionId, token: token);
      }
    }
  }

  return null;
}

bool _isValidSessionQr(int sessionId, String token) {
  if (sessionId <= 0) return false;
  if (token.length < 12 || token.length > 128) return false;
  return RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(token);
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

Map<String, List<String>> _validationErrors(Map<String, dynamic> body) {
  final errors = body['errors'];
  if (errors is! Map) return const {};
  return errors.map((key, value) {
    if (value is List) {
      return MapEntry('$key', value.map((item) => '$item').toList());
    }
    return MapEntry('$key', ['$value']);
  });
}

String? _firstValidationError(Map<String, dynamic> body) {
  final errors = _validationErrors(body);
  for (final messages in errors.values) {
    if (messages.isNotEmpty) return messages.first;
  }
  return null;
}
