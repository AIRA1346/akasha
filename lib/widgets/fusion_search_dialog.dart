import 'dart:async';
import 'package:flutter/material.dart';
import '../models/akasha_item.dart';
import '../services/works_registry.dart';
import '../widgets/star_rating.dart';

/// 3중 퓨전 검색: [로컬 .md] + [원격 사전] + [직접 추가 CTA]
class FusionSearchDialog extends StatefulWidget {
  final List<AkashaItem> localItems;
  final void Function(AkashaItem item) onSelectLocal;
  final Future<void> Function(RegistryWork work) onSelectRemote;
  final void Function(String query) onCustomAdd;

  const FusionSearchDialog({
    super.key,
    required this.localItems,
    required this.onSelectLocal,
    required this.onSelectRemote,
    required this.onCustomAdd,
  });

  @override
  State<FusionSearchDialog> createState() => _FusionSearchDialogState();
}

class _FusionSearchDialogState extends State<FusionSearchDialog> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<AkashaItem> _localResults = [];
  List<RegistryWork> _remoteResults = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _localResults = [];
        _remoteResults = [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(trimmed);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final q = query.toLowerCase();
    final local = widget.localItems.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.creator.toLowerCase().contains(q) ||
          item.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    final localWorkIds = local
        .map((e) => e.workId)
        .where((id) => id.isNotEmpty)
        .toSet();

    List<RegistryWork> remote = [];
    String? error;
    try {
      final registryHits = await WorksRegistry.searchAsync(query);
      remote = registryHits
          .where((work) => !localWorkIds.contains(work.workId))
          .toList();
    } catch (e) {
      error = '원격 사전 검색 실패 (오프라인일 수 있습니다)';
    }

    if (!mounted) return;
    setState(() {
      _localResults = local;
      _remoteResults = remote;
      _isSearching = false;
      _searchError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _ctrl.text.trim();
    final showCustomCta =
        query.isNotEmpty && !_isSearching && _localResults.isEmpty && _remoteResults.isEmpty;

    return AlertDialog(
      title: const Text('🔍 작품 검색'),
      content: SizedBox(
        width: 440,
        height: 460,
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '제목, 작가, 태그로 검색...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _onQueryChanged,
            ),
            if (_searchError != null) ...[
              const SizedBox(height: 8),
              Text(
                _searchError!,
                style: TextStyle(fontSize: 11, color: Colors.orange[300]),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: query.isEmpty
                  ? Center(
                      child: Text(
                        '검색어를 입력하세요.\n로컬 아카이브와 글로벌 사전을 함께 검색합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    )
                  : ListView(
                      children: [
                        if (_localResults.isNotEmpty) ...[
                          _sectionLabel('📂 내 아카이브', _localResults.length),
                          ..._localResults.map(_buildLocalTile),
                          const SizedBox(height: 8),
                        ],
                        if (_remoteResults.isNotEmpty) ...[
                          _sectionLabel('🌐 글로벌 사전', _remoteResults.length),
                          ..._remoteResults.map(_buildRemoteTile),
                        ],
                        if (showCustomCta) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onCustomAdd(query);
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('사전에 없는 작품 직접 추가하기'),
                            ),
                          ),
                        ],
                        if (!_isSearching &&
                            query.isNotEmpty &&
                            _localResults.isEmpty &&
                            _remoteResults.isEmpty &&
                            _searchError == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(child: Text('검색 결과가 없습니다.')),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.tealAccent,
        ),
      ),
    );
  }

  Widget _buildLocalTile(AkashaItem item) {
    return ListTile(
      dense: true,
      leading: Icon(item.category.icon, size: 20),
      title: Text(item.title, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        item.creator.isNotEmpty ? item.creator : '내 아카이브',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: StarRating(rating: item.rating, size: 11),
      onTap: () {
        Navigator.pop(context);
        widget.onSelectLocal(item);
      },
    );
  }

  Widget _buildRemoteTile(RegistryWork work) {
    return ListTile(
      dense: true,
      leading: Icon(work.category.icon, size: 20, color: Colors.lightBlueAccent),
      title: Text(work.title, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        work.creator.isNotEmpty ? work.creator : '글로벌 사전',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('사전', style: TextStyle(fontSize: 10, color: Colors.lightBlueAccent)),
      ),
      onTap: () async {
        Navigator.pop(context);
        await widget.onSelectRemote(work);
      },
    );
  }
}
