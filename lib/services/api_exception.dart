/* Thrown by ApiClient for any failed call; `message` is the backend's own
`error` field when present, otherwise a French fallback from the caller. */
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
