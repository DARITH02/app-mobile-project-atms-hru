import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class TeacherPermissionRepository {
  TeacherPermissionRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<TeacherPermissionData> load() async {
    final token = await _token();
    final responses = await Future.wait([
      _get('/teacher/attendance/sessions?per_page=100', token),
      _get('/teacher/attendance/corrections', token),
    ]);

    return TeacherPermissionData(
      sessions: _asList(
        _asMap(responses[0])['data'],
      ).map((item) => TeacherPermissionSession.fromJson(item)).toList(),
      requests: _asList(
        _asMap(responses[1])['data'],
      ).map((item) => TeacherPermissionRequest.fromJson(item)).toList(),
    );
  }

  Future<String> submit({
    required int attendanceSessionId,
    required String type,
    required String reason,
  }) async {
    final token = await _token();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/teacher/attendance/corrections'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'attendance_session_id': attendanceSessionId,
        'request_type': 'wrong_status',
        'requested_status': 'permission',
        'reason': '${_typeLabel(type)}: ${reason.trim()}',
      }),
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errors = _extractErrors(_asMap(decoded));
      throw ApiException(
        _firstError(errors) ??
            _asMap(decoded)['message'] as String? ??
            'Could not submit teacher permission request.',
        statusCode: response.statusCode,
        errors: errors,
      );
    }

    return 'Teacher permission request submitted. Admin approval is required.';
  }

  Future<String> submitMany({
    required List<int> attendanceSessionIds,
    required String type,
    required String reason,
  }) async {
    if (attendanceSessionIds.isEmpty) {
      throw const ApiException('Choose at least one session.');
    }

    for (final sessionId in attendanceSessionIds) {
      await submit(attendanceSessionId: sessionId, type: type, reason: reason);
    }

    return 'Teacher permission requests submitted. Admin approval is required.';
  }

  Future<Object?> _get(String path, String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _asMap(decoded)['message'] as String? ??
            _asMap(decoded)['error'] as String? ??
            'Could not load teacher permission data.',
        statusCode: response.statusCode,
      );
    }

    return decoded;
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

  String? _firstError(Map<String, List<String>> errors) {
    for (final messages in errors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return null;
  }
}

class TeacherPermissionData {
  const TeacherPermissionData({required this.sessions, required this.requests});

  final List<TeacherPermissionSession> sessions;
  final List<TeacherPermissionRequest> requests;
}

class TeacherPermissionSession {
  const TeacherPermissionSession({
    required this.id,
    required this.subject,
    required this.room,
    required this.status,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  final int id;
  final String subject;
  final String room;
  final String status;
  final String date;
  final String startTime;
  final String endTime;

  String get label => '$subject - $date - $startTime';

  DateTime? get sessionDate => DateTime.tryParse(date);

  factory TeacherPermissionSession.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] is Map
        ? (json['subject'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final classRoom = json['class_room'] is Map
        ? (json['class_room'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return TeacherPermissionSession(
      id: _int(json['id']),
      subject: subject['name'] as String? ?? 'Class',
      room:
          classRoom['room_number'] as String? ??
          json['room_number'] as String? ??
          'TBD',
      status: json['attendance_status'] as String? ?? 'scheduled',
      date: '${json['attendance_date'] ?? 'N/A'}',
      startTime: _shortTime(json['scheduled_start_time']),
      endTime: _shortTime(json['scheduled_end_time']),
    );
  }
}

class TeacherPermissionRequest {
  const TeacherPermissionRequest({
    required this.id,
    required this.subject,
    required this.date,
    required this.status,
    required this.requestedStatus,
    required this.reason,
    required this.reviewNote,
  });

  final int id;
  final String subject;
  final String date;
  final String status;
  final String requestedStatus;
  final String reason;
  final String reviewNote;

  factory TeacherPermissionRequest.fromJson(Map<String, dynamic> json) {
    final session = json['attendance_session'] is Map
        ? (json['attendance_session'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final subject = session['subject'] is Map
        ? (session['subject'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return TeacherPermissionRequest(
      id: _int(json['id']),
      subject: subject['name'] as String? ?? 'Teacher permission',
      date: '${session['attendance_date'] ?? json['created_at'] ?? 'N/A'}',
      status: json['status'] as String? ?? 'pending',
      requestedStatus: json['requested_status'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      reviewNote: json['review_note'] as String? ?? '',
    );
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

String _shortTime(Object? value) {
  final raw = '$value';
  if (raw.isEmpty || raw == 'null') return 'TBD';
  final date = DateTime.tryParse(raw);
  if (date == null) return raw.length >= 5 ? raw.substring(0, 5) : raw;
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _typeLabel(String value) {
  return switch (value) {
    'sick' => 'Sick leave',
    'event' => 'School event',
    'personal' => 'Personal permission',
    'official' => 'Official duty',
    _ => 'Permission',
  };
}
