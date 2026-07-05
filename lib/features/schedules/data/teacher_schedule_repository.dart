import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class TeacherScheduleRepository {
  TeacherScheduleRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<List<TeacherScheduleItem>> fetchAllSchedules() async {
    final firstPage = await fetchSchedules(page: 1);
    final items = [...firstPage.items];

    for (var page = 2; page <= firstPage.lastPage; page++) {
      final nextPage = await fetchSchedules(page: page);
      items.addAll(nextPage.items);
    }

    return items;
  }

  Future<TeacherSchedulePage> fetchSchedules({int page = 1}) async {
    final token = await _sessionStore.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again.');
    }

    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/teacher/attendance/schedules?page=$page&per_page=100',
      ),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _asMap(decoded);
      throw ApiException(
        body['message'] as String? ??
            body['error'] as String? ??
            'Could not load teacher schedules.',
        statusCode: response.statusCode,
      );
    }

    return TeacherSchedulePage.fromJson(_asMap(decoded));
  }

  Object? _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The server returned an invalid schedules response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class TeacherSchedulePage {
  const TeacherSchedulePage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<TeacherScheduleItem> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory TeacherSchedulePage.fromJson(Map<String, dynamic> json) {
    return TeacherSchedulePage(
      items: _asList(
        json['data'],
      ).map((item) => TeacherScheduleItem.fromJson(item)).toList(),
      currentPage: _int(json['current_page']),
      lastPage: _int(json['last_page']),
      perPage: _int(json['per_page']),
      total: _int(json['total']),
    );
  }
}

class TeacherScheduleItem {
  const TeacherScheduleItem({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.groupName,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.sessionNumber,
    required this.status,
    required this.semester,
    required this.academicYear,
  });

  final int id;
  final String subjectName;
  final String subjectCode;
  final String groupName;
  final String room;
  final DateTime? startTime;
  final DateTime? endTime;
  final int sessionNumber;
  final String status;
  final String semester;
  final String academicYear;

  factory TeacherScheduleItem.fromJson(Map<String, dynamic> json) {
    final subject = _asMap(json['subject']);
    final classGroup = _asMap(json['class_group']);
    final classRoom = _asMap(json['class_room']);
    final attendanceSession = _asMap(json['attendance_session']);
    final sourceAttendanceSession = _asMap(json['source_attendance_session']);

    return TeacherScheduleItem(
      id: _int(json['id']),
      subjectName: subject['name'] as String? ?? 'Class',
      subjectCode: subject['code'] as String? ?? 'N/A',
      groupName: classGroup['name'] as String? ?? 'N/A',
      room:
          json['room_name'] as String? ??
          classRoom['room_number'] as String? ??
          classRoom['room'] as String? ??
          'TBD',
      startTime: _date(json['scheduled_start_time']),
      endTime: _date(json['scheduled_end_time']),
      sessionNumber: _int(json['session_number']),
      status:
          sourceAttendanceSession['status'] as String? ??
          attendanceSession['attendance_status'] as String? ??
          attendanceSession['status'] as String? ??
          json['status'] as String? ??
          'scheduled',
      semester: '${json['semester'] ?? ''}'.trim(),
      academicYear: '${json['academic_year'] ?? ''}'.trim(),
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

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse('$value');
}
