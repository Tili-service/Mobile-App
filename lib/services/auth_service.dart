import 'dart:convert';
import 'package:http/http.dart' as http;

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
  static const String baseUrl = "http://10.0.2.2:8080";
  static Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/users/login');
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
}
