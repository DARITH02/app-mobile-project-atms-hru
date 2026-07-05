import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:hru_atms/features/home/data/teacher_dashboard_repository.dart';
import 'package:http/http.dart' as http;

class TeacherStudentsRepository {
  TeacherStudentsRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<List<TeacherClassStudents>> fetchClassStudents() async {
    final token = await _token();
    final classes = _asList(
      await _get('/teacher/classes', token),
    ).map((item) => TeacherClass.fromJson(item)).toList();

    final groups = await Future.wait(
      classes.map((classRoom) async {
        final students =
            _asList(
                await _get('/teacher/classes/${classRoom.id}/students', token),
              ).map((item) => TeacherClassStudent.fromJson(item)).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

        return TeacherClassStudents(classRoom: classRoom, students: students);
      }),
    );

    groups.sort((a, b) => a.classRoom.name.compareTo(b.classRoom.name));
    return groups;
  }

  Future<TeacherStudentDetail> fetchStudentDetail(int studentId) async {
    final token = await _token();
    return TeacherStudentDetail.fromJson(
      _asMap(await _get('/teacher/students/$studentId/detail', token)),
    );
  }

  Future<Object?> _get(String path, String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _asMap(decoded);
      throw ApiException(
        body['message'] as String? ??
            body['error'] as String? ??
            'Could not load teacher students.',
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
        'The server returned an invalid students response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class TeacherClassStudents {
  const TeacherClassStudents({required this.classRoom, required this.students});

  final TeacherClass classRoom;
  final List<TeacherClassStudent> students;
}

class TeacherClassStudent {
  const TeacherClassStudent({
    required this.id,
    required this.name,
    required this.studentCode,
    required this.groupName,
    required this.majorName,
    required this.departmentName,
    required this.attendancePercentage,
    required this.status,
    this.email = 'N/A',
    this.phone = 'N/A',
    this.accountStatus = 'N/A',
    this.studentStatus = 'N/A',
    this.yearLevel = 'N/A',
    this.createdAt = 'N/A',
    this.updatedAt = 'N/A',
    this.blacklistSemesters = 'N/A',
  });

  final int id;
  final String name;
  final String studentCode;
  final String groupName;
  final String majorName;
  final String departmentName;
  final int attendancePercentage;
  final String status;
  final String email;
  final String phone;
  final String accountStatus;
  final String studentStatus;
  final String yearLevel;
  final String createdAt;
  final String updatedAt;
  final String blacklistSemesters;

  factory TeacherClassStudent.fromJson(Map<String, dynamic> json) {
    final group = _asMap(json['group']);
    final major = _asMap(json['major']);
    final department = _asMap(json['department']);

    return TeacherClassStudent(
      id: _int(json['id']),
      name: json['name'] as String? ?? 'Student',
      studentCode: json['student_code'] as String? ?? 'N/A',
      groupName: group['name'] as String? ?? 'N/A',
      majorName: major['name'] as String? ?? 'N/A',
      departmentName: department['name'] as String? ?? 'N/A',
      attendancePercentage: _int(json['attendance_percentage']),
      status: json['status'] as String? ?? 'N/A',
      studentStatus: json['status'] as String? ?? 'N/A',
    );
  }
}

class TeacherStudentDetail {
  const TeacherStudentDetail({
    required this.student,
    required this.stats,
    required this.history,
  });

  final TeacherClassStudent student;
  final TeacherStudentStats stats;
  final List<TeacherStudentHistoryItem> history;

  factory TeacherStudentDetail.fromJson(Map<String, dynamic> json) {
    final studentJson = _asMap(json['student']);
    final user = _asMap(studentJson['user']);
    final group = _asMap(studentJson['group']);
    final major = _asMap(studentJson['major']);
    final department = _asMap(major['department']);

    return TeacherStudentDetail(
      student: TeacherClassStudent(
        id: _int(studentJson['id']),
        name:
            user['name'] as String? ??
            studentJson['name'] as String? ??
            'Student',
        studentCode: studentJson['student_code'] as String? ?? 'N/A',
        groupName: group['name'] as String? ?? 'N/A',
        majorName: major['name'] as String? ?? 'N/A',
        departmentName: department['name'] as String? ?? 'N/A',
        attendancePercentage: _int(_asMap(json['stats'])['attendance_rate']),
        status: studentJson['status'] as String? ?? '',
        email: user['email'] as String? ?? 'N/A',
        phone: user['phone'] as String? ?? 'N/A',
        accountStatus: user['status'] as String? ?? 'N/A',
        studentStatus: studentJson['status'] as String? ?? 'N/A',
        yearLevel:
            '${group['year_level'] ?? studentJson['year_level'] ?? 'N/A'}',
        createdAt: '${studentJson['created_at'] ?? 'N/A'}',
        updatedAt: '${studentJson['updated_at'] ?? 'N/A'}',
        blacklistSemesters: _stringList(studentJson['blacklist_semesters']),
      ),
      stats: TeacherStudentStats.fromJson(_asMap(json['stats'])),
      history: _asList(
        json['history'],
      ).map((item) => TeacherStudentHistoryItem.fromJson(item)).toList(),
    );
  }
}

class TeacherStudentStats {
  const TeacherStudentStats({
    required this.totalSessions,
    required this.attendedCount,
    required this.excusedCount,
    required this.absentCount,
    required this.attendanceRate,
  });

  final int totalSessions;
  final int attendedCount;
  final int excusedCount;
  final int absentCount;
  final int attendanceRate;

  factory TeacherStudentStats.fromJson(Map<String, dynamic> json) {
    return TeacherStudentStats(
      totalSessions: _int(json['total_sessions']),
      attendedCount: _int(json['attended_count']),
      excusedCount: _int(json['excused_count']),
      absentCount: _int(json['absent_count']),
      attendanceRate: _int(json['attendance_rate']),
    );
  }
}

class TeacherStudentHistoryItem {
  const TeacherStudentHistoryItem({
    required this.subject,
    required this.date,
    required this.status,
    required this.scanTime,
    required this.method,
  });

  final String subject;
  final String date;
  final String status;
  final String scanTime;
  final String method;

  factory TeacherStudentHistoryItem.fromJson(Map<String, dynamic> json) {
    return TeacherStudentHistoryItem(
      subject: json['subject'] as String? ?? 'N/A',
      date: '${json['date'] ?? 'N/A'}',
      status: json['status'] as String? ?? 'N/A',
      scanTime: json['scan_time'] as String? ?? 'N/A',
      method: json['method'] as String? ?? 'N/A',
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

String _stringList(Object? value) {
  if (value == null) return 'N/A';
  if (value is List) {
    if (value.isEmpty) return 'None';
    return value.map((item) => '$item').join(', ');
  }
  return '$value';
}
