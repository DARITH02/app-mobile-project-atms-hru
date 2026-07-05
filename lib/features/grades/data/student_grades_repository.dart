import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class StudentGradesRepository {
  StudentGradesRepository({http.Client? client, AuthSessionStore? sessionStore})
    : _client = client ?? http.Client(),
      _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<StudentGrades> fetchGrades() async {
    final token = await _token();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/student/grades'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 404) {
        return _fetchGradesFromClassHistory(token);
      }
      throw ApiException(
        _asMap(decoded)['message'] as String? ?? 'Could not load grades.',
        statusCode: response.statusCode,
      );
    }

    return StudentGrades.fromJson(_asMap(decoded));
  }

  Future<StudentGrades> _fetchGradesFromClassHistory(String token) async {
    final owner = await _fetchOwner(token);
    final classesResponse = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/student/classes'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final classesDecoded = _decode(classesResponse);

    if (classesResponse.statusCode < 200 || classesResponse.statusCode >= 300) {
      throw ApiException(
        _asMap(classesDecoded)['message'] as String? ??
            'Could not load grades.',
        statusCode: classesResponse.statusCode,
      );
    }

    final classItems = _asList(classesDecoded);
    final subjects = await Future.wait(
      classItems.map((item) => _fetchSubjectFromHistory(item, token)),
    );
    subjects.sort((a, b) {
      final groupCompare = a.group.compareTo(b.group);
      if (groupCompare != 0) return groupCompare;
      return a.subjectName.compareTo(b.subjectName);
    });

    final enteredScores = subjects
        .expand((subject) => subject.scores)
        .where((score) => score.hasScore)
        .toList();
    final averageTotal = _average(
      enteredScores.map((score) => score.totalScore),
    );
    final averageAttendance = _average(
      enteredScores.map((score) => score.attendanceScore),
    );

    return StudentGrades(
      student: owner,
      summary: StudentGradeSummary(
        subjectsCount: subjects.length,
        scoresCount: enteredScores.length,
        averageTotalScore: averageTotal,
        averageAttendanceScore: averageAttendance,
      ),
      subjects: subjects,
    );
  }

  Future<StudentGradeOwner> _fetchOwner(String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/profile'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const StudentGradeOwner(
        name: 'Student',
        studentCode: 'N/A',
        group: 'N/A',
        major: 'N/A',
      );
    }

    final decoded = _asMap(_decode(response));
    final student = _asMap(decoded['student']);
    return StudentGradeOwner(
      name: decoded['name'] as String? ?? 'Student',
      studentCode: student['student_code'] as String? ?? 'N/A',
      group: student['group'] as String? ?? 'N/A',
      major: student['major'] as String? ?? 'N/A',
    );
  }

  Future<StudentGradeSubject> _fetchSubjectFromHistory(
    Map<String, dynamic> classItem,
    String token,
  ) async {
    final classId = _int(classItem['id']);
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/student/classes/$classId/history'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _asMap(decoded)['message'] as String? ??
            'Could not load grade details.',
        statusCode: response.statusCode,
      );
    }

    final body = _asMap(decoded);
    final classBody = _asMap(body['class']);
    return StudentGradeSubject(
      classId: classId,
      subjectName:
          classBody['name'] as String? ?? classItem['name'] as String? ?? 'N/A',
      subjectCode: classItem['code'] as String? ?? 'N/A',
      teacher:
          classBody['teacher'] as String? ??
          classItem['teacher'] as String? ??
          'N/A',
      group:
          classBody['group'] as String? ??
          classItem['group'] as String? ??
          'N/A',
      room: classItem['room'] as String? ?? '',
      schedule: classItem['schedule'] as String? ?? '',
      scores: _asList(
        body['scores'],
      ).map(StudentSubjectScore.fromJson).toList(),
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
        'The server returned an invalid grades response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class StudentGrades {
  const StudentGrades({
    required this.student,
    required this.summary,
    required this.subjects,
  });

  final StudentGradeOwner student;
  final StudentGradeSummary summary;
  final List<StudentGradeSubject> subjects;

  factory StudentGrades.fromJson(Map<String, dynamic> json) {
    return StudentGrades(
      student: StudentGradeOwner.fromJson(_asMap(json['student'])),
      summary: StudentGradeSummary.fromJson(_asMap(json['summary'])),
      subjects: _asList(
        json['subjects'],
      ).map(StudentGradeSubject.fromJson).toList(),
    );
  }
}

class StudentGradeOwner {
  const StudentGradeOwner({
    required this.name,
    required this.studentCode,
    required this.group,
    required this.major,
  });

  final String name;
  final String studentCode;
  final String group;
  final String major;

  factory StudentGradeOwner.fromJson(Map<String, dynamic> json) {
    return StudentGradeOwner(
      name: json['name'] as String? ?? 'N/A',
      studentCode: json['student_code'] as String? ?? 'N/A',
      group: json['group'] as String? ?? 'N/A',
      major: json['major'] as String? ?? 'N/A',
    );
  }
}

class StudentGradeSummary {
  const StudentGradeSummary({
    required this.subjectsCount,
    required this.scoresCount,
    required this.averageTotalScore,
    required this.averageAttendanceScore,
  });

  final int subjectsCount;
  final int scoresCount;
  final double averageTotalScore;
  final double averageAttendanceScore;

  factory StudentGradeSummary.fromJson(Map<String, dynamic> json) {
    return StudentGradeSummary(
      subjectsCount: _int(json['subjects_count']),
      scoresCount: _int(json['scores_count']),
      averageTotalScore: _double(json['average_total_score']),
      averageAttendanceScore: _double(json['average_attendance_score']),
    );
  }
}

class StudentGradeSubject {
  const StudentGradeSubject({
    required this.classId,
    required this.subjectName,
    required this.subjectCode,
    required this.teacher,
    required this.group,
    required this.room,
    required this.schedule,
    required this.scores,
  });

  final int classId;
  final String subjectName;
  final String subjectCode;
  final String teacher;
  final String group;
  final String room;
  final String schedule;
  final List<StudentSubjectScore> scores;

  bool get hasEnteredScore => scores.any((score) => score.hasScore);

  factory StudentGradeSubject.fromJson(Map<String, dynamic> json) {
    return StudentGradeSubject(
      classId: _int(json['class_id']),
      subjectName: json['subject_name'] as String? ?? 'N/A',
      subjectCode: json['subject_code'] as String? ?? 'N/A',
      teacher: json['teacher'] as String? ?? 'N/A',
      group: json['group'] as String? ?? 'N/A',
      room: json['room'] as String? ?? '',
      schedule: json['schedule'] as String? ?? '',
      scores: _asList(
        json['scores'],
      ).map(StudentSubjectScore.fromJson).toList(),
    );
  }
}

class StudentSubjectScore {
  const StudentSubjectScore({
    required this.assignmentId,
    required this.semesterLabel,
    required this.status,
    required this.gradingStatus,
    required this.teacherScore,
    required this.adminScore,
    required this.attendanceScore,
    required this.midtermScore,
    required this.assignmentScore,
    required this.finalScore,
    required this.totalScore,
    required this.letterGrade,
    required this.notes,
    required this.hasScore,
  });

  final int assignmentId;
  final String semesterLabel;
  final String status;
  final String gradingStatus;
  final double teacherScore;
  final double adminScore;
  final double attendanceScore;
  final double midtermScore;
  final double assignmentScore;
  final double finalScore;
  final double totalScore;
  final String letterGrade;
  final String notes;
  final bool hasScore;

  factory StudentSubjectScore.fromJson(Map<String, dynamic> json) {
    return StudentSubjectScore(
      assignmentId: _int(json['assignment_id']),
      semesterLabel: json['semester_label'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'N/A',
      gradingStatus: json['grading_status'] as String? ?? 'N/A',
      teacherScore: _double(json['teacher_score']),
      adminScore: _double(json['admin_score']),
      attendanceScore: _double(json['attendance_score']),
      midtermScore: _double(json['midterm_score']),
      assignmentScore: _double(json['assignment_score']),
      finalScore: _double(json['final_score']),
      totalScore: _double(json['total_score']),
      letterGrade: json['letter_grade'] as String? ?? 'N/A',
      notes: json['notes'] as String? ?? '',
      hasScore: json['has_score'] == true,
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

double _average(Iterable<double> values) {
  if (values.isEmpty) return 0;
  final total = values.fold<double>(0, (sum, value) => sum + value);
  return double.parse((total / values.length).toStringAsFixed(2));
}
