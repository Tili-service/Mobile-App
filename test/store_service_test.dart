import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tili/services/store_service.dart';

void main() {
  group('StoreService', () {
    test('createStore returns map on 201', () async {
      final client = MockClient((request) async => http.Response(jsonEncode({'id': 10, 'name': 'S'}), 201));
      final res = await StoreService.createStore('t', 'lic', 'S', 'tv', 'siret', client: client);
      expect(res, isA<Map<String, dynamic>>());
      expect(res!['id'], 10);
    });

    test('createStore returns null on 400', () async {
      final client = MockClient((request) async => http.Response('bad', 400));
      final res = await StoreService.createStore('t', 'lic', 'S', 'tv', 'siret', client: client);
      expect(res, isNull);
    });
  });
}
