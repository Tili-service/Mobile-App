import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/* This service is responsible for handling authentication-related operations,
such as logging in users and managing authentication tokens. It provides a method
to send login requests to the backend API and retrieve authentication tokens upon
successful login. */
class AuthService {
  /* The login method takes an email and password as parameters, constructs a
  POST request to the backend API's login endpoint, and sends the credentials
  in JSON format. If the response status code is 200 (indicating a successful login),
  it decodes the response body to extract and return the authentication token.
  If the login fails, it returns null. */
  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? "http://10.0.2.2:8000";
  static Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/account/login');
    print("Sending email: $email and password: $password to $url");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["token"];
    }
    return null;
  }

  /* The getLicenses method takes an authentication token as a parameter, constructs
  a GET request to the backend API's licenses endpoint, and includes the token in the
  Authorization header. If the response status code is 200 (indicating a successful request),
  it decodes the response body to extract and return the list of licenses. If the
  request fails, it returns null. This method allows the application to retrieve the
  licenses associated with the authenticated user, which can then be displayed in the UI. */
  static Future<List<dynamic>?> getLicenses(String token) async {
    final url = Uri.parse('$baseUrl/licences');
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as List<dynamic>;
    }
    return null;
  }

  /* The getPin method takes an authentication token, a PIN entered by the user,
  and a store ID as parameters. It constructs a POST request to the backend API's PIN
  login endpoint, including the token in the Authorization header and the PIN and
  store ID in the request body as JSON. If the response status code is 200 (indicating a
  successful request), it decodes the response body to extract and return the relevant
  data as a Map<String, dynamic>. If the request fails, it returns null. This method
  allows the application to verify the entered PIN against the backend and retrieve any
  associated session information for the selected license. */
  static Future<Map<String, dynamic>?> getPin(String token, String pinEntered, String storeId) async {
    final url = Uri.parse('$baseUrl/profile/login/pin');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "pin": pinEntered,
        "store_id": int.parse(storeId),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as Map<String, dynamic>;
    }
    return null;
  }
}
