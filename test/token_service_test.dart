import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tili/services/token_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    TokenService.storage = mockStorage;
  });

  test('saveToken writes shop token', () async {
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async => null);

    await TokenService.saveToken(TokenType.shop, 'abc');

    verify(() => mockStorage.write(key: 'shopToken', value: 'abc')).called(1);
  });

  test('getToken returns saved token', () async {
    when(() => mockStorage.read(key: 'shopToken')).thenAnswer((_) async => 'abc');

    final token = await TokenService.getToken(TokenType.shop);

    expect(token, 'abc');
    verify(() => mockStorage.read(key: 'shopToken')).called(1);
  });

  test('deleteToken deletes shop token', () async {
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async => null);

    await TokenService.deleteToken(TokenType.shop);

    verify(() => mockStorage.delete(key: 'shopToken')).called(1);
  });

  test('saveToken writes user token', () async {
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async => null);

    await TokenService.saveToken(TokenType.user, 'user123');

    verify(() => mockStorage.write(key: 'userToken', value: 'user123')).called(1);
  });

  test('getToken returns null when token missing', () async {
    when(() => mockStorage.read(key: 'userToken')).thenAnswer((_) async => null);

    final token = await TokenService.getToken(TokenType.user);

    expect(token, isNull);
    verify(() => mockStorage.read(key: 'userToken')).called(1);
  });

  test('saveToken and deleteToken for license token', () async {
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async => null);
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async => null);

    await TokenService.saveToken(TokenType.license, 'lic-999');
    await TokenService.deleteToken(TokenType.license);

    verify(() => mockStorage.write(key: 'licenseToken', value: 'lic-999')).called(1);
    verify(() => mockStorage.delete(key: 'licenseToken')).called(1);
  });
}
