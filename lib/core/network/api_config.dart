import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }

    // return 'http://192.168.18.2:8080/api';
    return 'http://10.12.1.135:8080/api';
  }

  static String get serverUrl {
    final uri = Uri.parse(baseUrl);
    final path = uri.path.replaceFirst(RegExp(r'/api/?$'), '');
    return uri.replace(path: path, query: '', fragment: '').toString();
  }

  static String resolveUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final apiUri = Uri.parse(baseUrl);
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        return uri
            .replace(
              scheme: apiUri.scheme,
              host: apiUri.host,
              port: apiUri.hasPort ? apiUri.port : null,
            )
            .toString();
      }
      return trimmed;
    }

    final serverUri = Uri.parse(serverUrl);
    return serverUri.replace(path: trimmed, query: '', fragment: '').toString();
  }
}
