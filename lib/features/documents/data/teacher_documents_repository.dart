import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;

class TeacherDocumentsRepository {
  TeacherDocumentsRepository({
    http.Client? client,
    AuthSessionStore? sessionStore,
  }) : _client = client ?? http.Client(),
       _sessionStore = sessionStore ?? AuthSessionStore();

  final http.Client _client;
  final AuthSessionStore _sessionStore;

  Future<TeacherDocumentsResult> fetchDocuments() async {
    final token = await _token();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/teacher/documents'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _asMap(decoded);
      throw ApiException(
        body['message'] as String? ??
            body['error'] as String? ??
            'Could not load teacher documents.',
        statusCode: response.statusCode,
      );
    }

    return TeacherDocumentsResult.fromJson(_asMap(decoded));
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
        'The server returned an invalid documents response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class TeacherDocumentsResult {
  const TeacherDocumentsResult({required this.counts, required this.documents});

  final TeacherDocumentCounts counts;
  final List<TeacherDocument> documents;

  factory TeacherDocumentsResult.fromJson(Map<String, dynamic> json) {
    return TeacherDocumentsResult(
      counts: TeacherDocumentCounts.fromJson(_asMap(json['counts'])),
      documents: _asList(
        json['documents'],
      ).map((item) => TeacherDocument.fromJson(item)).toList(),
    );
  }
}

class TeacherDocumentCounts {
  const TeacherDocumentCounts({
    required this.all,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  final int all;
  final int pending;
  final int approved;
  final int rejected;

  factory TeacherDocumentCounts.fromJson(Map<String, dynamic> json) {
    return TeacherDocumentCounts(
      all: _int(json['all']),
      pending: _int(json['pending']),
      approved: _int(json['approved']),
      rejected: _int(json['rejected']),
    );
  }
}

class TeacherDocument {
  const TeacherDocument({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.type,
    required this.ext,
    required this.status,
    required this.size,
    required this.fileSize,
    required this.date,
    required this.comment,
    required this.originalName,
  });

  final int id;
  final String title;
  final String subject;
  final String className;
  final String type;
  final String ext;
  final String status;
  final String size;
  final int fileSize;
  final DateTime? date;
  final String comment;
  final String originalName;

  factory TeacherDocument.fromJson(Map<String, dynamic> json) {
    return TeacherDocument(
      id: _int(json['id']),
      title: json['title'] as String? ?? 'Untitled document',
      subject: json['subject'] as String? ?? 'Class document',
      className: json['class_name'] as String? ?? 'N/A',
      type: json['type'] as String? ?? 'other',
      ext: json['ext'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      size: json['size'] as String? ?? _formatSize(_int(json['file_size'])),
      fileSize: _int(json['file_size']),
      date: DateTime.tryParse('${json['date'] ?? ''}')?.toLocal(),
      comment: json['comment'] as String? ?? '',
      originalName: json['original_name'] as String? ?? '',
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

String _formatSize(int bytes) {
  if (bytes <= 0) return '0 KB';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).round().clamp(1, 999)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
