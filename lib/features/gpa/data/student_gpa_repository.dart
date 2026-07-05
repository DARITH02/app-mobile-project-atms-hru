import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class StudentGpaRepository {
  StudentGpaRepository({http.Client? client, AuthSessionStore? sessionStore})
    : _client = client ?? http.Client(),
      _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<StudentGpaTranscript> fetchTranscript() async {
    final token = await _token();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/student/transcript'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _asMap(decoded)['message'] as String? ??
            'Could not load GPA transcript.',
        statusCode: response.statusCode,
      );
    }

    return StudentGpaTranscript.fromJson(_asMap(decoded));
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
        'The server returned an invalid GPA transcript response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class StudentGpaTranscript {
  const StudentGpaTranscript({
    required this.student,
    required this.summary,
    required this.histories,
  });

  final GpaStudent student;
  final GpaSummary summary;
  final List<GpaSemesterHistory> histories;

  factory StudentGpaTranscript.fromJson(Map<String, dynamic> json) {
    return StudentGpaTranscript(
      student: GpaStudent.fromJson(_asMap(json['student'])),
      summary: GpaSummary.fromJson(_asMap(json['summary'])),
      histories: _asList(
        json['histories'],
      ).map(GpaSemesterHistory.fromJson).toList(),
    );
  }
}

class GpaStudent {
  const GpaStudent({
    required this.name,
    required this.studentCode,
    required this.group,
    required this.major,
    required this.yearLevel,
  });

  final String name;
  final String studentCode;
  final String group;
  final String major;
  final String yearLevel;

  factory GpaStudent.fromJson(Map<String, dynamic> json) {
    return GpaStudent(
      name: json['name'] as String? ?? 'N/A',
      studentCode: json['student_code'] as String? ?? 'N/A',
      group: json['group'] as String? ?? 'N/A',
      major: json['major'] as String? ?? 'N/A',
      yearLevel: '${json['year_level'] ?? 'N/A'}',
    );
  }
}

class GpaSummary {
  const GpaSummary({
    required this.semesterCount,
    required this.totalCredits,
    required this.latestGpa,
    required this.cumulativeGpa,
  });

  final int semesterCount;
  final double totalCredits;
  final double latestGpa;
  final double cumulativeGpa;

  factory GpaSummary.fromJson(Map<String, dynamic> json) {
    return GpaSummary(
      semesterCount: _int(json['semester_count']),
      totalCredits: _double(json['total_credits']),
      latestGpa: _double(json['latest_gpa']),
      cumulativeGpa: _double(json['cumulative_gpa']),
    );
  }
}

class GpaSemesterHistory {
  const GpaSemesterHistory({
    required this.academicYear,
    required this.semester,
    required this.yearLevel,
    required this.classGroupName,
    required this.majorName,
    required this.totalCredits,
    required this.semesterGpa,
    required this.cumulativeGpa,
    required this.resultStatus,
    required this.finalizedAt,
    required this.subjectGrades,
  });

  final String academicYear;
  final int semester;
  final String yearLevel;
  final String classGroupName;
  final String majorName;
  final double totalCredits;
  final double semesterGpa;
  final double cumulativeGpa;
  final String resultStatus;
  final String finalizedAt;
  final List<GpaSubjectGrade> subjectGrades;

  String get label => '$academicYear S$semester';

  factory GpaSemesterHistory.fromJson(Map<String, dynamic> json) {
    return GpaSemesterHistory(
      academicYear: json['academic_year'] as String? ?? 'N/A',
      semester: _int(json['semester']),
      yearLevel: '${json['year_level'] ?? 'N/A'}',
      classGroupName: json['class_group_name'] as String? ?? 'N/A',
      majorName: json['major_name'] as String? ?? 'N/A',
      totalCredits: _double(json['total_credits']),
      semesterGpa: _double(json['semester_gpa']),
      cumulativeGpa: _double(json['cumulative_gpa']),
      resultStatus: json['result_status'] as String? ?? 'N/A',
      finalizedAt: json['finalized_at'] as String? ?? '',
      subjectGrades: _asList(
        json['subject_grades'],
      ).map(GpaSubjectGrade.fromJson).toList(),
    );
  }
}

class GpaSubjectGrade {
  const GpaSubjectGrade({
    required this.subjectName,
    required this.subjectCode,
    required this.credit,
    required this.attendanceScore,
    required this.midtermScore,
    required this.assignmentScore,
    required this.finalScore,
    required this.totalScore,
    required this.letterGrade,
    required this.gradePoint,
  });

  final String subjectName;
  final String subjectCode;
  final double credit;
  final double attendanceScore;
  final double midtermScore;
  final double assignmentScore;
  final double finalScore;
  final double totalScore;
  final String letterGrade;
  final double gradePoint;

  factory GpaSubjectGrade.fromJson(Map<String, dynamic> json) {
    return GpaSubjectGrade(
      subjectName: json['subject_name'] as String? ?? 'N/A',
      subjectCode: json['subject_code'] as String? ?? 'N/A',
      credit: _double(json['credit']),
      attendanceScore: _double(json['attendance_score']),
      midtermScore: _double(json['midterm_score']),
      assignmentScore: _double(json['assignment_score']),
      finalScore: _double(json['final_score']),
      totalScore: _double(json['total_score']),
      letterGrade: json['letter_grade'] as String? ?? 'N/A',
      gradePoint: _double(json['grade_point']),
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

double _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
