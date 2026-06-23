import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// R4-B2: `HomeBrowseCoordinator.buildPosterCard` open policy.
void Function(dynamic) _explorationOpenHandler({
  required void Function(dynamic item)? onPreviewWork,
  required void Function(dynamic item) openBrowse,
}) {
  return onPreviewWork ?? openBrowse;
}

void main() {
  test('library grid uses preview callback when wired (R4-B2)', () {
    final item = createItem(
      workId: 'wk_lib_preview',
      title: 'Library Preview Work',
      category: MediaCategory.manga,
    );
    dynamic opened;
    var workbenchCalled = false;

    final open = _explorationOpenHandler(
      onPreviewWork: (i) => opened = i,
      openBrowse: (_) => workbenchCalled = true,
    );

    open(item);

    expect(opened, item);
    expect(workbenchCalled, isFalse);
  });

  test('library grid falls back to workbench when preview not wired', () {
    final item = createItem(
      workId: 'wk_lib_fallback',
      title: 'Fallback',
      category: MediaCategory.manga,
    );
    dynamic opened;
    var workbenchCalled = false;

    final open = _explorationOpenHandler(
      onPreviewWork: null,
      openBrowse: (i) {
        workbenchCalled = true;
        opened = i;
      },
    );

    open(item);

    expect(workbenchCalled, isTrue);
    expect(opened, item);
  });
}
