import 'dart:convert';

import 'package:hru_atms/core/network/api_config.dart';
import 'package:http/http.dart' as http;

class SystemStatusRepository {
  SystemStatusRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<SystemStatus> check() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/check-status'),
        headers: const {'Accept': 'application/json'},
      );
      final body = _decode(response.body);

      if (body['maintenance_mode'] == true) {
        return SystemStatus.maintenance(
          body['message'] as String? ??
              'System maintenance is active. Please try again later.',
        );
      }

      return const SystemStatus.available();
    } catch (_) {
      return const SystemStatus.available();
    }
  }

  Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return const {};
  }
}

class SystemStatus {
  const SystemStatus._({required this.isMaintenance, required this.message});

  const SystemStatus.available() : this._(isMaintenance: false, message: '');

  const SystemStatus.maintenance(String message)
    : this._(isMaintenance: true, message: message);

  final bool isMaintenance;
  final String message;
}
