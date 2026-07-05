import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class StudentPermissionRepository {
  StudentPermissionRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<StudentPermissionData> load() async {
    final token = await _token();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/student/permissions'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _asMap(decoded)['message'] as String? ??
            'Could not load pre-permission requests.',
        statusCode: response.statusCode,
      );
    }

    return StudentPermissionData.fromJson(_asMap(decoded));
  }

  Future<String> submit({
    required String mode,
    int? attendanceSessionId,
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    required String reason,
  }) async {
    final token = await _token();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/student/permissions'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'mode': mode,
        'attendance_session_id': ?attendanceSessionId,
        'start_date': _date(startDate),
        'end_date': _date(endDate),
        'type': type,
        'reason': reason.trim(),
      }),
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _asMap(decoded);
      throw ApiException(
        _firstError(body['errors']) ??
            body['message'] as String? ??
            'Could not submit pre-permission request.',
        statusCode: response.statusCode,
      );
    }

    return _asMap(decoded)['message'] as String? ??
        'Pre-permission request submitted.';
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
        'The server returned an invalid permission response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class StudentPermissionData {
  const StudentPermissionData({
    required this.student,
    required this.requests,
    required this.sessions,
  });

  final StudentPermissionOwner student;
  final List<StudentPermissionRequest> requests;
  final List<StudentPermissionSession> sessions;

  factory StudentPermissionData.fromJson(Map<String, dynamic> json) {
    return StudentPermissionData(
      student: StudentPermissionOwner.fromJson(_asMap(json['student'])),
      requests: _asList(
        json['permissions'],
      ).map(StudentPermissionRequest.fromJson).toList(),
      sessions: _asList(
        json['sessions'],
      ).map(StudentPermissionSession.fromJson).toList(),
    );
  }
}

class StudentPermissionSession {
  const StudentPermissionSession({
    required this.id,
    required this.date,
    required this.time,
    required this.title,
    required this.teacher,
    required this.room,
    required this.status,
  });

  final int id;
  final String date;
  final String time;
  final String title;
  final String teacher;
  final String room;
  final String status;

  String get label => '$date $time - $title (${_statusLabel(status)})';

  factory StudentPermissionSession.fromJson(Map<String, dynamic> json) {
    return StudentPermissionSession(
      id: _int(json['id']),
      date: '${json['date'] ?? ''}',
      time: '${json['time'] ?? ''}',
      title: json['title'] as String? ?? 'Class',
      teacher: json['teacher'] as String? ?? 'N/A',
      room: json['room'] as String? ?? 'TBD',
      status: json['status'] as String? ?? 'scheduled',
    );
  }
}

class StudentPermissionOwner {
  const StudentPermissionOwner({
    required this.name,
    required this.studentCode,
    required this.group,
  });

  final String name;
  final String studentCode;
  final String group;

  factory StudentPermissionOwner.fromJson(Map<String, dynamic> json) {
    return StudentPermissionOwner(
      name: json['name'] as String? ?? 'Student',
      studentCode: json['student_code'] as String? ?? 'N/A',
      group: json['group'] as String? ?? 'N/A',
    );
  }
}

class StudentPermissionRequest {
  const StudentPermissionRequest({
    required this.id,
    required this.attendanceSessionId,
    required this.subject,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.reason,
    required this.status,
    required this.expiresAt,
    required this.reviewedAt,
    required this.createdAt,
  });

  final int id;
  final int attendanceSessionId;
  final String subject;
  final String startDate;
  final String endDate;
  final String type;
  final String reason;
  final String status;
  final String expiresAt;
  final String reviewedAt;
  final String createdAt;

  bool get isExpired {
    if (status.toLowerCase() != 'pending') return false;
    final expiry = DateTime.tryParse(expiresAt)?.toLocal();
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  String get effectiveStatus => isExpired ? 'expired' : status;

  factory StudentPermissionRequest.fromJson(Map<String, dynamic> json) {
    return StudentPermissionRequest(
      id: _int(json['id']),
      attendanceSessionId: _int(json['attendance_session_id']),
      subject: json['subject'] as String? ?? '',
      startDate: '${json['start_date'] ?? ''}',
      endDate: '${json['end_date'] ?? ''}',
      type: json['type'] as String? ?? 'other',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      expiresAt: '${json['expires_at'] ?? ''}',
      reviewedAt: '${json['reviewed_at'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

List<Map<String, dynamic>> _asList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

String _date(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _statusLabel(String value) {
  final normalized = value.trim().toLowerCase().replaceAll('_', ' ');
  if (normalized.isEmpty) return 'Scheduled';
  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String? _firstError(Object? errors) {
  if (errors is! Map) return null;
  for (final value in errors.values) {
    if (value is List && value.isNotEmpty) return '${value.first}';
    if (value != null) return '$value';
  }
  return null;
}
