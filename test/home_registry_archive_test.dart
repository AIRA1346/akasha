import 'package:akasha/models/enums.dart';
import 'package:akasha/models/registry_work.dart';
import 'package:akasha/screens/home/home_registry_archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_vault_port.dart';

void main() {
  test('archives a registry Work through the Vault writer', () async {
    final vault = FakeVaultPort();
    const work = RegistryWork(
      workId: 'wk_registry_alpha',
      title: 'Registry Alpha',
      category: MediaCategory.movie,
      domain: AppDomain.subculture,
    );

    final saved = await HomeRegistryArchive.persistRegistryWork(
      work,
      vault: vault,
      onDemoAdd: (_) {},
    );

    expect(vault.inMemoryCache[saved.workId], same(saved));
  });
}
