import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/features/workbench/presentation/workbench_link_pick_ops.dart';
import 'package:akasha/models/entity_link_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkbenchLinkPickOps.classifyPending', () {
    const request = WorkbenchPendingLinkRequest(
      contextId: 'wk_manga_a',
      entityLinkType: EntityAnchorType.person,
    );

    test('wrongContext when pending id mismatches', () {
      expect(
        WorkbenchLinkPickOps.classifyPending(
          request: request,
          currentContextId: 'wk_manga_b',
          catalog: _FakeCatalog(),
        ),
        WorkbenchPendingLinkResolution.wrongContext,
      );
    });

    test('pickEntity when context matches and catalog present', () {
      expect(
        WorkbenchLinkPickOps.classifyPending(
          request: request,
          currentContextId: 'wk_manga_a',
          catalog: _FakeCatalog(),
        ),
        WorkbenchPendingLinkResolution.pickEntity,
      );
    });

    test('pickWork when pendingWorkLinkPick is true', () {
      expect(
        WorkbenchLinkPickOps.classifyPending(
          request: const WorkbenchPendingLinkRequest(
            pendingWorkLinkPick: true,
          ),
          currentContextId: 'wk_manga_a',
          catalog: null,
        ),
        WorkbenchPendingLinkResolution.pickWork,
      );
    });

    test('skipped when entity type missing', () {
      expect(
        WorkbenchLinkPickOps.classifyPending(
          request: const WorkbenchPendingLinkRequest(),
          currentContextId: 'wk_manga_a',
          catalog: _FakeCatalog(),
        ),
        WorkbenchPendingLinkResolution.skipped,
      );
    });
  });

  test('applyToBodyController inserts wiki link token', () {
    final ctrl = TextEditingController(text: '본문 ');
    ctrl.selection = const TextSelection.collapsed(offset: 3);
    const picked = EntityLinkSelection(
      entityId: 'ent_person_x',
      title: '인물',
      entityType: 'person',
    );

    WorkbenchLinkPickOps.applyToBodyController(bodyCtrl: ctrl, picked: picked);

    expect(ctrl.text, contains('[[ent_person_x|인물]]'));
  });
}

class _FakeCatalog implements UserCatalogPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
