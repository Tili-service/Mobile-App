import 'api_client.dart';

/* Merchant account operations (AccountToken). */
class AccountService {
  static Future<void> register(String name, String email, String password) async {
    await ApiClient.request(
      'POST',
      '/account',
      body: {'name': name, 'email': email, 'password': password},
      errorMessage: 'Impossible de créer le compte',
    );
  }

  static Future<Map<String, dynamic>> getAccount(String token) async {
    final data = await ApiClient.request(
      'GET',
      '/account',
      token: token,
      errorMessage: 'Impossible de récupérer le compte',
    );
    return (data as Map).cast<String, dynamic>();
  }

  // The backend binds `email` as required on update, so both fields are always sent.
  static Future<void> updateAccount(String token, {required String name, required String email}) async {
    await ApiClient.request(
      'PUT',
      '/account',
      token: token,
      body: {'name': name, 'email': email},
      errorMessage: 'Impossible de modifier le compte',
    );
  }

  static Future<void> changePassword(String token, String oldPassword, String newPassword) async {
    await ApiClient.request(
      'POST',
      '/account/reset-password',
      token: token,
      body: {'old_password': oldPassword, 'new_password': newPassword},
      errorMessage: 'Impossible de modifier le mot de passe',
    );
  }

  static Future<void> deleteAccount(String token) async {
    await ApiClient.request(
      'DELETE',
      '/account',
      token: token,
      errorMessage: 'Impossible de supprimer le compte',
    );
  }
}
