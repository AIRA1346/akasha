import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/vault_work_presence.dart';

ContentItem _vaultWork({String id = 'wk_u_test01'}) {
  final item = ContentItem(
    workId: id,
    title: 'Vault Work',
    category: MediaCategory.movie,
    domain: AppDomain.subculture,
  );
  item.filePath = '/vault/test.md';
  return item;
}

void main() {
  group('VaultWorkPresence', () {
    test('detects archived vault item by work id', () {
      final item = _vaultWork();
      expect(
        VaultWorkPresence.isArchivedInVault(item.workId, [item]),
        isTrue,
      );
      expect(
        VaultWorkPresence.isRegistryOnlyPreview(item, [item]),
        isFalse,
      );
    });

    test('registry preview item without vault file is registry-only', () {
      final registryPreview = ContentItem(
        workId: 'wk_000000001',
        title: 'Interstellar',
        category: MediaCategory.movie,
        domain: AppDomain.subculture,
        creator: 'Christopher Nolan',
      );

      expect(
        VaultWorkPresence.isRegistryOnlyPreview(registryPreview, const []),
        isTrue,
      );
      expect(
        VaultWorkPresence.isRegistryOnlyPreview(
          registryPreview,
          [_vaultWork(id: 'wk_u_other')],
        ),
        isTrue,
      );
    });
  });
}
