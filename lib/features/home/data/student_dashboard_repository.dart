import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class StudentDashboardRepository {
  StudentDashboardRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<StudentDashboard> fetchDashboard() async {
    final token = await _sessionStore.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again.');
    }

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/student/portal'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['message'] as String? ?? 'Could not load dashboard.',
        statusCode: response.statusCode,
      );
    }

    return StudentDashboard.fromJson(decoded);
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        'The server returned an invalid dashboard response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class StudentDashboard {
  const StudentDashboard({
    required this.student,
    required this.termLabel,
    required this.standing,
    required this.stats,
    required this.monthAttendance,
    required this.performance,
    required this.comparison,
    required this.schedules,
    required this.weekSchedules,
    required this.services,
    required this.activeSession,
  });

  final DashboardStudent student;
  final String termLabel;
  final String standing;
  final DashboardStats stats;
  final DashboardMonthAttendance monthAttendance;
  final List<DashboardPerformance> performance;
  final List<DashboardComparison> comparison;
  final List<DashboardSchedule> schedules;
  final List<DashboardSchedule> weekSchedules;
  final List<DashboardService> services;
  final DashboardActiveSession? activeSession;

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    return StudentDashboard(
      student: DashboardStudent.fromJson(
        json['student'] as Map<String, dynamic>? ?? {},
      ),
      termLabel: json['term_label'] as String? ?? 'Current Academic Term',
      standing: json['standing'] as String? ?? 'Current standing',
      stats: DashboardStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
      monthAttendance: DashboardMonthAttendance.fromJson(
        json['month_attendance'] as Map<String, dynamic>? ?? {},
      ),
      performance: _list(
        json['performance'],
      ).map((item) => DashboardPerformance.fromJson(item)).toList(),
      comparison: _list(
        json['comparison'],
      ).map((item) => DashboardComparison.fromJson(item)).toList(),
      schedules: _list(
        json['schedules'],
      ).map((item) => DashboardSchedule.fromJson(item)).toList(),
      weekSchedules: _list(
        json['week_schedules'],
      ).map((item) => DashboardSchedule.fromJson(item)).toList(),
      services: _list(
        json['services'],
      ).map((item) => DashboardService.fromJson(item)).toList(),
      activeSession: json['active_session'] is Map
          ? DashboardActiveSession.fromJson(
              (json['active_session'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  static List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}

class DashboardActiveSession {
  const DashboardActiveSession({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.status,
  });

  final int id;
  final String subject;
  final String teacher;
  final String room;
  final String status;

  factory DashboardActiveSession.fromJson(Map<String, dynamic> json) {
    return DashboardActiveSession(
      id: _int(json['id']),
      subject: json['subject'] as String? ?? 'N/A',
      teacher: json['teacher'] as String? ?? 'N/A',
      room: json['room'] as String? ?? 'TBD',
      status: json['status'] as String? ?? 'scheduled',
    );
  }
}

class DashboardMonthAttendance {
  const DashboardMonthAttendance({
    required this.monthLabel,
    required this.records,
    required this.present,
    required this.late,
    required this.absent,
    required this.permission,
    required this.issues,
    required this.statuses,
    required this.blacklisted,
  });

  final String monthLabel;
  final int records;
  final int present;
  final int late;
  final int absent;
  final int permission;
  final int issues;
  final List<DashboardAttendanceStatus> statuses;
  final bool blacklisted;

  factory DashboardMonthAttendance.fromJson(Map<String, dynamic> json) {
    return DashboardMonthAttendance(
      monthLabel: json['month_label'] as String? ?? '',
      records: _int(json['records']),
      present: _int(json['present']),
      late: _int(json['late']),
      absent: _int(json['absent']),
      permission: _int(json['permission']),
      issues: _int(json['issues']),
      statuses: StudentDashboard._list(
        json['statuses'],
      ).map((item) => DashboardAttendanceStatus.fromJson(item)).toList(),
      blacklisted: json['blacklisted'] == true,
    );
  }
}

class DashboardAttendanceStatus {
  const DashboardAttendanceStatus({
    required this.status,
    required this.label,
    required this.count,
  });

  final String status;
  final String label;
  final int count;

  factory DashboardAttendanceStatus.fromJson(Map<String, dynamic> json) {
    return DashboardAttendanceStatus(
      status: json['status'] as String? ?? '',
      label: json['label'] as String? ?? json['status'] as String? ?? 'Status',
      count: _int(json['count']),
    );
  }
}

class DashboardStudent {
  const DashboardStudent({
    required this.name,
    required this.code,
    required this.group,
    required this.major,
    required this.profilePhotoUrl,
  });

  final String name;
  final String code;
  final String group;
  final String major;
  final String profilePhotoUrl;

  factory DashboardStudent.fromJson(Map<String, dynamic> json) {
    return DashboardStudent(
      name: json['name'] as String? ?? 'Student',
      code: json['code'] as String? ?? 'N/A',
      group: json['group'] as String? ?? 'N/A',
      major: json['major'] as String? ?? 'N/A',
      profilePhotoUrl:
          json['profile_photo_url'] as String? ??
          json['primary_photo_url'] as String? ??
          '',
    );
  }
}

class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.present,
    required this.absent,
    required this.rate,
    required this.remaining,
  });

  final int total;
  final int present;
  final int absent;
  final int rate;
  final int remaining;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      total: _int(json['total']),
      present: _int(json['present']),
      absent: _int(json['absent']),
      rate: _int(json['rate']),
      remaining: _int(json['remaining']),
    );
  }
}

class DashboardPerformance {
  const DashboardPerformance({
    required this.label,
    required this.value,
    required this.detail,
    required this.progress,
  });

  final String label;
  final String value;
  final String detail;
  final int progress;

  factory DashboardPerformance.fromJson(Map<String, dynamic> json) {
    return DashboardPerformance(
      label: json['label'] as String? ?? 'Metric',
      value: '${json['value'] ?? '0'}',
      detail: json['detail'] as String? ?? '',
      progress: _int(json['progress']),
    );
  }
}

class DashboardComparison {
  const DashboardComparison({required this.label, required this.score});

  final String label;
  final int score;

  factory DashboardComparison.fromJson(Map<String, dynamic> json) {
    return DashboardComparison(
      label: json['label'] as String? ?? 'Metric',
      score: _int(json['score']),
    );
  }
}

class DashboardSchedule {
  const DashboardSchedule({
    required this.time,
    required this.date,
    required this.dayLabel,
    required this.title,
    required this.room,
    required this.teacher,
    required this.status,
  });

  final String time;
  final String date;
  final String dayLabel;
  final String title;
  final String room;
  final String teacher;
  final String status;

  factory DashboardSchedule.fromJson(Map<String, dynamic> json) {
    return DashboardSchedule(
      time: json['time'] as String? ?? 'TBD',
      date: json['date'] as String? ?? '',
      dayLabel: json['day_label'] as String? ?? '',
      title: json['title'] as String? ?? 'Class',
      room: json['room'] as String? ?? 'TBD',
      teacher: json['teacher'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'scheduled',
    );
  }
}

class DashboardService {
  const DashboardService({required this.label, required this.icon});

  final String label;
  final String icon;

  factory DashboardService.fromJson(Map<String, dynamic> json) {
    return DashboardService(
      label: json['label'] as String? ?? 'Service',
      icon: json['icon'] as String? ?? 'service',
    );
  }
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse('$value') ?? 0;
}
