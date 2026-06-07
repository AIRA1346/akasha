import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kAkashaPromptTemplate = '''
당신은 서브컬처(만화, 게임, 애니메이션, 책) 아카이빙 전문가입니다.
사용자가 요청한 작품의 정보를 아래 YAML Front-Matter 형식을 포함한 마크다운 문서로 작성해 주세요.

---
work_id: "" (비워두면 AKASHA가 사전 매칭 또는 custom ID를 부여)
title: "작품의 정확한 제목"
category: manga | game | animation | book | movie | drama (하나만)
domain: subculture | generalCulture (대분류에 맞게 하나만 선택)
creator: "원작자 / 제작사 / 감독 등"
release_year: 출시 또는 연재 시작 연도 (숫자만, 예: 2011)
rating: 5.0 (0.0~5.0 범위의 실수)
work_status: "연재중" | "휴재중" | "완결" (game 카테고리인 경우: "출시됨" | "얼리액세스" | "출시예정")
my_status: "아직 안 봄" | "보는 중" | "전부 봄" | "하차함" (game 카테고리인 경우: "할 예정(백로그)" | "플레이 중" | "클리어함" | "중도하차")
is_hall_of_fame: true | false (인생 명작 여부)
tags: [태그1, 태그2] (예: [청춘, 감동, 음악])
poster: "" (비워둠)
added_at: "현재 날짜 및 시간 (ISO 8601 형식, 예: 2026-06-05T19:00:00)"
---

# 📝 작품 특징
(작품의 줄거리, 특징, 추천 이유 등을 마크다운으로 작성)

# 🎬 명장면 & 명대사
> "명대사 내용 1" — 캐릭터 이름 / 상황 설명 (화수 등)

> "명대사 내용 2" — 캐릭터 이름 / 상황 설명

# 📖 감상문
(작품에 대한 감상문을 자유롭게 작성)
''';

/// AI 프롬프트 템플릿 복사 다이얼로그
Future<void> showPromptTemplatesDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('📋 AI 프롬프트 템플릿'),
      content: SizedBox(
        width: 500,
        height: 350,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이 템플릿을 AI에게 제공하면, 규격에 맞는 마크다운을 쉽게 받아올 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    kAkashaPromptTemplate,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('닫기'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              const ClipboardData(text: kAkashaPromptTemplate),
            );
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('템플릿이 클립보드에 복사되었습니다.')),
              );
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('복사하기'),
        ),
      ],
    ),
  );
}
