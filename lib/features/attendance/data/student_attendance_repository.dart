import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class StudentAttendanceRepository {
  StudentAttendanceRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<List<StudentAttendanceSubject>> fetchSubjects() async {
    final token = await _token();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/student/classes'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _asMap(decoded)['message'] as String? ?? 'Could not load attendance.',
        statusCode: response.statusCode,
      );
    }

    final classes = _asList(
      decoded,
    ).map((item) => StudentAttendanceSubject.fromJson(item)).toList();

    final withHistory = await Future.wait(
      classes.map((item) => _fetchSubjectHistory(item, token)),
    );
    withHistory.sort((a, b) {
      final groupCompare = a.group.compareTo(b.group);
      if (groupCompare != 0) return groupCompare;
      return a.name.compareTo(b.name);
    });
    return withHistory;
  }

  Future<StudentAttendanceSubject> _fetchSubjectHistory(
    StudentAttendanceSubject subject,
    String token,
  ) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/student/classes/${subject.id}/history'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _asMap(decoded)['message'] as String? ??
            'Could not load attendance history.',
        statusCode: response.statusCode,
      );
    }

    final body = _asMap(decoded);
    final classBody = _asMap(body['class']);
    return subject.copyWith(
      name: classBody['name'] as String? ?? subject.name,
      group: classBody['group'] as String? ?? subject.group,
      teacher: classBody['teacher'] as String? ?? subject.teacher,
      history: _asList(
        body['history'],
      ).map((item) => StudentAttendanceRecord.fromJson(item)).toList(),
    );
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
        'The server returned an invalid attendance response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class StudentAttendanceSubject {
  const StudentAttendanceSubject({
    required this.id,
    required this.name,
    required this.code,
    required this.group,
    required this.teacher,
    required this.sessionsCount,
    required this.attendedCount,
    required this.attendanceRate,
    required this.remainingSessions,
    this.history = const [],
  });

  final int id;
  final String name;
  final String code;
  final String group;
  final String teacher;
  final int sessionsCount;
  final int attendedCount;
  final int attendanceRate;
  final int remainingSessions;
  final List<StudentAttendanceRecord> history;

  int get presentCount => history.where((item) => item.isPresent).length;
  int get absentCount => history.where((item) => item.isAbsent).length;
  int get permissionCount => history.where((item) => item.isPermission).length;
  int get lateCount => history.where((item) => item.isLate).length;

  StudentAttendanceSubject copyWith({
    String? name,
    String? group,
    String? teacher,
    List<StudentAttendanceRecord>? history,
  }) {
    return StudentAttendanceSubject(
      id: id,
      name: name ?? this.name,
      code: code,
      group: group ?? this.group,
      teacher: teacher ?? this.teacher,
      sessionsCount: sessionsCount,
      attendedCount: attendedCount,
      attendanceRate: attendanceRate,
      remainingSessions: remainingSessions,
      history: history ?? this.history,
    );
  }

  factory StudentAttendanceSubject.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceSubject(
      id: _int(json['id']),
      name: json['name'] as String? ?? 'N/A',
      code: json['code'] as String? ?? 'N/A',
      group: json['group'] as String? ?? 'N/A',
      teacher: json['teacher'] as String? ?? 'N/A',
      sessionsCount: _int(json['sessions_count']),
      attendedCount: _int(json['attended_count']),
      attendanceRate: _int(json['attendance_rate']),
      remainingSessions: _int(json['remaining_sessions']),
    );
  }
}

class StudentAttendanceRecord {
  const StudentAttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    required this.scanTime,
    required this.method,
  });

  final int id;
  final DateTime? date;
  final String status;
  final String scanTime;
  final String method;

  bool get isPresent {
    final lower = status.toLowerCase();
    return lower == 'present';
  }

  bool get isLate => status.toLowerCase() == 'late';

  bool get isPermission {
    final lower = status.toLowerCase();
    return lower == 'excused' || lower == 'permission';
  }

  bool get isAbsent => status.toLowerCase() == 'absent';

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRecord(
      id: _int(json['id']),
      date: DateTime.tryParse('${json['date'] ?? ''}'),
      status: json['status'] as String? ?? 'SCHEDULED',
      scanTime: json['scan_time'] as String? ?? '',
      method: json['method'] as String? ?? '',
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
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
