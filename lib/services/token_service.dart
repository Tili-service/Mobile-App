import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum TokenType { shop, user, license }

class TokenService {
  static const _storage = FlutterSecureStorage();

  /* The TokenService class provides static methods for saving, retrieving, and deleting
  authentication tokens and administrator PINs using the FlutterSecureStorage package.
  It defines three token types: shop, user, and pinAdmin. The saveToken method saves
  a token to secure storage based on the specified token type. The getToken method
  retrieves a token from secure storage based on the specified token type. The deleteToken
  method removes a token from secure storage based on the specified token type. This service
  abstracts away the details of how tokens are stored and accessed, providing a simple
  interface for managing authentication credentials within the application. */
  static const _shopKey = 'shopToken';
  static const _userKey = 'userToken';
  static const _licenseKey = 'licenseToken';
  static Future<void> saveToken(TokenType tokenType, String token) async {
    switch (tokenType) {
      case TokenType.shop:
        await _storage.write(key: _shopKey, value: token);
        break;
      case TokenType.user:
        await _storage.write(key: _userKey, value: token);
        break;
      case TokenType.license:
        await _storage.write(key: _licenseKey, value: token);
        break;
    }
  }

  /* The getToken method retrieves a token from secure storage based on the specified
  token type. It uses a switch statement to determine which token to read from storage
  based on the provided TokenType. The method returns a Future<String?> that resolves
  to the token value if it exists, or null if the token is not found. This method allows
  other parts of the application to access stored tokens without needing to know the
  details of how they are stored, providing a clean and consistent interface for token
  retrieval. If the token is not found, it returns null, allowing the calling code to
  handle the absence of a token appropriately. */
  static Future<String?> getToken(TokenType tokenType) async {
    switch (tokenType) {
      case TokenType.shop:
        return await _storage.read(key: _shopKey);
      case TokenType.user:
        return await _storage.read(key: _userKey);
      case TokenType.license:
        return await _storage.read(key: _licenseKey);
    }
  }

  /* The deleteToken method removes a token from secure storage based on the specified
  token type. It uses a switch statement to determine which token to delete from storage
  based on the provided TokenType. The method returns a Future<void> that completes when
  the token has been deleted. This method allows other parts of the application to securely
  remove tokens when they are no longer needed, such as during a logout process. By
  abstracting the token deletion logic within this service, it ensures that token
  management is centralized and consistent across the application. When a token is deleted,
  it is removed from secure storage, preventing unauthorized access to sensitive information. */
  static Future<void> deleteToken(TokenType tokenType) async {
    switch (tokenType) {
      case TokenType.shop:
        await _storage.delete(key: _shopKey);
        break;
      case TokenType.user:
        await _storage.delete(key: _userKey);
        break;
      case TokenType.license:
        await _storage.delete(key: _licenseKey);
        break;
    }
  }
}