import 'api_client.dart';

/* Shop creation for a licence (AccountToken). */
class StoreService {
  static Future<Map<String, dynamic>> createStore(
    String token,
    String licenceId,
    String name,
    String numeroTva,
    String siret,
  ) async {
    final data = await ApiClient.request(
      'POST',
      '/store',
      token: token,
      body: {'licence_id': licenceId, 'name': name, 'numero_tva': numeroTva, 'siret': siret},
      errorMessage: 'Erreur lors de la création du commerce',
    );
    return (data as Map).cast<String, dynamic>();
  }
}
