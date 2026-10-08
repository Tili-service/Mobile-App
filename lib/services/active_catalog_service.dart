import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/* The catalogue shown on the POS screen, chosen per store in the settings.
The backend has no "active catalogue" notion, so the choice is kept on the
device: each till can run its own catalogue. */
class ActiveCatalogService {
  static FlutterSecureStorage _storage = const FlutterSecureStorage();

  @visibleForTesting
  static set storage(FlutterSecureStorage s) => _storage = s;

  static String _key(String storeId) => 'activeCatalog_$storeId';

  static Future<String?> get(String storeId) => _storage.read(key: _key(storeId));

  static Future<void> set(String storeId, String catalogId) =>
      _storage.write(key: _key(storeId), value: catalogId);
}
