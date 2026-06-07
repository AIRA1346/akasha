import 'package:flutter/material.dart';

/// 볼트 미연동 시 데모 모드 안내 배너
class HomeVaultBanner extends StatelessWidget {
  final VoidCallback onConnectVault;

  const HomeVaultBanner({super.key, required this.onConnectVault});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '현재 데모용 샘플 데이터를 보고 있습니다. 로컬 폴더(Obsidian Vault)를 연동하여 마크다운 파일로 실제 아카이빙을 시작해 보세요!',
              style: TextStyle(fontSize: 12, color: Colors.amber),
            ),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: onConnectVault,
            icon: const Icon(Icons.folder_open, size: 16, color: Colors.amber),
            label: const Text(
              '폴더 연동',
              style: TextStyle(fontSize: 12, color: Colors.amber),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              side: const BorderSide(color: Colors.amber),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
