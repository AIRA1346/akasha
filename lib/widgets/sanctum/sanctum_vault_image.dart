import 'package:flutter/material.dart';

import '../../utils/vault_asset_resolver.dart';
import '../safe_local_image.dart';
import '../../theme/akasha_colors.dart';

/// Sanctum 미리보기 — vault 상대 경로 마크다운 이미지.
class SanctumVaultImage extends StatelessWidget {
  const SanctumVaultImage({
    super.key,
    required this.src,
    this.mdFilePath,
    this.caption,
    this.height = 160,
    this.fit = BoxFit.cover,
  });

  final String src;
  final String? mdFilePath;
  final String? caption;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final local = VaultAssetResolver.resolveImageFile(
      src,
      mdFilePath: mdFilePath,
    );

    Widget image;
    if (local != null) {
      image = SafeLocalImage(
        file: local,
        fit: fit,
        height: height,
        width: double.infinity,
        errorBuilder: (_, _, _) => _broken(),
      );
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      image = Image.network(
        src,
        fit: fit,
        height: height,
        width: double.infinity,
        errorBuilder: (_, _, _) => _broken(),
      );
    } else {
      image = _broken();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image,
          ),
          if (caption != null && caption!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AkashaColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _broken() {
    return Container(
      height: height,
      color: Colors.black26,
      child: Center(
        child: Icon(Icons.broken_image, size: 28, color: AkashaColors.textCaption),
      ),
    );
  }
}
