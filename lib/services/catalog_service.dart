import '../utils/pricing.dart';
import 'api_client.dart';

/* Catalogues, categories and items of a store (ProfileToken; mutations need
Manager level or above). Categories belong to a catalogue and `GET /item` is
unscoped, so items are filtered client-side by the catalogue's category IDs. */
class CatalogService {
  static Future<List<dynamic>> getCatalogs(String token, String storeId) async {
    final data = await ApiClient.request(
      'GET',
      '/catalog/store/$storeId',
      token: token,
      errorMessage: 'Impossible de récupérer les catalogues',
    );
    return ApiClient.asList(data);
  }

  static Future<Map<String, dynamic>> createCatalog(
    String token,
    String storeId,
    String name,
    String description,
  ) async {
    final data = await ApiClient.request(
      'POST',
      '/catalog/store/$storeId',
      token: token,
      body: {'name': name, 'description': description},
      errorMessage: 'Impossible de créer le catalogue',
    );
    return (data as Map).cast<String, dynamic>();
  }

  static Future<void> updateCatalog(
    String token,
    String storeId,
    String catalogId,
    String name,
    String description,
  ) async {
    await ApiClient.request(
      'PUT',
      '/catalog/store/$storeId/$catalogId',
      token: token,
      body: {'name': name, 'description': description},
      errorMessage: 'Impossible de modifier le catalogue',
    );
  }

  static Future<void> deleteCatalog(String token, String storeId, String catalogId) async {
    await ApiClient.request(
      'DELETE',
      '/catalog/store/$storeId/$catalogId',
      token: token,
      errorMessage: 'Impossible de supprimer le catalogue',
    );
  }

  static Future<List<dynamic>> getCategories(String token, String catalogId) async {
    final data = await ApiClient.request(
      'GET',
      '/categorie/catalog/$catalogId',
      token: token,
      errorMessage: 'Impossible de récupérer les catégories',
    );
    return ApiClient.asList(data);
  }

  static Future<void> createCategory(String token, String catalogId, String type) async {
    await ApiClient.request(
      'POST',
      '/categorie/catalog/$catalogId',
      token: token,
      body: {'type': type},
      errorMessage: 'Impossible de créer la catégorie',
    );
  }

  static Future<void> renameCategory(String token, String catalogId, String categoryId, String type) async {
    await ApiClient.request(
      'PUT',
      '/categorie/catalog/$catalogId/$categoryId',
      token: token,
      body: {'type': type},
      errorMessage: 'Impossible de modifier la catégorie',
    );
  }

  static Future<void> deleteCategory(String token, String catalogId, String categoryId) async {
    await ApiClient.request(
      'DELETE',
      '/categorie/catalog/$catalogId/$categoryId',
      token: token,
      errorMessage: 'Impossible de supprimer la catégorie',
    );
  }

  static Future<List<dynamic>> getItems(String token) async {
    final data = await ApiClient.request(
      'GET',
      '/item',
      token: token,
      errorMessage: 'Impossible de récupérer les articles',
    );
    return ApiClient.asList(data);
  }

  static Future<List<dynamic>> getCatalogItems(String token, List<dynamic> categories) async {
    final ids = categories.map((c) => c['categorie_id']?.toString()).whereType<String>().toSet();
    final items = await getItems(token);
    return items.where((i) => ids.contains(i['categorie_id']?.toString())).toList();
  }

  static Map<String, dynamic> _itemBody(String name, double priceTTC, double taxRate, String categoryId) {
    final priceHT = round2(priceTTC / (1 + taxRate));
    return {
      'name': name,
      'price': priceHT,
      'tax': taxRate,
      'tax_amount': round2(priceHT * taxRate),
      'categorie_id': categoryId,
    };
  }

  static Future<void> createItem(
    String token, {
    required String name,
    required double priceTTC,
    required double taxRate,
    required String categoryId,
  }) async {
    await ApiClient.request(
      'POST',
      '/item',
      token: token,
      body: _itemBody(name, priceTTC, taxRate, categoryId),
      errorMessage: "Impossible de créer l'article",
    );
  }

  static Future<void> updateItem(
    String token,
    String itemId, {
    required String name,
    required double priceTTC,
    required double taxRate,
    required String categoryId,
  }) async {
    await ApiClient.request(
      'PUT',
      '/item/$itemId',
      token: token,
      body: _itemBody(name, priceTTC, taxRate, categoryId),
      errorMessage: "Impossible de modifier l'article",
    );
  }

  static Future<void> moveItem(String token, String itemId, String categoryId) async {
    await ApiClient.request(
      'PUT',
      '/item/$itemId',
      token: token,
      body: {'categorie_id': categoryId},
      errorMessage: "Impossible de déplacer l'article",
    );
  }

  static Future<void> deleteItem(String token, String itemId) async {
    await ApiClient.request(
      'DELETE',
      '/item/$itemId',
      token: token,
      errorMessage: "Impossible de supprimer l'article",
    );
  }
}
