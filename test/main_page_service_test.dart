import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tili/services/main_page_service.dart';

void main() {
  group('MainPageService', () {
    test('getProfileName returns list on 200', () async {
      final client = MockClient((request) async => http.Response(jsonEncode(['A', 'B']), 200));
      final res = await MainPageService.getProfileName('t', client: client);
      expect(res, ['A', 'B']);
    });

    test('getProfileName returns null on 500', () async {
      final client = MockClient((request) async => http.Response('err', 500));
      final res = await MainPageService.getProfileName('t', client: client);
      expect(res, isNull);
    });
  });
}
