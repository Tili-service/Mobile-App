import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tili/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('login returns token on 200', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'token': 'abc123'}), 200);
      });

      final token = await AuthService.login('a@b', 'p', client: client);
      expect(token, 'abc123');
    });

    test('login returns null on non-200', () async {
      final client = MockClient((request) async {
        return http.Response('unauthorized', 401);
      });

      final token = await AuthService.login('a@b', 'p', client: client);
      expect(token, isNull);
    });

    test('getLicenses parses list on 200', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode(['L1', 'L2']), 200);
      });

      final list = await AuthService.getLicenses('tok', client: client);
      expect(list, isA<List>());
      expect(list, ['L1', 'L2']);
    });

    test('getLicenses returns null on 500', () async {
      final client = MockClient((request) async => http.Response('err', 500));
      final list = await AuthService.getLicenses('tok', client: client);
      expect(list, isNull);
    });

    test('getPin returns map on 200', () async {
      final client = MockClient((request) async {
        final body = jsonEncode({'id': 5, 'name': 'John'});
        return http.Response(body, 200);
      });

      final res = await AuthService.getPin('t', '1234', '1', client: client);
      expect(res, isA<Map<String, dynamic>>());
      expect(res!['id'], 5);
    });

    test('getPin returns null on non-200', () async {
      final client = MockClient((request) async => http.Response('nok', 400));
      final res = await AuthService.getPin('t', '1234', '1', client: client);
      expect(res, isNull);
    });

    test('getCatalog returns list on 200', () async {
      final client = MockClient((request) async => http.Response(jsonEncode([{'id': 1}]), 200));
      final res = await AuthService.getCatalog('t', client: client);
      expect(res, isA<List>());
    });

    test('getCatalog handles non-200', () async {
      final client = MockClient((request) async => http.Response('bad', 404));
      final res = await AuthService.getCatalog('t', client: client);
      expect(res, isNull);
    });

    test('getCategories returns list on 200', () async {
      final client = MockClient((request) async => http.Response(jsonEncode(['c1']), 200));
      final res = await AuthService.getCategories('t', client: client);
      expect(res, ['c1']);
    });

    test('updateCatalog returns true on 200', () async {
      final client = MockClient((request) async => http.Response('', 200));
      final ok = await AuthService.updateCatalog('t', 5, {'x': 1}, client: client);
      expect(ok, isTrue);
    });

    test('updateCatalog returns false on 500', () async {
      final client = MockClient((request) async => http.Response('', 500));
      final ok = await AuthService.updateCatalog('t', 5, {'x': 1}, client: client);
      expect(ok, isFalse);
    });

    test('deleteCatalog returns true on 200', () async {
      final client = MockClient((request) async => http.Response('', 200));
      final ok = await AuthService.deleteCatalog('t', 3, client: client);
      expect(ok, isTrue);
    });

    test('deleteCatalog returns false on 404', () async {
      final client = MockClient((request) async => http.Response('', 404));
      final ok = await AuthService.deleteCatalog('t', 3, client: client);
      expect(ok, isFalse);
    });

    test('createCatalog returns true on 201', () async {
      final client = MockClient((request) async => http.Response('', 201));
      final ok = await AuthService.createCatalog('t', 'n', 'd', client: client);
      expect(ok, isTrue);
    });

    test('createCatalog returns false on 200', () async {
      final client = MockClient((request) async => http.Response('', 200));
      final ok = await AuthService.createCatalog('t', 'n', 'd', client: client);
      expect(ok, isFalse);
    });

    test('createSession returns true on 201', () async {
      final client = MockClient((request) async => http.Response('', 201));
      final ok = await AuthService.createSession('t', 'name', 2, client: client);
      expect(ok, isTrue);
    });

    test('getSessions parses list on 200', () async {
      final client = MockClient((request) async => http.Response(jsonEncode([{'p':1}]), 200));
      final res = await AuthService.getSessions('t', 1, client: client);
      expect(res, isA<List>());
    });

    test('createCategory returns true on 201', () async {
      final client = MockClient((request) async => http.Response('', 201));
      final ok = await AuthService.createCategory('t', 1, 'type', client: client);
      expect(ok, isTrue);
    });

    test('login handles invalid JSON gracefully (throws)', () async {
      final client = MockClient((request) async => http.Response('not-json', 200));
      expect(() => AuthService.login('a', 'b', client: client), throwsA(isA<FormatException>()));
    });

    test('getLicenses handles invalid JSON (throws)', () async {
      final client = MockClient((request) async => http.Response('oops', 200));
      expect(() => AuthService.getLicenses('t', client: client), throwsA(isA<FormatException>()));
    });
  });
}
