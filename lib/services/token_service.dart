import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/* The names are historical and misleading, and are kept because they are the
storage keys already written on devices:
  shop    → AccountToken (merchant email/password login)
  user    → ProfileToken of the cashier logged in with a PIN
  license → store_id of the selected shop (not a token) */
enum TokenType { shop, user, license }

class TokenService {
  static FlutterSecureStorage _storage = const FlutterSecureStorage();

  @visibleForTesting
  static set storage(FlutterSecureStorage s) => _storage = s;

  static const _keys = {
    TokenType.shop: 'shopToken',
    TokenType.user: 'userToken',
    TokenType.license: 'licenseToken',
  };

  static Future<void> saveToken(TokenType type, String token) =>
      _storage.write(key: _keys[type]!, value: token);

  static Future<String?> getToken(TokenType type) => _storage.read(key: _keys[type]!);

  static Future<void> deleteToken(TokenType type) => _storage.delete(key: _keys[type]!);

  static Future<void> clearAll() async {
    for (final type in TokenType.values) {
      await deleteToken(type);
    }
  }
}
