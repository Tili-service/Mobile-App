import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/* The StoreService class provides methods for interacting with the
backend API to manage stores. It includes a method to create a new store
by sending a POST request to the API with the necessary information such
as the license ID, store name, SIRET number, and TVA number. The class also
retrieves the base URL for the API from environment variables. */
class StoreService {
  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? "http://10.0.2.2:8000";
  static Future<Map<String, dynamic>?> createStore(String token, String licenceId, String name, String numeroTva, String siret) async {
    final url = Uri.parse('$baseUrl/store');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "licence_id": licenceId,
        "name": name,
        "numero_tva": numeroTva,
        "siret": siret,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as Map<String, dynamic>;
    }
    return null;
  }
}
