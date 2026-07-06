import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/services/vault_spec_content.dart';

/// Guards against drift between the standalone spec document
/// (`docs/active/AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md`) and the template
/// packaged into every vault (`VaultSpecContent.content`).
///
/// The two are intentionally duplicated (repo SSOT vs self-describing vault
/// copy); this test is what keeps the duplication honest.
void main() {
  test('standalone spec document matches vault-embedded spec template', () {
    final docFile = File(
      'docs/active/AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md',
    );
    expect(
      docFile.existsSync(),
      isTrue,
      reason: 'standalone spec document must exist next to the code',
    );

    final doc = _normalize(docFile.readAsStringSync());
    final template = _normalize(VaultSpecContent.content);

    expect(
      doc,
      template,
      reason:
          'AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md and VaultSpecContent.content '
          'must stay identical. Update both when changing the spec.',
    );
  });
}

String _normalize(String raw) => raw.replaceAll('\r\n', '\n').trim();
