import 'dart:convert';
import 'dart:typed_data';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class StudentDocumentsRepository {
  StudentDocumentsRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<StudentDocumentsResult> fetchDocuments() async {
    final token = await _token();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/student/documents'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decodeJson(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _asMap(decoded)['message'] as String? ??
            'Could not load student documents.',
        statusCode: response.statusCode,
      );
    }

    return StudentDocumentsResult.fromJson(_asMap(decoded));
  }

  Future<Uint8List> preview(StudentDocument document) {
    return _fetchFileBytes(
      '${ApiConfig.baseUrl}/student/documents/${document.id}/preview',
    );
  }

  Future<Uint8List> download(StudentDocument document) {
    return _fetchFileBytes(
      '${ApiConfig.baseUrl}/student/documents/${document.id}/download',
    );
  }

  Future<Uint8List> _fetchFileBytes(String url) async {
    final token = await _token();
    final response = await _client.get(
      Uri.parse(url),
      headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }
      throw ApiException(
        _asMap(decoded)['message'] as String? ?? 'Could not open document.',
        statusCode: response.statusCode,
      );
    }

    return response.bodyBytes;
  }

  Future<String> _token() async {
    final token = await _sessionStore.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again.');
    }
    return token;
  }

  Object? _decodeJson(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The server returned an invalid documents response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class StudentDocumentsResult {
  const StudentDocumentsResult({
    required this.counts,
    required this.subjects,
    required this.documents,
  });

  final StudentDocumentCounts counts;
  final List<String> subjects;
  final List<StudentDocument> documents;

  factory StudentDocumentsResult.fromJson(Map<String, dynamic> json) {
    return StudentDocumentsResult(
      counts: StudentDocumentCounts.fromJson(_asMap(json['counts'])),
      subjects: _asStringList(json['subjects']),
      documents: _asList(
        json['documents'],
      ).map(StudentDocument.fromJson).toList(),
    );
  }
}

class StudentDocumentCounts {
  const StudentDocumentCounts({required this.all, required this.subjects});

  final int all;
  final int subjects;

  factory StudentDocumentCounts.fromJson(Map<String, dynamic> json) {
    return StudentDocumentCounts(
      all: _int(json['all']),
      subjects: _int(json['subjects']),
    );
  }
}

class StudentDocument {
  const StudentDocument({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.className,
    required this.teacher,
    required this.type,
    required this.ext,
    required this.size,
    required this.fileSize,
    required this.date,
    required this.originalName,
    required this.canPreview,
  });

  final int id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final String teacher;
  final String type;
  final String ext;
  final String size;
  final int fileSize;
  final DateTime? date;
  final String originalName;
  final bool canPreview;

  bool get isPdf => ext.toLowerCase() == 'pdf';
  bool get isImage {
    return ['png', 'jpg', 'jpeg', 'webp'].contains(ext.toLowerCase());
  }

  factory StudentDocument.fromJson(Map<String, dynamic> json) {
    return StudentDocument(
      id: _int(json['id']),
      title: json['title'] as String? ?? 'Untitled document',
      description: json['description'] as String? ?? '',
      subject: json['subject'] as String? ?? 'N/A',
      className: json['class_name'] as String? ?? '',
      teacher: json['teacher'] as String? ?? 'N/A',
      type: json['type'] as String? ?? 'other',
      ext: json['ext'] as String? ?? '',
      size: json['size'] as String? ?? '',
      fileSize: _int(json['file_size']),
      date: DateTime.tryParse('${json['date'] ?? ''}'),
      originalName: json['original_name'] as String? ?? '',
      canPreview: json['can_preview'] == true,
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

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => '$item').where((item) => item.isNotEmpty).toList();
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}
