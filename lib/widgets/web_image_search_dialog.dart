import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/enums.dart';
import '../services/file_service.dart';
import '../utils/helpers.dart';

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
  late TextEditingController _manualUrlCtrl;
  Timer? _clipboardTimer;
  String? _detectedClipboardUrl;
  bool _isClipboardUrlValid = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: '${widget.initialQuery} 포스터');
    _manualUrlCtrl = TextEditingController();
    _startClipboardMonitoring();
  }

  @override
  void dispose() {
    _stopClipboardMonitoring();
    _searchCtrl.dispose();
    _manualUrlCtrl.dispose();
    super.dispose();
  }

  /// 클립보드를 주기적으로 모니터링하여 이미지 주소를 감지합니다.
  void _startClipboardMonitoring() {
    _clipboardTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text?.trim() ?? '';
        if (text.isNotEmpty && text != _detectedClipboardUrl) {
          final isValid = isValidImageUrl(text);
          if (mounted) {
            setState(() {
              _detectedClipboardUrl = text;
              _isClipboardUrlValid = isValid;
              if (isValid) {
                // 감지 시 수동 입력란에도 자동 편의성 세팅
                _manualUrlCtrl.text = text;
              }
            });
          }
        }
      } catch (_) {
        // 백그라운드 모니터링 중 에러 방지
      }
    });
  }

  void _stopClipboardMonitoring() {
    _clipboardTimer?.cancel();
    _clipboardTimer = null;
  }

  Future<void> _pickLocalImage() async {
    final fileResult = await FilePicker.pickFiles(type: FileType.image);
    if (fileResult == null || fileResult.files.single.path == null) return;

    final path = fileResult.files.single.path!;
    final service = AkashaFileService();
    if (!mounted) return;

    if (service.vaultPath != null) {
      final relativePath = await service.importPosterImage(path);
      if (relativePath != null && mounted) {
        Navigator.pop(context, relativePath);
      }
    } else {
      Navigator.pop(context, path);
    }
  }

  /// 시스템 브라우저를 띄워 검색 수행
  Future<void> _launchBrowser(String baseUrl) async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    final fullUrl = '$baseUrl${Uri.encodeComponent(query)}';
    final uri = Uri.parse(fullUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('브라우저를 열 수 없습니다. 주소를 수동 복사해주세요.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('브라우저 실행 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.image_search, color: Colors.tealAccent),
          SizedBox(width: 10),
          Text('🌐 아카이브 포스터 이미지 교정'),
        ],
      ),
      content: SizedBox(
        width: 540,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용 설명 가이드
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 스마트 이미지 교정 방법',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.tealAccent,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. 아래 검색어로 구글/핀터레스트에서 포스터를 검색합니다.\n'
                    '2. 마음에 드는 이미지를 우클릭하여 [이미지 주소 복사]를 실행합니다.\n'
                    '3. 앱이 클립보드의 복사된 주소를 자동으로 감지하여 바로 적용해 줍니다.',
                    style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 검색어 및 브라우저 열기 버튼
            const Text(
              '포스터 검색어',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: '작품 포스터 검색어 입력...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C3E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _launchBrowser('https://www.google.com/search?tbm=isch&q='),
                    icon: const Icon(Icons.travel_explore, size: 16, color: Colors.blueAccent),
                    label: const Text('구글 이미지 검색 열기'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    onPressed: () => _launchBrowser('https://www.pinterest.co.kr/search/pins/?q='),
                    icon: const Icon(Icons.push_pin, size: 16, color: Colors.redAccent),
                    label: const Text('핀터레스트 검색 열기'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 클립보드 감지 프리뷰 영역
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161622),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isClipboardUrlValid 
                        ? Colors.tealAccent.withValues(alpha: 0.3) 
                        : Colors.white.withValues(alpha: 0.05),
                    width: _isClipboardUrlValid ? 1.5 : 1,
                  ),
                ),
                child: _isClipboardUrlValid && _detectedClipboardUrl != null
                    ? Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.tealAccent, size: 16),
                              SizedBox(width: 6),
                              Text(
                                '클립보드에서 이미지 주소 감지 완료!',
                                style: TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Row(
                              children: [
                                // 썸네일 미리보기
                                Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    _detectedClipboardUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // 주소 정보 및 적용 버튼
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _detectedClipboardUrl!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          color: Colors.white70,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.tealAccent,
                                          foregroundColor: Colors.black,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context, _detectedClipboardUrl);
                                        },
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text('이 이미지로 포스터 교정'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.teal.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '인터넷 브라우저에서 포스터 주소를 복사하기를 기다리는 중...',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickLocalImage,
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('로컬 이미지 선택'),
            ),
            const SizedBox(height: 12),

            // 수동 입력창 (폴백용)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualUrlCtrl,
                    decoration: const InputDecoration(
                      hintText: '또는 여기에 직접 이미지 URL 입력...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = _manualUrlCtrl.text.trim();
                    if (isValidImageUrl(text)) {
                      Navigator.pop(context, text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('올바르지 않은 이미지 URL 주소입니다.')),
                      );
                    }
                  },
                  child: const Text('수동 적용'),
                ),
              ],
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
