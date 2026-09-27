/* Thrown by AuthService/StoreService calls that need to surface the backend's
actual error message instead of a generic "something went wrong" snackbar.
Methods that predate this (returning bool/List/Map and swallowing the reason)
are left as-is to limit churn; new/critical flows (sale creation, login,
profile mutations) use this so the UI can show what really failed. */
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
