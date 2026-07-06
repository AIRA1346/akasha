import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/entity_id_codec.dart';
import 'package:akasha/models/work_id_codec.dart';

void main() {
  group('EntityIdCodec', () {
    test('buildUserLocal for work delegates pattern', () {
      final id = EntityIdCodec.buildUserLocal(EntityAnchorType.work);
      expect(WorkIdCodec.isUserLocalWorkId(id), isTrue);
      expect(EntityIdCodec.typeFromId(id), EntityAnchorType.work);
    });

    test('buildUserLocal for concept person event', () {
      final concept = EntityIdCodec.buildUserLocal(EntityAnchorType.concept);
      expect(concept.startsWith('co_u_'), isTrue);
      expect(EntityIdCodec.typeFromId(concept), EntityAnchorType.concept);

      final person = EntityIdCodec.buildUserLocal(EntityAnchorType.person);
      expect(person.startsWith('pe_u_'), isTrue);
      expect(EntityIdCodec.typeFromId(person), EntityAnchorType.person);

      final event = EntityIdCodec.buildUserLocal(EntityAnchorType.event);
      expect(event.startsWith('ev_u_'), isTrue);
      expect(EntityIdCodec.typeFromId(event), EntityAnchorType.event);

      final place = EntityIdCodec.buildUserLocal(EntityAnchorType.place);
      expect(place.startsWith('pl_u_'), isTrue);
      expect(EntityIdCodec.typeFromId(place), EntityAnchorType.place);

      final org = EntityIdCodec.buildUserLocal(EntityAnchorType.organization);
      expect(org.startsWith('or_u_'), isTrue);
      expect(EntityIdCodec.typeFromId(org), EntityAnchorType.organization);
    });

    test('global id patterns', () {
      expect(EntityIdCodec.isGlobalId('pe_000000001', EntityAnchorType.person), isTrue);
      expect(EntityIdCodec.isGlobalId('co_000000042', EntityAnchorType.concept), isTrue);
      expect(EntityIdCodec.isGlobalId('wk_000000001', EntityAnchorType.work), isTrue);
    });

    test('isUserLocalAny', () {
      expect(
        EntityIdCodec.isUserLocalAny(EntityIdCodec.buildUserLocal(EntityAnchorType.concept)),
        isTrue,
      );
      expect(
        EntityIdCodec.isUserLocalAny(WorkIdCodec.buildUserLocal()),
        isTrue,
      );
      expect(EntityIdCodec.isUserLocalAny('sub_manga_legacy_2020'), isFalse);
    });

    test('unknown and custom legacy falls back', () {
      // Legacy custom prefix maps to object
      expect(EntityIdCodec.typeFromId('cu_u_abc12345'), EntityAnchorType.object);
      expect(EntityIdCodec.typeFromId('cu_123456789'), EntityAnchorType.object);

      // New object prefix maps to object
      expect(EntityIdCodec.typeFromId('ob_u_abc12345'), EntityAnchorType.object);

      // Unrecognized prefix maps to unknown
      expect(EntityIdCodec.typeFromId('xx_u_abc12345'), EntityAnchorType.unknown);
      expect(EntityIdCodec.typeFromId('invalid_id'), EntityAnchorType.unknown);
    });
  });

  group('EntityAnchor.typeForEntityId', () {
    test('maps prefixes to types', () {
      expect(
        EntityAnchor.typeForEntityId(
          EntityIdCodec.buildUserLocal(EntityAnchorType.concept),
        ),
        EntityAnchorType.concept,
      );
      expect(
        EntityAnchor.typeForEntityId(
          EntityIdCodec.buildUserLocal(EntityAnchorType.person),
        ),
        EntityAnchorType.person,
      );
    });

    test('falls back to unknown for invalid prefix', () {
      expect(EntityAnchor.typeForEntityId('xx_u_abc12345'), EntityAnchorType.unknown);
      expect(EntityAnchor.typeForEntityId('invalid'), EntityAnchorType.unknown);
    });
  });
}
