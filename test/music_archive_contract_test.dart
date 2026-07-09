import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:akasha/core/archiving/archive_record_contract.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/record_summary_index_service.dart';

void main() {
  group('Music & OST Representation Architecture Tests (UA-108)', () {
    test('1. parse soundtrack album and track as Work category: music', () {
      const albumYaml = '''---
schema_version: 3
record_id: "rec_wk_u_rezero_ost"
work_id: "wk_u_rezero_ost"
entity_type: work
entity_id: "wk_u_rezero_ost"
record_kind: workJournal
title: "Re:제로부터 시작하는 이세계 생활 OST Vol.1"
category: music
entity_subtype: album
release_year: 2016
links:
  - relation: "ost_of"
    target_id: "wk_u_rezero"
    target_title: "Re:제로부터 시작하는 이세계 생활"
---
오리지널 사운드트랙 앨범.
''';

      const trackYaml = '''---
schema_version: 3
record_id: "rec_wk_u_stay_alive"
work_id: "wk_u_stay_alive"
entity_type: work
entity_id: "wk_u_stay_alive"
record_kind: workJournal
title: "Stay Alive"
category: music
entity_subtype: track
release_year: 2016
links:
  - relation: "track_of"
    target_id: "wk_u_rezero_ost"
    target_title: "Re:Zero OST Vol.1"
  - relation: "vocalist"
    target_id: "pe_u_rie_takahashi"
    target_title: "타카하시 리에"
---
2기 엔딩 테마곡.
''';

      // 1. 앨범 파싱 검증
      final albumFrontmatter = albumYaml.split('---')[1];
      final albumMeta = ArchiveRecordContract.metadataFromYaml(
        loadYaml(albumFrontmatter) as Map,
      );

      // MediaCategory parse simulation
      final albumCategoryRaw = (loadYaml(albumFrontmatter) as Map)['category']?.toString();
      final albumCategory = MediaCategory.values.firstWhere(
        (c) => c.name == albumCategoryRaw,
        orElse: () => MediaCategory.manga,
      );

      expect(albumCategory, equals(MediaCategory.music));
      expect(albumMeta.entitySubtype, equals('album'));
      expect(albumMeta.links, hasLength(1));
      expect(albumMeta.links[0].relation, equals('ost_of'));
      expect(albumMeta.links[0].targetId, equals('wk_u_rezero'));

      // 2. 수록곡 파싱 검증
      final trackFrontmatter = trackYaml.split('---')[1];
      final trackMeta = ArchiveRecordContract.metadataFromYaml(
        loadYaml(trackFrontmatter) as Map,
      );

      final trackCategoryRaw = (loadYaml(trackFrontmatter) as Map)['category']?.toString();
      final trackCategory = MediaCategory.values.firstWhere(
        (c) => c.name == trackCategoryRaw,
        orElse: () => MediaCategory.manga,
      );

      expect(trackCategory, equals(MediaCategory.music));
      expect(trackMeta.entitySubtype, equals('track'));
      expect(trackMeta.links, hasLength(2));
      
      final parentAlbumLink = trackMeta.links.firstWhere((l) => l.relation == 'track_of');
      expect(parentAlbumLink.targetId, equals('wk_u_rezero_ost'));
      
      final singerLink = trackMeta.links.firstWhere((l) => l.relation == 'vocalist');
      expect(singerLink.targetId, equals('pe_u_rie_takahashi'));
      expect(singerLink.targetTitle, equals('타카하시 리에'));
    });

    test('2. VaultRecordSummary serialization includes music category and entitySubtype', () async {
      final json = {
        'id': 'wk_u_stay_alive',
        'recordKind': 'workJournal',
        'entityType': 'work',
        'title': 'Stay Alive',
        'path': 'works/music/wk_u_stay_alive.md',
        'category': 'music',
        'entitySubtype': 'track',
        'releaseYear': 2016,
      };

      final summary = VaultRecordSummary.fromJson(json);
      expect(summary.id, equals('wk_u_stay_alive'));
      expect(summary.category, equals('music'));
      expect(summary.entitySubtype, equals('track'));

      final outJson = summary.toJson();
      expect(outJson['category'], equals('music'));
      expect(outJson['entitySubtype'], equals('track'));
    });
  });
}
