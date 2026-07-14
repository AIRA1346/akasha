import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/core/ports/record_link_port.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/services/record_link_stale_label.dart';

/// R2-D Step 3 — mirrors Entity Sheet incoming load + refresh UI.
class _IncomingRefreshHarness extends StatefulWidget {
  const _IncomingRefreshHarness({
    required this.linkIndex,
    required this.entityId,
    required this.currentTitle,
  });

  final RecordLinkPort linkIndex;
  final String entityId;
  final String currentTitle;

  @override
  State<_IncomingRefreshHarness> createState() =>
      _IncomingRefreshHarnessState();
}

class _IncomingRefreshHarnessState extends State<_IncomingRefreshHarness> {
  List<String> _paths = const [];
  var _staleRecordCount = 0;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _loadIncoming();
  }

  Future<void> _loadIncoming() async {
    setState(() => _loading = true);
    final paths = await widget.linkIndex.incomingRecordPaths(widget.entityId);
    final uniquePaths = paths.toSet().toList()..sort();
    final stale = await RecordLinkStaleLabel.countForEntity(
      linkIndex: widget.linkIndex,
      entityId: widget.entityId,
      currentTitle: widget.currentTitle,
    );
    if (!mounted) return;
    setState(() {
      _paths = uniquePaths;
      _staleRecordCount = stale.staleRecordCount;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('연결된 Record ${_paths.length}개'),
                  if (_staleRecordCount > 0)
                    Text('제목 갱신 필요 $_staleRecordCount개'),
                ],
              ),
            ),
            IconButton(
              key: const Key('entity_incoming_refresh'),
              icon: const Icon(Icons.refresh),
              onPressed: _loadIncoming,
            ),
          ],
        ),
        ..._paths.map(Text.new),
      ],
    );
  }
}

class _FakeLinkIndex implements RecordLinkPort {
  @override
  Future<RecordLinkSummary> loadSummary() async => RecordLinkSummary.empty;

  _FakeLinkIndex({
    Map<String, List<String>>? incomingByEntity,
    Map<String, List<RecordLink>>? outgoingByPath,
  }) : incomingByEntity = incomingByEntity ?? {},
       outgoingByPath = outgoingByPath ?? {};

  final Map<String, List<String>> incomingByEntity;
  final Map<String, List<RecordLink>> outgoingByPath;

  void setSnapshot({
    required List<String> incomingPaths,
    required List<RecordLink> outgoingLinks,
  }) {
    incomingByEntity['pe_u_target01'] = List.from(incomingPaths);
    for (final link in outgoingLinks) {
      outgoingByPath.putIfAbsent(link.sourceRecordId, () => []).add(link);
    }
  }

  @override
  Future<List<String>> incomingRecordPaths(String entityId) async =>
      List.unmodifiable(incomingByEntity[entityId] ?? const []);

  @override
  Future<Iterable<String>> incomingEntityIds() async => incomingByEntity.keys;

  @override
  Future<List<RecordLink>> outgoingLinks(String sourcePath) async =>
      List.unmodifiable(outgoingByPath[sourcePath] ?? const []);

  @override
  Future<void> rebuildIndex({
    String? changedPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('refresh reloads incoming and stale counts after index change', (
    tester,
  ) async {
    const entityId = 'pe_u_target01';
    const workPath = r'C:\vault\works\memo.md';
    const currentTitle = '스바루';

    final index = _FakeLinkIndex();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _IncomingRefreshHarness(
            linkIndex: index,
            entityId: entityId,
            currentTitle: currentTitle,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('연결된 Record 0개'), findsOneWidget);
    expect(find.textContaining('제목 갱신 필요'), findsNothing);

    index.setSnapshot(
      incomingPaths: [workPath],
      outgoingLinks: [
        RecordLink(
          sourceRecordId: workPath,
          kind: RecordLinkKind.explicitId,
          raw: entityId,
          targetEntityId: entityId,
          displayLabel: '나츠키 스바루',
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('entity_incoming_refresh')));
    await tester.pumpAndSettle();

    expect(find.text('연결된 Record 1개'), findsOneWidget);
    expect(find.text('제목 갱신 필요 1개'), findsOneWidget);
    expect(find.textContaining('memo.md'), findsOneWidget);
  });
}
