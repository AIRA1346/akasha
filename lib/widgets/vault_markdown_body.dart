import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../utils/vault_asset_resolver.dart';
import 'safe_local_image.dart';

/// Sanctum vault md 본문 렌더러 — vault 상대 이미지·외부 URL 지원
class VaultMarkdownBody extends StatelessWidget {
  final String data;
  final String? mdFilePath;

  const VaultMarkdownBody({
    super.key,
    required this.data,
    this.mdFilePath,
  });

  static const _networkImageHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  @override
  Widget build(BuildContext context) {
    if (data.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          'Sanctum 페이지가 비어 있습니다.\n'
          '「본문」 또는 「.md」 탭에서 감상·메모를 작성해 보세요.',
          style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
        ),
      );
    }

    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    final sheet = base.copyWith(
      h1: base.h1?.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
      h2: base.h2?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
      h3: base.h3?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      p: base.p?.copyWith(fontSize: 14, height: 1.55),
      blockquote: base.blockquote?.copyWith(
        color: Colors.tealAccent.withValues(alpha: 0.85),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.tealAccent.withValues(alpha: 0.4),
            width: 3,
          ),
        ),
      ),
      code: base.code?.copyWith(
        backgroundColor: const Color(0xFF2A2A3A),
        fontFamily: 'monospace',
        fontSize: 12,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MarkdownBody(
        data: data,
        styleSheet: sheet,
        selectable: true,
        imageBuilder: (uri, title, alt) =>
            _buildImage(uri.toString(), alt ?? title),
      ),
    );
  }

  Widget _buildImage(String src, String? alt) {
    final local = VaultAssetResolver.resolveImageFile(
      src,
      mdFilePath: mdFilePath,
    );
    if (local != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SafeLocalImage(
            file: local,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _brokenImage(alt),
          ),
        ),
      );
    }

    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            src,
            headers: _networkImageHeaders,
            errorBuilder: (_, __, ___) => _brokenImage(alt),
          ),
        ),
      );
    }

    return _brokenImage(alt ?? src);
  }

  Widget _brokenImage(String? label) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black26,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, size: 18, color: Colors.grey[600]),
          if (label != null && label.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
