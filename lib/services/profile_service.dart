import 'api_client.dart';

/* Employee profiles of a store (ProfileToken, Manager level or above;
deletion requires Admin). */
class ProfileService {
  static const levelNames = <int, String>{
    1: 'Super administrateur',
    2: 'Admin',
    3: 'Manager',
    4: 'Employé',
  };

  static const assignableLevels = [2, 3, 4];

  static Future<Map<String, dynamic>> loginWithPin(String storeId, String pin) async {
    final data = await ApiClient.request(
      'POST',
      '/profile/login/pin',
      body: {'store_id': storeId, 'pin': pin},
      errorMessage: 'PIN invalide',
    );
    return (data as Map).cast<String, dynamic>();
  }

  static Future<List<dynamic>> getProfiles(String token, String storeId) async {
    final data = await ApiClient.request(
      'GET',
      '/profile/allProfilesByStoreId/$storeId',
      token: token,
      errorMessage: 'Impossible de récupérer les profils',
    );
    return ApiClient.asList(data);
  }

  /* Returns the created profile including its generated PIN, which the
  backend never exposes again afterwards. */
  static Future<Map<String, dynamic>> createProfile(String token, String name, int level) async {
    final data = await ApiClient.request(
      'POST',
      '/profile',
      token: token,
      body: {'name': name, 'level_access': level},
      errorMessage: 'Impossible de créer le profil',
    );
    return (data as Map).cast<String, dynamic>();
  }

  static Future<void> updateProfile(
    String token,
    String profileId,
    String storeId, {
    String? name,
    int? level,
    bool? isActive,
  }) async {
    await ApiClient.request(
      'PUT',
      '/profile/updateProfile/$profileId/$storeId',
      token: token,
      body: {
        'name': ?name,
        'level_access': ?level,
        'is_active': ?isActive,
      },
      errorMessage: 'Impossible de modifier le profil',
    );
  }

  static Future<String> resetPin(String token, String profileId, String storeId) async {
    final data = await ApiClient.request(
      'PUT',
      '/profile/resetPin/$profileId/$storeId',
      token: token,
      errorMessage: 'Impossible de régénérer le PIN',
    );
    return (data as Map)['pin'].toString();
  }

  static Future<void> deleteProfile(String token, String profileId) async {
    await ApiClient.request(
      'DELETE',
      '/profile/$profileId',
      token: token,
      errorMessage: 'Impossible de supprimer le profil',
    );
  }
}
