import 'api_client.dart';

/* Licence operations (AccountToken). Buying a licence stays on the web app
on purpose; the mobile app only lists, refunds and links licences to shops. */
class LicenseService {
  static Future<List<dynamic>> getLicenses(String token) async {
    final data = await ApiClient.request(
      'GET',
      '/licences',
      token: token,
      errorMessage: 'Impossible de récupérer les licences',
    );
    return ApiClient.asList(data);
  }

  static Future<List<dynamic>> getMyStores(String token) async {
    final data = await ApiClient.request(
      'GET',
      '/store/me',
      token: token,
      errorMessage: 'Impossible de récupérer les boutiques',
    );
    return ApiClient.asList(data);
  }

  static Future<void> refund(String token, String licenceId) async {
    await ApiClient.request(
      'POST',
      '/licences/refund?licenceId=${Uri.encodeQueryComponent(licenceId)}',
      token: token,
      errorMessage: 'Impossible de rembourser la licence',
    );
  }
}
