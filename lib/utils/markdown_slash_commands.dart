/// `/` 슬래시 커맨드 — 본문·전체 md 편집기 공통.
class MarkdownSlashCommand {
  const MarkdownSlashCommand({
    required this.id,
    required this.label,
    required this.keywords,
    this.description = '',
  });

  final String id;
  final String label;
  final List<String> keywords;
  final String description;
}

class MarkdownSlashMatch {
  const MarkdownSlashMatch({
    required this.commandStart,
    required this.lineEnd,
    required this.query,
    required this.candidates,
  });

  /// `/` 문자 오프셋
  final int commandStart;
  final int lineEnd;
  final String query;
  final List<MarkdownSlashCommand> candidates;
}

class MarkdownSlashCommands {
  MarkdownSlashCommands._();

  static const commands = <MarkdownSlashCommand>[
    MarkdownSlashCommand(
      id: 'synopsis',
      label: '시놉시스 섹션',
      keywords: ['시놉', 'synopsis', '시놉시스'],
      description: '# 📋 시놉시스',
    ),
    MarkdownSlashCommand(
      id: 'quotes',
      label: '명장면 & 명대사',
      keywords: ['인용', '명대사', '명장면', 'quote', 'quotes'],
      description: '# 🎬 명장면 & 명대사',
    ),
    MarkdownSlashCommand(
      id: 'memo',
      label: '메모 섹션',
      keywords: ['메모', 'memo', '감상', 'review'],
      description: '# 📝 메모',
    ),
    MarkdownSlashCommand(
      id: 'quote_line',
      label: '인용 한 줄',
      keywords: ['인용줄', 'q'],
      description: '> 인용문',
    ),
    MarkdownSlashCommand(
      id: 'link',
      label: '링크',
      keywords: ['링크', 'link'],
      description: '[텍스트](url)',
    ),
    MarkdownSlashCommand(
      id: 'image',
      label: '이미지',
      keywords: ['이미지', 'image', 'img'],
      description: '![](path)',
    ),
    MarkdownSlashCommand(
      id: 'code_block',
      label: '코드 블록',
      keywords: ['코드', 'code'],
      description: '``` … ```',
    ),
    MarkdownSlashCommand(
      id: 'hr',
      label: '구분선',
      keywords: ['구분선', 'hr', 'line'],
      description: '---',
    ),
    MarkdownSlashCommand(
      id: 'h1',
      label: '제목 1',
      keywords: ['h1', '제목1'],
      description: '# ',
    ),
    MarkdownSlashCommand(
      id: 'h2',
      label: '제목 2',
      keywords: ['h2', '제목2'],
      description: '## ',
    ),
    MarkdownSlashCommand(
      id: 'h3',
      label: '제목 3',
      keywords: ['h3', '제목3'],
      description: '### ',
    ),
    MarkdownSlashCommand(
      id: 'bullet',
      label: '글머리 목록',
      keywords: ['목록', 'bullet', 'ul'],
      description: '- ',
    ),
    MarkdownSlashCommand(
      id: 'numbered',
      label: '번호 목록',
      keywords: ['번호', 'ol', '1'],
      description: '1. ',
    ),
  ];

  /// 커서가 `/키워드` 줄에 있으면 매치 반환.
  static MarkdownSlashMatch? matchAtOffset(String text, int offset) {
    if (text.isEmpty) return null;
    final safeOffset = offset.clamp(0, text.length);
    final lineStart = _lineStart(text, safeOffset);
    final lineEnd = _lineEnd(text, safeOffset);
    final line = text.substring(lineStart, lineEnd);
    final trimmed = line.trimLeft();
    if (!trimmed.startsWith('/')) return null;

    final slashInLine = line.indexOf('/');
    if (slashInLine < 0) return null;
    final commandStart = lineStart + slashInLine;
    final query = line.substring(slashInLine + 1);
    if (query.contains(' ')) return null;

    final lower = query.toLowerCase();
    final candidates = commands
        .where((c) {
          if (lower.isEmpty) return true;
          return c.keywords.any((k) => k.toLowerCase().startsWith(lower)) ||
              c.id.startsWith(lower) ||
              c.label.toLowerCase().contains(lower);
        })
        .toList();

    if (candidates.isEmpty) return null;

    return MarkdownSlashMatch(
      commandStart: commandStart,
      lineEnd: lineEnd,
      query: query,
      candidates: candidates,
    );
  }

  static int _lineStart(String text, int offset) {
    final i = text.lastIndexOf('\n', offset - 1);
    return i < 0 ? 0 : i + 1;
  }

  static int _lineEnd(String text, int offset) {
    final i = text.indexOf('\n', offset);
    return i < 0 ? text.length : i;
  }
}
