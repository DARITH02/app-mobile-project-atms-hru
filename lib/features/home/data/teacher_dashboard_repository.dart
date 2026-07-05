import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class TeacherDashboardRepository {
  TeacherDashboardRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<TeacherDashboard> fetchDashboard() async {
    final token = await _sessionStore.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again.');
    }

    final responses = await Future.wait([
      _get('/teacher/summary', token),
      _get('/teacher/classes', token),
      _get('/teacher/sessions', token),
    ]);

    final summary = _asMap(responses[0]);
    final classes = _asList(
      responses[1],
    ).map((item) => TeacherClass.fromJson(item)).toList();
    final sessions = _asList(
      responses[2],
    ).map((item) => TeacherSession.fromJson(item)).toList();

    return TeacherDashboard(
      summary: TeacherSummary.fromJson(summary),
      classes: classes,
      sessions: sessions,
    );
  }

  Future<List<TeacherClass>> fetchClasses() async {
    final token = await _sessionStore.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again.');
    }

    return _asList(
      await _get('/teacher/classes', token),
    ).map((item) => TeacherClass.fromJson(item)).toList();
  }

  Future<Object?> _get(String path, String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['message'] as String? ?? decoded['error'] as String?
          : null;
      throw ApiException(
        message ?? 'Could not load teacher dashboard.',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  Object? _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The server returned an invalid dashboard response.',
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
}

class TeacherDashboard {
  const TeacherDashboard({
    required this.summary,
    required this.classes,
    required this.sessions,
  });

  final TeacherSummary summary;
  final List<TeacherClass> classes;
  final List<TeacherSession> sessions;

  int get completedSessions => sessions
      .where((session) => session.status.toLowerCase() == 'completed')
      .length;

  int get scheduledSessions => sessions
      .where((session) => session.status.toLowerCase() == 'scheduled')
      .length;

  List<TeacherClass> get topClasses {
    final sorted = [...classes]
      ..sort((a, b) => b.efficacy.compareTo(a.efficacy));
    return sorted.take(4).toList();
  }

  List<TeacherClass> get attentionClasses {
    final sorted = [...classes]
      ..sort((a, b) => a.efficacy.compareTo(b.efficacy));
    return sorted.take(3).toList();
  }
}

class TeacherSummary {
  const TeacherSummary({
    required this.teacher,
    required this.profilePhotoUrl,
    required this.totalClasses,
    required this.totalStudents,
    required this.totalSessions,
    required this.totalScans,
    required this.attendanceRate,
    required this.activeSessions,
  });

  final String teacher;
  final String profilePhotoUrl;
  final int totalClasses;
  final int totalStudents;
  final int totalSessions;
  final int totalScans;
  final int attendanceRate;
  final int activeSessions;

  factory TeacherSummary.fromJson(Map<String, dynamic> json) {
    return TeacherSummary(
      teacher: json['teacher'] as String? ?? 'Teacher',
      profilePhotoUrl:
          json['profile_photo_url'] as String? ??
          json['primary_photo_url'] as String? ??
          '',
      totalClasses: _int(json['total_classes']),
      totalStudents: _int(json['total_students']),
      totalSessions: _int(json['total_sessions']),
      totalScans: _int(json['total_scans']),
      attendanceRate: _int(json['attendance_rate']),
      activeSessions: _int(json['active_sessions']),
    );
  }
}

class TeacherClass {
  const TeacherClass({
    required this.id,
    required this.name,
    required this.code,
    required this.room,
    required this.groupName,
    required this.schedule,
    required this.sessionsCount,
    required this.totalStudents,
    required this.presenceCount,
    required this.efficacy,
  });

  final int id;
  final String name;
  final String code;
  final String room;
  final String groupName;
  final String schedule;
  final int sessionsCount;
  final int totalStudents;
  final int presenceCount;
  final int efficacy;

  factory TeacherClass.fromJson(Map<String, dynamic> json) {
    return TeacherClass(
      id: _int(json['id']),
      name: json['name'] as String? ?? 'Class',
      code: json['code'] as String? ?? 'N/A',
      room: json['room'] as String? ?? 'TBD',
      groupName: json['group_name'] as String? ?? 'N/A',
      schedule: json['schedule'] as String? ?? 'Schedule pending',
      sessionsCount: _int(json['sessions_count']),
      totalStudents: _int(json['total_students_count']),
      presenceCount: _int(json['presence_count']),
      efficacy: _int(json['efficacy']),
    );
  }
}

class TeacherSession {
  const TeacherSession({
    required this.id,
    required this.classId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.room,
    required this.subjectName,
    required this.subjectCode,
    required this.presenceCount,
    required this.totalStudents,
  });

  final int id;
  final int classId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final String room;
  final String subjectName;
  final String subjectCode;
  final int presenceCount;
  final int totalStudents;

  int get attendanceRate =>
      totalStudents > 0 ? ((presenceCount / totalStudents) * 100).round() : 0;

  factory TeacherSession.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] is Map
        ? (json['subject'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return TeacherSession(
      id: _int(json['id']),
      classId: _int(json['class_id']),
      startTime: _date(json['start_time']),
      endTime: _date(json['end_time']),
      status: json['status'] as String? ?? 'scheduled',
      room: json['room'] as String? ?? 'TBD',
      subjectName: subject['name'] as String? ?? 'Class',
      subjectCode: subject['code'] as String? ?? 'N/A',
      presenceCount: _int(json['presence_count']),
      totalStudents: _int(json['total_students_count']),
    );
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse('$value');
}
