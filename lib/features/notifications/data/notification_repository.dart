import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:hru_atms/features/home/data/teacher_dashboard_repository.dart';
import 'package:http/http.dart' as http;

class NotificationRepository {
  NotificationRepository({http.Client? client, AuthSessionStore? sessionStore})
    : _client = client ?? http.Client(),
      _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<AppNotificationFeed> fetchNotifications() async {
    final token = await _token();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/chat/notifications'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _asMap(decoded)['message'] as String? ??
            'Could not load notifications.',
        statusCode: response.statusCode,
      );
    }

    final body = _asMap(decoded);
    final notifications = _asMap(body['notifications']);
    final items = _asList(
      notifications['data'],
    ).map((item) => AppNotification.fromJson(item)).toList();
    final scheduleAlerts = await _fetchTeacherScheduleAlerts(token);
    final studentScheduleAlerts = await _fetchStudentScheduleAlerts(token);
    final studentPermissionAlerts = await _fetchStudentPermissionAlerts(token);
    final teacherPermissionAlerts = await _fetchTeacherPermissionAlerts(token);
    final generatedAlerts = [
      ...studentScheduleAlerts,
      ...studentPermissionAlerts,
      ...scheduleAlerts,
      ...teacherPermissionAlerts,
    ];

    return AppNotificationFeed(
      unreadCount:
          _int(body['unread_count']) +
          generatedAlerts.where((item) => !item.isRead).length,
      items: [...generatedAlerts, ...items],
    );
  }

  Future<void> markAllRead() async {
    final token = await _token();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/chat/notifications/read'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _asMap(decoded)['message'] as String? ??
            'Could not mark notifications read.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<String> _token() async {
    final token = await _sessionStore.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again.');
    }
    return token;
  }

  Future<List<AppNotification>> _fetchTeacherScheduleAlerts(
    String token,
  ) async {
    final role = await _sessionStore.userRole();
    if (role != 'teacher') return const [];

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/teacher/sessions'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decoded = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final now = DateTime.now();
      final sessions =
          _asList(decoded).map((item) => TeacherSession.fromJson(item)).where((
            session,
          ) {
            final start = session.startTime?.toLocal();
            if (start == null || !start.isAfter(now)) return false;
            return start.difference(now) <= const Duration(hours: 48);
          }).toList()..sort((a, b) => a.startTime!.compareTo(b.startTime!));

      return sessions.map((session) {
        final start = session.startTime!.toLocal();
        final status = _scheduleStatus(now, start);
        return AppNotification(
          id: 'teacher_session_${session.id}',
          title: 'Upcoming class',
          message:
              '${session.subjectName} - ${_dateTime(start)} - Room ${session.room}',
          type: 'TeacherSessionReminder',
          createdAt: _dateTime(start),
          isRead: false,
          status: status,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AppNotification>> _fetchStudentScheduleAlerts(
    String token,
  ) async {
    final role = await _sessionStore.userRole();
    if (role != 'student') return const [];

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/student/portal'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decoded = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final now = DateTime.now();
      final body = _asMap(decoded);
      final schedules =
          [
              ..._asList(body['schedules']),
              ..._asList(body['week_schedules']),
            ].where((item) {
              final start = _studentScheduleStart(item);
              if (start == null || !start.isAfter(now)) return false;
              return start.difference(now) <= const Duration(hours: 48);
            }).toList()
            ..sort((a, b) {
              final first = _studentScheduleStart(a);
              final second = _studentScheduleStart(b);
              if (first == null || second == null) return 0;
              return first.compareTo(second);
            });

      return schedules.map((schedule) {
        final start = _studentScheduleStart(schedule)!;
        final status = _scheduleStatus(now, start);
        final subject = schedule['title'] as String? ?? 'Class';
        final room = schedule['room'] as String? ?? 'TBD';
        final teacher = schedule['teacher'] as String? ?? 'N/A';
        return AppNotification(
          id: 'student_schedule_${schedule['id'] ?? '${schedule['date']}_${schedule['time']}'}',
          title: 'Upcoming class',
          message: '$subject - ${_dateTime(start)} - Room $room - $teacher',
          type: 'StudentScheduleReminder',
          createdAt: _dateTime(start),
          isRead: false,
          status: status,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AppNotification>> _fetchTeacherPermissionAlerts(
    String token,
  ) async {
    final role = await _sessionStore.userRole();
    if (role != 'teacher') return const [];

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/teacher/student-permissions'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decoded = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final requests = _asList(_asMap(decoded)['requests']).take(10);
      return requests.map((request) {
        final student = request['student_name'] as String? ?? 'Student';
        final subject = request['subject'] as String? ?? 'Class';
        final status = request['status'] as String? ?? 'pending';
        final createdAt =
            '${request['reviewed_at'] ?? request['created_at'] ?? ''}';
        return AppNotification(
          id: 'teacher_permission_${request['id'] ?? createdAt}',
          title: 'Teacher permission',
          message: '$student - $subject - ${_friendlyType(status)}',
          type: 'TeacherPermissionAlert',
          createdAt: createdAt,
          isRead: false,
          status: status,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AppNotification>> _fetchStudentPermissionAlerts(
    String token,
  ) async {
    final role = await _sessionStore.userRole();
    if (role != 'student') return const [];

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/student/permissions'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final decoded = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      return _asList(_asMap(decoded)['permissions']).take(10).map((request) {
        final status = request['status'] as String? ?? 'pending';
        final start = request['start_date'] as String? ?? '';
        final end = request['end_date'] as String? ?? '';
        final createdAt =
            '${request['reviewed_at'] ?? request['created_at'] ?? ''}';
        return AppNotification(
          id: 'student_permission_${request['id'] ?? createdAt}',
          title: 'Pre-permission',
          message: '$start - $end - ${_friendlyType(status)}',
          type: 'StudentPermissionAlert',
          createdAt: createdAt,
          isRead: status == 'pending',
          status: status,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Object? _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The server returned an invalid notification response.',
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

DateTime? _studentScheduleStart(Map<String, dynamic> schedule) {
  final date = '${schedule['date'] ?? ''}'.trim();
  final time = '${schedule['time'] ?? ''}'.trim();
  if (date.isEmpty || time.isEmpty || time == 'TBD') return null;
  return DateTime.tryParse('$date ${time.length == 5 ? '$time:00' : time}');
}

class AppNotificationFeed {
  const AppNotificationFeed({required this.unreadCount, required this.items});

  final int unreadCount;
  final List<AppNotification> items;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.status = '',
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final String createdAt;
  final bool isRead;
  final String status;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? (json['data'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final type = json['type'] as String? ?? 'notification';
    return AppNotification(
      id: '${json['id'] ?? ''}',
      title:
          data['title'] as String? ??
          data['name'] as String? ??
          _friendlyType(type),
      message:
          data['message'] as String? ??
          data['body'] as String? ??
          data['target'] as String? ??
          data['subject'] as String? ??
          'New notification',
      type: type.split('\\').last,
      createdAt: '${json['created_at'] ?? ''}',
      isRead: json['read_at'] != null,
      status: data['status'] as String? ?? '',
    );
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

String _friendlyType(String type) {
  final short = type.split('\\').last;
  return short
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .trim();
}

String _scheduleStatus(DateTime now, DateTime start) {
  final difference = start.difference(now);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final startDay = DateTime(start.year, start.month, start.day);

  if (startDay == tomorrow) return 'Tomorrow';
  if (difference <= const Duration(hours: 5)) return 'In 5 hours';
  return 'Upcoming';
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
