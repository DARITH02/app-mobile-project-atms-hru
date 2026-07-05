import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class StudentProfileRepository {
  StudentProfileRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<StudentProfile> fetchProfile() async {
    final token = await _token();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/profile'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['message'] as String? ?? 'Could not load profile.',
        statusCode: response.statusCode,
      );
    }

    return StudentProfile.fromJson(decoded);
  }

  Future<String> uploadProfilePhoto(XFile image) async {
    final token = await _token();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/profile/photo'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final bytes = await image.readAsBytes();
    final fileName = _normalizedImageName(image.name, image.path);
    final mimeType =
        image.mimeType ??
        lookupMimeType(fileName, headerBytes: bytes) ??
        'image/jpeg';
    final mimeParts = mimeType.split('/');
    request.files.add(
      http.MultipartFile.fromBytes(
        'profile_photo',
        bytes,
        filename: fileName,
        contentType: MediaType(
          mimeParts.first,
          mimeParts.length > 1 ? mimeParts.last : 'jpeg',
        ),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errors = _extractErrors(decoded);
      throw ApiException(
        _firstError(errors) ??
            decoded['message'] as String? ??
            'Could not update profile photo.',
        statusCode: response.statusCode,
        errors: errors,
      );
    }

    return decoded['profile_photo_url'] as String? ?? '';
  }

  Future<String> _token() async {
    final token = await _sessionStore.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again.');
    }
    return token;
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        'The server returned an invalid profile response.',
        statusCode: response.statusCode,
      );
    }
  }

  String _normalizedImageName(String name, String path) {
    final fallback = path.split(RegExp(r'[\\/]')).last;
    final raw = name.isNotEmpty ? name : fallback;
    final safe = raw.trim().isEmpty ? 'profile.jpg' : raw.trim();
    if (safe.contains('.')) return safe;
    return '$safe.jpg';
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

class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.profilePhotoUrl,
    required this.student,
    required this.teacher,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String profilePhotoUrl;
  final StudentProfileDetails? student;
  final TeacherProfileDetails? teacher;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: _int(json['id']),
      name: json['name'] as String? ?? 'Student',
      email: json['email'] as String? ?? 'N/A',
      phone: json['phone'] as String? ?? 'N/A',
      role: json['role'] as String? ?? 'student',
      profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
      student: json['student'] is Map
          ? StudentProfileDetails.fromJson(
              (json['student'] as Map).cast<String, dynamic>(),
            )
          : null,
      teacher: json['teacher'] is Map
          ? TeacherProfileDetails.fromJson(
              (json['teacher'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class TeacherProfileDetails {
  const TeacherProfileDetails({
    required this.id,
    required this.teacherCode,
    required this.department,
    required this.specialization,
    required this.status,
  });

  final int id;
  final String teacherCode;
  final String department;
  final String specialization;
  final String status;

  factory TeacherProfileDetails.fromJson(Map<String, dynamic> json) {
    return TeacherProfileDetails(
      id: _int(json['id']),
      teacherCode: json['teacher_code'] as String? ?? 'N/A',
      department: json['department'] as String? ?? 'N/A',
      specialization: json['specialization'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'N/A',
    );
  }
}

class StudentProfileDetails {
  const StudentProfileDetails({
    required this.id,
    required this.studentCode,
    required this.status,
    required this.group,
    required this.yearLevel,
    required this.major,
    required this.majorCode,
    required this.department,
    required this.profilePhotoUrl,
  });

  final int id;
  final String studentCode;
  final String status;
  final String group;
  final String yearLevel;
  final String major;
  final String majorCode;
  final String department;
  final String profilePhotoUrl;

  factory StudentProfileDetails.fromJson(Map<String, dynamic> json) {
    return StudentProfileDetails(
      id: _int(json['id']),
      studentCode: json['student_code'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'N/A',
      group: json['group'] as String? ?? 'N/A',
      yearLevel: '${json['year_level'] ?? 'N/A'}',
      major: json['major'] as String? ?? 'N/A',
      majorCode: json['major_code'] as String? ?? 'N/A',
      department: json['department'] as String? ?? 'N/A',
      profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
    );
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}
