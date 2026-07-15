import 'dart:convert';
import 'dart:io';

import 'package:akasha/core/commerce/commerce.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final schema =
      jsonDecode(
            File(
              'docs/active/steam_inventory_production/'
              'itemdefs_steamworks_upload.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  final items = (schema['items']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final byId = <String, Map<String, Object?>>{
    for (final item in items) item['itemdefid']! as String: item,
  };

  test(
    'upload candidate has unique IDs and retires every published POC ID',
    () {
      expect(schema['appid'], '4677560');
      expect(byId, hasLength(items.length));
      for (final item in items) {
        final id = int.parse(item['itemdefid']! as String);
        expect(id, inExclusiveRange(0, 1000000));
        expect(
          item['type'],
          isIn(['item', 'bundle', 'generator', 'playtimegenerator']),
        );
      }

      for (final id in const [
        '10001',
        '10002',
        '10010',
        '10020',
        '10021',
        '20001',
        '20010',
        '30001',
      ]) {
        expect(byId[id]?['hidden'], isTrue, reason: 'POC ItemDef $id');
        expect(byId[id]?['game_only'], isTrue, reason: 'POC ItemDef $id');
      }

      expect(byId['10020']?['use_drop_limit'], isTrue);
      expect(byId['10020']?['drop_limit'], 0);
    },
  );

  test('upload schema is app-only and all recipes resolve safely', () {
    final activeIds = <String>{
      for (final item in items)
        if (item['hidden'] != true) item['itemdefid']! as String,
    };

    for (final item in items) {
      final id = item['itemdefid']! as String;
      expect(item['appid'], schema['appid'], reason: 'ItemDef $id AppID');
      expect(item['tradable'], isFalse, reason: 'ItemDef $id tradable');
      expect(item['marketable'], isFalse, reason: 'ItemDef $id marketable');
      expect(item['game_only'], isTrue, reason: 'ItemDef $id game_only');
      expect(item['store_hidden'], isTrue, reason: 'ItemDef $id store_hidden');
      expect(
        !(item.containsKey('price') && item.containsKey('price_category')),
        isTrue,
        reason: 'ItemDef $id cannot define price and price_category together',
      );

      for (final property in const ['bundle', 'exchange']) {
        final recipe = item[property] as String?;
        if (recipe == null) continue;
        final referencedIds = RegExp(
          r'(?:^|[;,])(\d+)(?:x\d+)?',
        ).allMatches(recipe).map((match) => match.group(1)!);
        for (final referencedId in referencedIds) {
          expect(
            byId,
            contains(referencedId),
            reason: 'ItemDef $id $property references missing $referencedId',
          );
          if (item['hidden'] != true) {
            expect(
              activeIds,
              contains(referencedId),
              reason: 'Active ItemDef $id references retired $referencedId',
            );
          }
        }
      }
    }
  });

  test(
    'approved Astra pack allowlist maps to production bundles and prices',
    () {
      const expected = {
        CommerceCatalog.astraPack500ProductId: (
          '40110',
          '40001x500',
          '1;VLV500',
        ),
        CommerceCatalog.astraPack1000ProductId: (
          '40111',
          '40001x1000',
          '1;VLV1000',
        ),
        CommerceCatalog.astraPack2500ProductId: (
          '40112',
          '40001x2500',
          '1;VLV2500',
        ),
      };

      for (final entry in expected.entries) {
        final (id, bundle, priceCategory) = entry.value;
        final item = byId[id]!;
        expect(item['akasha_product_id'], entry.key);
        expect(item['type'], 'bundle');
        expect(item['bundle'], bundle);
        expect(item['price_category'], priceCategory);
        expect(item['use_bundle_price'], isTrue);
        expect(item['store_hidden'], isTrue);
      }

      expect(byId['40001']?['price'], '1;USD1');
      expect(byId['40001']?['store_hidden'], isTrue);
    },
  );

  test('Echo play reward grants ten with a six-per-window Steam cap', () {
    final echoUnit = byId['40002']!;
    final rewardBundle = byId['40210']!;
    final generator = byId['40220']!;

    expect(echoUnit.containsKey('price'), isFalse);
    expect(rewardBundle['type'], 'bundle');
    expect(rewardBundle['bundle'], '40002x10');
    expect(generator['type'], 'playtimegenerator');
    expect(generator['bundle'], '40210');
    expect(generator['drop_interval'], 10);
    expect(generator['use_drop_window'], isTrue);
    expect(generator['drop_window'], 1440);
    expect(generator['drop_max_per_window'], 6);
  });

  test(
    'each paid theme uses one choose-one exchange and a new entitlement',
    () {
      const expected = {
        CommerceCatalog.sakuraThemeProductId: ('41101', '41001x1'),
        CommerceCatalog.amethystThemeProductId: ('41102', '41002x1'),
        CommerceCatalog.nocturneThemeProductId: ('41103', '41003x1'),
      };

      for (final entry in expected.entries) {
        final (exchangeId, entitlementBundle) = entry.value;
        final exchange = byId[exchangeId]!;
        expect(exchange['akasha_product_id'], entry.key);
        expect(exchange['bundle'], entitlementBundle);
        expect(exchange['exchange'], '40001x500;40002x500');
        expect(exchange['store_hidden'], isTrue);
      }

      expect(byId['41001']?['akasha_entitlement_key'], 'theme:sakura');
      expect(byId['41002']?['akasha_entitlement_key'], 'theme:amethyst');
      expect(byId['41003']?['akasha_entitlement_key'], 'theme:nocturne');
    },
  );

  test(
    'active launch definitions contain no starter promo or support offer',
    () {
      final activeItems = items
          .where((item) => item['hidden'] != true)
          .toList();

      expect(activeItems.any((item) => item.containsKey('promo')), isFalse);
      expect(
        activeItems.any((item) => item['akasha_catalog_kind'] == 'support'),
        isFalse,
      );
      expect(
        activeItems,
        everyElement(
          allOf(
            containsPair('tradable', false),
            containsPair('marketable', false),
            contains('name_koreana'),
            contains('description_koreana'),
          ),
        ),
      );
    },
  );
}
