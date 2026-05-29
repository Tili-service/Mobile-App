import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? (Platform.isAndroid ? "http://10.0.2.2:8000" : "http://127.0.0.1:8000");
  static Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/account/login');
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

  /* The getCatalog method takes an authentication token as a parameter, constructs
  a GET request to the backend API's catalog endpoint, and includes the token in the
  Authorization header. If the response status code is 200 (indicating a successful request),
  it decodes the response body to extract and return the catalog data. If the
  request fails, it returns null. This method allows the application to retrieve the
  catalog for the current session. */
  static Future<List<dynamic>?> getCatalog(String token) async {
    final url = Uri.parse('$baseUrl/catalog');
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

  /* The getCategories method takes an authentication token as a parameter, constructs
  a GET request to the backend API's categories endpoint, and includes the token in the
  Authorization header. If the response status code is 200 (indicating a successful request),
  it decodes the response body to extract and return the list of categories. If the
  request fails, it returns null. This method allows the application to retrieve the
  categories for the current session. */
  static Future<List<dynamic>?> getCategories(String token) async {
    final url = Uri.parse('$baseUrl/categorie');
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

  /* The updateCatalog method takes an authentication token, a catalog ID, and data to update,
  constructs a PUT request to the backend API's catalog update endpoint, and includes the token
  in the Authorization header. It returns true if the update is successful (status 200). */
  static Future<bool> updateCatalog(String token, int catalogId, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/catalog/$catalogId');
    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  /* The deleteCatalog method takes an authentication token and a catalog ID, constructs
  a DELETE request to the backend API's catalog delete endpoint, and includes the token
  in the Authorization header. It returns true if the deletion is successful (status 200). */
  static Future<bool> deleteCatalog(String token, int catalogId) async {
    final url = Uri.parse('$baseUrl/catalog/$catalogId');
    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );
    return response.statusCode == 200;
  }

  /* The createCatalog method takes an authentication token, name, and description, constructs
  a POST request to the backend API's catalog create endpoint, and includes the token
  in the Authorization header. It returns true if the creation is successful (status 201). */
  static Future<bool> createCatalog(String token, String name, String description) async {
    final url = Uri.parse('$baseUrl/catalog');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );
    return response.statusCode == 201;
  }

  /* The createSession method takes an authentication token, name, and level, constructs
  a POST request to the backend API's session create endpoint, and includes the token
  in the Authorization header. It returns true if the creation is successful (status 201). */
  static Future<bool> createSession(String token, String name, int level) async {
    final url = Uri.parse('$baseUrl/profile');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        'level_access': level,
        'name': name
      }),
    );
    return response.statusCode == 201;
  }

  /* The getSessions method takes an authentication token and store ID, constructs
  a GET request to the backend API's profiles by store endpoint, and includes the token in the
  Authorization header. If the response status code is 200 (indicating a successful request),
  it decodes the response body to extract and return the list of profiles (sessions). If the
  request fails, it returns null. This method allows the application to retrieve the
  list of profiles for the store. */
  static Future<List<dynamic>?> getSessions(String token, int storeId) async {
    final url = Uri.parse('$baseUrl/profile/allProfilesByStoreId/$storeId');
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as List<dynamic>;
    }
    return null;
  }

  /* The createCategory method takes an authentication token, catalog ID, and type, constructs
  a POST request to the backend API's categorie create endpoint, and includes the token
  in the Authorization header. It returns true if the creation is successful (status 201). */
  static Future<bool> createCategory(String token, int catalogId, String type) async {
    final url = Uri.parse('$baseUrl/categorie');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        'categorie_id': catalogId,
        'type': type,
      }),
    );
    return response.statusCode == 201;
  }
}
