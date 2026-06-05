import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../services/image_search_service.dart';

class WebImageSearchDialog extends StatefulWidget {
  final String initialQuery;
  final MediaCategory category;

  const WebImageSearchDialog({
    super.key,
    required this.initialQuery,
    required this.category,
  });

  @override
  State<WebImageSearchDialog> createState() => _WebImageSearchDialogState();
}

class _WebImageSearchDialogState extends State<WebImageSearchDialog> {
  late TextEditingController _searchCtrl;
  bool _searching = false;
  List<Map<String, String>> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery);
    _performSearch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });

    try {
      final results = await ImageSearchService().searchCovers(query, widget.category);
      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '검색 중 오류가 발생했습니다: $e';
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🌐 포스터 웹 이미지 검색'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          children: [
            // 검색바
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: '검색할 작품 제목 입력...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('검색'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 검색 결과
            Expanded(
              child: _searching
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('인터넷에서 표지 검색 중...', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                      : _results.isEmpty
                          ? const Center(child: Text('검색 결과가 없습니다.'))
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _results.length,
                              itemBuilder: (ctx, idx) {
                                final res = _results[idx];
                                final title = res['title'] ?? '';
                                final coverUrl = res['coverUrl'] ?? '';
                                final source = res['source'] ?? '';

                                return GestureDetector(
                                  onTap: () => Navigator.pop(context, coverUrl),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E2E),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.08),
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // 표지 이미지 썸네일
                                          coverUrl.isNotEmpty
                                              ? Image.network(
                                                  coverUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                                )
                                              : const Center(child: Icon(Icons.image, color: Colors.grey)),
                                          
                                          // 하단 정보 레이어
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              color: Colors.black.withValues(alpha: 0.8),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 5,
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    source,
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: Colors.grey[400],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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
}
