import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/* The StoreService class provides methods for interacting with the
backend API to manage stores. It includes a method to create a new store
by sending a POST request to the API with the necessary information such
as the license ID, store name, SIRET number, and TVA number. The class also
retrieves the base URL for the API from environment variables. */
class MainPageService {
  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? "http://10.0.2.2:8000";
  static Future<List?> getProfileName(String token) async {
    final url = Uri.parse('$baseUrl/profile/me');
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as List;
    }
    return null;
  }
}
