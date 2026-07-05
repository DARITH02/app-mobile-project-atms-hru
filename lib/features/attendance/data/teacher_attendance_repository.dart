import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class TeacherAttendanceRepository {
  TeacherAttendanceRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<List<TeacherAttendanceSession>> fetchAllSessions() async {
    final firstPage = await fetchSessions(page: 1);
    final items = [...firstPage.items];

    for (var page = 2; page <= firstPage.lastPage; page++) {
      final nextPage = await fetchSessions(page: page);
      items.addAll(nextPage.items);
    }

    final corrections = await fetchAllCorrections();
    return _applyApprovedCorrections(items, corrections);
  }

  Future<List<TeacherAttendanceCorrection>> fetchAllCorrections() async {
    final firstPage = await fetchCorrections(page: 1);
    final items = [...firstPage.items];

    for (var page = 2; page <= firstPage.lastPage; page++) {
      final nextPage = await fetchCorrections(page: page);
      items.addAll(nextPage.items);
    }

    return items;
  }

  Future<TeacherAttendanceSession> qrCheckIn(String token) async {
    final authToken = await _token();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/teacher/attendance/qr/check-in'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'token': token}),
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _asMap(decoded);
      throw ApiException(
        body['message'] as String? ??
            body['error'] as String? ??
            _firstValidationError(body) ??
            'Could not check in with this QR code.',
        statusCode: response.statusCode,
        code: body['code'] as String? ?? '',
        errors: _validationErrors(body),
      );
    }

    return TeacherAttendanceSession.fromJson(
      _asMap(_asMap(decoded)['session']),
    );
  }

  Future<TeacherAttendancePage> fetchSessions({int page = 1}) async {
    final token = await _token();

    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/teacher/attendance/sessions?page=$page&per_page=100',
      ),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _asMap(decoded);
      throw ApiException(
        body['message'] as String? ??
            body['error'] as String? ??
            'Could not load teacher attendance.',
        statusCode: response.statusCode,
      );
    }

    return TeacherAttendancePage.fromJson(_asMap(decoded));
  }

  Future<TeacherAttendanceCorrectionPage> fetchCorrections({
    int page = 1,
  }) async {
    final token = await _token();

    final response = await _client.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/teacher/attendance/corrections?page=$page',
      ),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _asMap(decoded);
      throw ApiException(
        body['message'] as String? ??
            body['error'] as String? ??
            'Could not load teacher attendance corrections.',
        statusCode: response.statusCode,
      );
    }

    return TeacherAttendanceCorrectionPage.fromJson(_asMap(decoded));
  }

  Future<TeacherSessionStudents> fetchSessionStudents(int sessionId) async {
    final token = await _token();

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/teacher/session/$sessionId/monitor'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _asMap(decoded);
      throw ApiException(
        body['message'] as String? ??
            body['error'] as String? ??
            'Could not load session students.',
        statusCode: response.statusCode,
      );
    }

    return TeacherSessionStudents.fromJson(_asMap(decoded));
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

List<TeacherAttendanceSession> _applyApprovedCorrections(
  List<TeacherAttendanceSession> sessions,
  List<TeacherAttendanceCorrection> corrections,
) {
  final correctionBySessionId = <int, TeacherAttendanceCorrection>{};
  for (final correction in corrections) {
    if (correction.attendanceSessionId == 0) continue;
    if (correction.status.toLowerCase() != 'approved') continue;
    if (!_isIssueStatus(correction.requestedStatus)) continue;
    correctionBySessionId.putIfAbsent(
      correction.attendanceSessionId,
      () => correction,
    );
  }

  return sessions.map((session) {
    final correction = correctionBySessionId[session.id];
    if (correction == null) return session;
    return session.copyWith(
      status: correction.requestedStatus,
      correctionStatus: correction.status,
      requestedStatus: correction.requestedStatus,
    );
  }).toList();
}

bool _isIssueStatus(String status) {
  final lower = status.toLowerCase().trim();
  return lower == 'permission' ||
      lower == 'absent' ||
      lower == 'asent' ||
      lower == 'missed';
}

class TeacherAttendancePage {
  const TeacherAttendancePage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  final List<TeacherAttendanceSession> items;
  final int currentPage;
  final int lastPage;

  factory TeacherAttendancePage.fromJson(Map<String, dynamic> json) {
    return TeacherAttendancePage(
      items: _asList(
        json['data'],
      ).map((item) => TeacherAttendanceSession.fromJson(item)).toList(),
      currentPage: _int(json['current_page']),
      lastPage: _int(json['last_page']).clamp(1, 9999),
    );
  }
}

class TeacherAttendanceCorrectionPage {
  const TeacherAttendanceCorrectionPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  final List<TeacherAttendanceCorrection> items;
  final int currentPage;
  final int lastPage;

  factory TeacherAttendanceCorrectionPage.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceCorrectionPage(
      items: _asList(
        json['data'],
      ).map((item) => TeacherAttendanceCorrection.fromJson(item)).toList(),
      currentPage: _int(json['current_page']),
      lastPage: _int(json['last_page']).clamp(1, 9999),
    );
  }
}

class TeacherAttendanceSession {
  const TeacherAttendanceSession({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.groupName,
    required this.room,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.checkInTime,
    required this.checkOutTime,
    required this.status,
    required this.correctionStatus,
    required this.requestedStatus,
  });

  final int id;
  final String subjectName;
  final String subjectCode;
  final String groupName;
  final String room;
  final String date;
  final String startTime;
  final String endTime;
  final String checkInTime;
  final String checkOutTime;
  final String status;
  final String correctionStatus;
  final String requestedStatus;

  bool get hasCheckIn => checkInTime != 'TBD';
  bool get hasCheckOut => checkOutTime != 'TBD';
  DateTime? get attendanceDate => DateTime.tryParse(date);

  TeacherAttendanceSession copyWith({
    String? status,
    String? correctionStatus,
    String? requestedStatus,
  }) {
    return TeacherAttendanceSession(
      id: id,
      subjectName: subjectName,
      subjectCode: subjectCode,
      groupName: groupName,
      room: room,
      date: date,
      startTime: startTime,
      endTime: endTime,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      status: status ?? this.status,
      correctionStatus: correctionStatus ?? this.correctionStatus,
      requestedStatus: requestedStatus ?? this.requestedStatus,
    );
  }

  factory TeacherAttendanceSession.fromJson(Map<String, dynamic> json) {
    final subject = _asMap(json['subject']);
    final classGroup = _asMap(json['class_group']);
    final classRoom = _asMap(json['class_room']);

    return TeacherAttendanceSession(
      id: _int(json['id']),
      subjectName: subject['name'] as String? ?? 'Class',
      subjectCode: subject['code'] as String? ?? 'N/A',
      groupName: classGroup['name'] as String? ?? 'N/A',
      room:
          json['room_name'] as String? ??
          classRoom['room_number'] as String? ??
          classRoom['room'] as String? ??
          'TBD',
      date: '${json['attendance_date'] ?? 'N/A'}',
      startTime: _shortTime(json['scheduled_start_time']),
      endTime: _shortTime(json['scheduled_end_time']),
      checkInTime: _shortTime(json['check_in_time']),
      checkOutTime: _shortTime(json['check_out_time']),
      status:
          json['attendance_status'] as String? ??
          json['status'] as String? ??
          'scheduled',
      correctionStatus:
          _asMap(json['latest_correction'])['status'] as String? ??
          _asMap(json['correction'])['status'] as String? ??
          '',
      requestedStatus:
          _asMap(json['latest_correction'])['requested_status'] as String? ??
          _asMap(json['correction'])['requested_status'] as String? ??
          '',
    );
  }
}

class TeacherAttendanceCorrection {
  const TeacherAttendanceCorrection({
    required this.id,
    required this.attendanceSessionId,
    required this.status,
    required this.requestedStatus,
  });

  final int id;
  final int attendanceSessionId;
  final String status;
  final String requestedStatus;

  factory TeacherAttendanceCorrection.fromJson(Map<String, dynamic> json) {
    final session = _asMap(json['attendance_session']);
    return TeacherAttendanceCorrection(
      id: _int(json['id']),
      attendanceSessionId: _int(json['attendance_session_id'] ?? session['id']),
      status: '${json['status'] ?? 'pending'}',
      requestedStatus: '${json['requested_status'] ?? ''}',
    );
  }
}

class TeacherSessionStudents {
  const TeacherSessionStudents({
    required this.presentCount,
    required this.excusedCount,
    required this.totalCount,
    required this.students,
  });

  final int presentCount;
  final int excusedCount;
  final int totalCount;
  final List<TeacherSessionStudent> students;

  factory TeacherSessionStudents.fromJson(Map<String, dynamic> json) {
    return TeacherSessionStudents(
      presentCount: _int(json['present_count']),
      excusedCount: _int(json['excused_count']),
      totalCount: _int(json['total_count']),
      students: _asList(
        json['data'],
      ).map((item) => TeacherSessionStudent.fromJson(item)).toList(),
    );
  }
}

class TeacherSessionStudent {
  const TeacherSessionStudent({
    required this.id,
    required this.name,
    required this.studentCode,
    required this.groupName,
    required this.majorName,
    required this.status,
    required this.permissionReason,
    required this.permissionType,
    required this.permissionStatus,
    required this.checkInTime,
    required this.method,
  });

  final int id;
  final String name;
  final String studentCode;
  final String groupName;
  final String majorName;
  final String status;
  final String permissionReason;
  final String permissionType;
  final String permissionStatus;
  final String checkInTime;
  final String method;

  bool get hasPermission => permissionStatus.isNotEmpty;

  factory TeacherSessionStudent.fromJson(Map<String, dynamic> json) {
    return TeacherSessionStudent(
      id: _int(json['id']),
      name: json['name'] as String? ?? 'Student',
      studentCode: json['student_code'] as String? ?? 'N/A',
      groupName: json['group_name'] as String? ?? '',
      majorName: json['major_name'] as String? ?? '',
      status: json['status'] as String? ?? 'ABSENT',
      permissionReason: json['permission_reason'] as String? ?? '',
      permissionType: json['permission_type'] as String? ?? '',
      permissionStatus: json['permission_status'] as String? ?? '',
      checkInTime: _cleanDetail(json['check_in_time']),
      method: _cleanDetail(json['method']),
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

String _cleanDetail(Object? value) {
  final text = '${value ?? ''}'.trim();
  if (!RegExp(r'[A-Za-z0-9]').hasMatch(text)) return '';
  return text;
}

String _shortTime(Object? value) {
  final raw = '$value';
  if (raw.isEmpty || raw == 'null') return 'TBD';
  final date = DateTime.tryParse(raw);
  if (date == null) return raw.length >= 5 ? raw.substring(0, 5) : raw;
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String? _firstValidationError(Map<String, dynamic> body) {
  final errors = body['errors'];
  if (errors is! Map || errors.isEmpty) return null;
  final first = errors.values.first;
  if (first is List && first.isNotEmpty) return '${first.first}';
  return '$first';
}

Map<String, List<String>> _validationErrors(Map<String, dynamic> body) {
  final errors = body['errors'];
  if (errors is! Map || errors.isEmpty) return const {};

  return errors.map((key, value) {
    if (value is List) {
      return MapEntry('$key', value.map((item) => '$item').toList());
    }

    return MapEntry('$key', ['$value']);
  });
}
