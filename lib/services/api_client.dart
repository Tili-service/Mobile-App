import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_exception.dart';

/* Single entry point for the newer services: builds the URL, adds the auth
header, decodes JSON and turns any non-2xx response into an ApiException that
carries the backend's own `error` message (falling back to a French message
given by the caller). Mirrors the web app's apiFetch helper. */
class ApiClient {
  static String get baseUrl {
    try {
      final env = dotenv.env['BACKEND_URL'];
      if (env != null && env.isNotEmpty) return env;
    } catch (_) {}
    return Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
  }

  static http.Client client = http.Client();

  static Future<dynamic> request(
    String method,
    String path, {
    String? token,
    Object? body,
    String errorMessage = 'Une erreur est survenue',
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 15)),
      );
    } on TimeoutException {
      throw ApiException('Le serveur ne répond pas');
    } on SocketException {
      throw ApiException('Impossible de joindre le serveur');
    }

    final decoded = _tryDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : errorMessage;
      throw ApiException(message, statusCode: response.statusCode);
    }
    return decoded;
  }

  static dynamic _tryDecode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static List<dynamic> asList(dynamic data) => data is List ? data : <dynamic>[];
}
