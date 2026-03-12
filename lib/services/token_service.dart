import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum TokenType { shop, user, pinAdmin}

class TokenService {
  static const _storage = FlutterSecureStorage();

  static const _shopKey = 'shopToken';
  static const _userKey = 'userToken';
  static const _pinAdminKey = 'pinAdmin';

  static Future<void> saveToken(TokenType tokenType, String token) async {
    switch (tokenType) {
      case TokenType.shop:
        await _storage.write(key: _shopKey, value: token);
        break;
      case TokenType.user:
        await _storage.write(key: _userKey, value: token);
        break;
      case TokenType.pinAdmin:
        await _storage.write(key: _pinAdminKey, value: token);
        break;
    }
  }

  static Future<String?> getToken(TokenType tokenType) async {
    switch (tokenType) {
      case TokenType.shop:
        return await _storage.read(key: _shopKey);
      case TokenType.user:
        return await _storage.read(key: _userKey);
      case TokenType.pinAdmin:
        return await _storage.read(key: _pinAdminKey);
    }
  }

  static Future<void> deleteToken(TokenType tokenType) async {
    switch (tokenType) {
      case TokenType.shop:
        await _storage.delete(key: _shopKey);
        break;
      case TokenType.user:
        await _storage.delete(key: _userKey);
        break;
      case TokenType.pinAdmin:
        await _storage.delete(key: _pinAdminKey);
        break;
    }
  }
}