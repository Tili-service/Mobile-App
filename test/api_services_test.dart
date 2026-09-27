import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tili/services/account_service.dart';
import 'package:tili/services/api_client.dart';
import 'package:tili/services/api_exception.dart';
import 'package:tili/services/catalog_service.dart';
import 'package:tili/services/profile_service.dart';
import 'package:tili/services/store_service.dart';
import 'package:tili/utils/pricing.dart';

void main() {
  late http.Request lastRequest;

  setUpAll(() => dotenv.testLoad(fileInput: 'BACKEND_URL=http://api.test'));

  void respond(int status, Object? body) {
    ApiClient.client = MockClient((request) async {
      lastRequest = request;
      return http.Response(body == null ? '' : jsonEncode(body), status);
    });
  }

  group('pricing', () {
    test('itemPriceTTC applies tax to HT price', () {
      expect(itemPriceTTC({'price': '10.00', 'tax': '0.2000'}), 12.0);
    });

    test('parseInput accepts comma decimals', () {
      expect(parseInput(' 3,50 '), 3.5);
      expect(parseInput('abc').isNaN, isTrue);
    });
  });

  group('CatalogService', () {
    test('createItem converts TTC input to rounded HT', () async {
      respond(201, {'item_id': 'x'});
      await CatalogService.createItem('tok', name: 'Café', priceTTC: 2.5, taxRate: 0.2, categoryId: 'c1');

      final body = jsonDecode(lastRequest.body) as Map<String, dynamic>;
      expect(lastRequest.url.toString(), 'http://api.test/item');
      expect(lastRequest.headers['Authorization'], 'Bearer tok');
      expect(body['price'], 2.08);
      expect(body['tax'], 0.2);
      expect(body['tax_amount'], 0.42);
      expect(body['categorie_id'], 'c1');
    });

    test('getCatalogItems keeps only items of the catalog categories', () async {
      respond(200, [
        {'item_id': 'a', 'categorie_id': 'c1'},
        {'item_id': 'b', 'categorie_id': 'other'},
      ]);
      final items = await CatalogService.getCatalogItems('tok', [
        {'categorie_id': 'c1'},
      ]);
      expect(items.map((i) => i['item_id']), ['a']);
    });

    test('deleteItem accepts 204 with empty body', () async {
      respond(204, null);
      await CatalogService.deleteItem('tok', 'i1');
      expect(lastRequest.method, 'DELETE');
    });
  });

  group('ProfileService', () {
    test('updateProfile omits null fields', () async {
      respond(200, {});
      await ProfileService.updateProfile('tok', 'p1', 's1', isActive: false);
      expect(lastRequest.url.path, '/profile/updateProfile/p1/s1');
      expect(jsonDecode(lastRequest.body), {'is_active': false});
    });

    test('resetPin returns the new pin', () async {
      respond(200, {'pin': '123456'});
      expect(await ProfileService.resetPin('tok', 'p1', 's1'), '123456');
    });
  });

  group('AccountService', () {
    test('login returns the token', () async {
      respond(200, {'token': 'jwt'});
      expect(await AccountService.login('a@b.c', 'pw'), 'jwt');
      expect(jsonDecode(lastRequest.body), {'email': 'a@b.c', 'password': 'pw'});
    });
  });

  group('StoreService', () {
    test('createStore posts licence and shop info', () async {
      respond(201, {'store_id': 's1', 'name': 'Shop'});
      final store = await StoreService.createStore('tok', 'lic', 'Shop', 'FR1', '123');
      expect(store['store_id'], 's1');
      expect(jsonDecode(lastRequest.body), {'licence_id': 'lic', 'name': 'Shop', 'numero_tva': 'FR1', 'siret': '123'});
    });
  });

  group('ApiClient errors', () {
    test('surfaces backend error message', () async {
      respond(401, {'error': 'invalid pin'});
      expect(
        () => ProfileService.loginWithPin('s1', '000000'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'invalid pin')
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('falls back to caller message when body has no error', () async {
      respond(500, null);
      expect(
        () => CatalogService.getCatalogs('tok', 's1'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Impossible de récupérer les catalogues')),
      );
    });
  });
}
