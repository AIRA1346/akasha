import 'package:flutter/material.dart';

/// 상세 화면 섹션 제목
Widget detailSectionTitle(String emoji, String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
