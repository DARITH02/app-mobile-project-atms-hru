class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code = '',
    this.errors = const {},
  });

  final String message;
  final int? statusCode;
  final String code;
  final Map<String, List<String>> errors;

  @override
  String toString() => message;
}
