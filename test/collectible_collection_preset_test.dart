import 'package:akasha/models/collectible_collection.dart';
import 'package:akasha/models/collectible_collection_preset.dart';
import 'package:akasha/models/collectible_kind.dart';
import 'package:akasha/screens/home/home_collectible_collection_controller.dart';
import 'package:akasha/services/collectible_collection_storage_service.dart';
import 'package:akasha/services/file_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('buildRelatedWorkCollection', () {
    test('builds filter collection with person kind and relatedWorkId only', () {
      final collection = buildRelatedWorkCollection(
        title: 'Re:Zero Cast',
        workId: 'wk_u_rezero01',
      );

      expect(collection.mode, CollectibleCollectionMode.filter);
      expect(collection.title, 'Re:Zero Cast');
      expect(collection.filter?.kinds, [CollectibleKind.person]);
      expect(collection.filter?.relatedWorkId, 'wk_u_rezero01');
      expect(collection.filter?.tagsAll, isNull);
      expect(collection.memberOrder, isEmpty);
    });

    test('controller helper matches preset builder', () {
      final fromController = HomeCollectibleCollectionController
          .buildRelatedWorkCollection(
        title: 'Fate Cast',
        workId: 'wk_u_fate_stay_night',
      );
      final fromPreset = CollectibleCollectionPresets.fateCast.build();

      expect(fromController.filter?.relatedWorkId, fromPreset.filter?.relatedWorkId);
      expect(fromController.filter?.tagsAll, isNull);
      expect(fromController.title, 'Fate Cast');
    });
  });

  group('CollectibleCollectionPresets', () {
    test('Re:Zero preset uses wk_u_rezero01', () {
      final collection = CollectibleCollectionPresets.rezeroCast.build();

      expect(collection.title, 'Re:Zero Cast');
      expect(collection.filter?.relatedWorkId, 'wk_u_rezero01');
      expect(collection.filter?.tagsAll, isNull);
    });

    test('Fate preset uses wk_u_fate_stay_night', () {
      final collection = CollectibleCollectionPresets.fateCast.build();

      expect(collection.title, 'Fate Cast');
      expect(collection.filter?.relatedWorkId, 'wk_u_fate_stay_night');
    });

    test('isAvailableIn requires known workId', () {
      expect(
        CollectibleCollectionPresets.rezeroCast.isAvailableIn(
          const {'wk_u_rezero01', 'wk_u_other001'},
        ),
        isTrue,
      );
      expect(
        CollectibleCollectionPresets.rezeroCast.isAvailableIn(
          const {'wk_u_fate_stay_night'},
        ),
        isFalse,
      );
    });
  });

  group('CollectibleCollectionStorageService preset persistence', () {
    test('Re:Zero preset survives save and reload', () async {
      final fileService = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_preset_');
      try {
        await fileService.setVaultPath(tempDir.path);
        final storage = CollectibleCollectionStorageService();
        final original = [CollectibleCollectionPresets.rezeroCast.build()];

        await storage.save(original);
        final reloaded = await storage.load();

        expect(reloaded, hasLength(1));
        expect(reloaded.first.title, 'Re:Zero Cast');
        expect(reloaded.first.filter?.relatedWorkId, 'wk_u_rezero01');
        expect(reloaded.first.filter?.tagsAll, isNull);
        expect(reloaded.first.filter?.kinds?.map((k) => k.name), ['person']);
      } finally {
        await fileService.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('Fate preset survives save and reload', () async {
      final fileService = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_preset_');
      try {
        await fileService.setVaultPath(tempDir.path);
        final storage = CollectibleCollectionStorageService();
        final original = [CollectibleCollectionPresets.fateCast.build()];

        await storage.save(original);
        final reloaded = await storage.load();

        expect(reloaded.first.filter?.relatedWorkId, 'wk_u_fate_stay_night');
        expect(reloaded.first.filter?.tagsAll, isNull);
      } finally {
        await fileService.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
