import 'package:yaml/yaml.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../utils/helpers.dart';
import 'works_registry.dart';

class MarkdownParser {
  /// AkashaItem을 마크다운 파일 내용(YAML Front-matter + Markdown Body)으로 직렬화합니다.
  /// 2원화 설계에 따라 공통 정보(작가, 연도, 설명, 포스터 등)는 걷어내고 사용자 기록만 저장합니다.
  static String serialize(AkashaItem item) {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('work_id: "${item.workId}"');
    buffer.writeln('title: "${item.title.replaceAll('"', '\\"')}"'); // 옵시디언 파일 리딩용 제목
    buffer.writeln('category: ${item.category.name}');
    buffer.writeln('domain: ${item.domain.name}');
    buffer.writeln('rating: ${item.rating}');
    
    // 작품 상태 및 나의 상태 저장 (Obsidian 호환성 극대화)
    buffer.writeln('work_status: "${item.workStatusLabel}"');
    buffer.writeln('status: "${item.myStatusLabel}"');
    buffer.writeln('my_status: "${item.myStatusLabel}"');
    buffer.writeln('is_hall_of_fame: ${item.isHallOfFame}');
    
    if (item.tags.isNotEmpty) {
      buffer.writeln('tags: [${item.tags.map((t) => '"${t.replaceAll('"', '\\"')}"').join(', ')}]');
    } else {
      buffer.writeln('tags: []');
    }
    
    buffer.writeln('added_at: "${item.addedAt.toIso8601String()}"');
    buffer.writeln('---');
    buffer.writeln();
    
    // 유저 개인의 기록(명대사, 감상문)만 본문에 남깁니다. (공통 설명 description 등은 DB에 있으므로 저장 생략)
    buffer.writeln('# 🎬 명장면 & 명대사');
    for (final quote in item.memorableQuotes) {
      buffer.writeln('> $quote');
      buffer.writeln();
    }
    
    buffer.writeln('# 📖 감상문');
    buffer.writeln(item.review.trim());
    buffer.writeln();
    
    return buffer.toString();
  }

  /// 마크다운 파일 내용을 파싱하고 공통 사전을 융합(UI Fusion)하여 AkashaItem을 생성합니다.
  static AkashaItem deserialize(String content, String fallbackTitle) {
    final lines = content.split('\n');
    int frontMatterStart = -1;
    int frontMatterEnd = -1;
    
    // YAML Front-matter 영역 찾기
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line == '---') {
        if (frontMatterStart == -1) {
          frontMatterStart = i;
        } else {
          frontMatterEnd = i;
          break;
        }
      }
    }

    Map<dynamic, dynamic> yamlMap = {};
    int bodyStartLine = 0;
    if (frontMatterStart != -1 && frontMatterEnd != -1) {
      final yamlStr = lines.sublist(frontMatterStart + 1, frontMatterEnd).join('\n');
      try {
        final parsed = loadYaml(yamlStr);
        if (parsed is Map) {
          yamlMap = parsed;
        }
      } catch (e) {
        // YAML 파싱 실패 시 비상 정규식 파서 작동 (Phase 5)
        String? regExtract(String key, String text) {
          final reg = RegExp('$key:\\s*"?([^"\\n\\r]+)"?');
          final match = reg.firstMatch(text);
          return match?.group(1)?.trim();
        }

        yamlMap = {
          'work_id': regExtract('work_id', yamlStr),
          'title': regExtract('title', yamlStr),
          'category': regExtract('category', yamlStr),
          'domain': regExtract('domain', yamlStr),
          'rating': regExtract('rating', yamlStr),
          'work_status': regExtract('work_status', yamlStr),
          'status': regExtract('status', yamlStr),
          'my_status': regExtract('my_status', yamlStr),
          'is_hall_of_fame': regExtract('is_hall_of_fame', yamlStr),
          'added_at': regExtract('added_at', yamlStr),
        };
      }
      bodyStartLine = frontMatterEnd + 1;
    }

    // 메타데이터 추출
    String workId = yamlMap['work_id']?.toString() ?? '';
    final title = yamlMap['title']?.toString() ?? fallbackTitle;
    final categoryStr = yamlMap['category']?.toString() ?? 'manga';
    
    MediaCategory category = MediaCategory.manga;
    for (final cat in MediaCategory.values) {
      if (cat.name == categoryStr) {
        category = cat;
        break;
      }
    }

    AppDomain domain = AppDomain.subculture;
    final domainStr = yamlMap['domain']?.toString();
    for (final dom in AppDomain.values) {
      if (dom.name == domainStr) {
        domain = dom;
        break;
      }
    }

    final rating = double.tryParse(yamlMap['rating']?.toString() ?? '') ?? 0.0;
    final workStatusStr = yamlMap['work_status']?.toString();
    var myStatusStr = yamlMap['my_status']?.toString() ?? yamlMap['status']?.toString();
    
    // 이전 버전 상태 또는 구버전 라벨 호환 처리
    if (myStatusStr == '아직 안 봄' || myStatusStr == '할 예정(백로그)') {
      myStatusStr = '볼 예정';
    }
    
    final isHallOfFame = yamlMap['is_hall_of_fame'] == true || yamlMap['is_hall_of_fame']?.toString() == 'true';
    
    List<String> tags = [];
    if (yamlMap['tags'] is List) {
      tags = (yamlMap['tags'] as List).map((e) => e.toString()).toList();
    } else if (yamlMap['tags'] is String) {
      tags = (yamlMap['tags'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    
    DateTime addedAt = DateTime.now();
    if (yamlMap['added_at'] != null) {
      addedAt = DateTime.tryParse(yamlMap['added_at'].toString()) ?? DateTime.now();
    }

    // 마크다운 바디 파싱 (유저 기록 파싱)
    final bodyLines = lines.sublist(bodyStartLine);
    final List<String> quotes = [];
    final reviewBuffer = StringBuffer();

    String currentSection = 'none';

    for (var line in bodyLines) {
      final trimmedLine = line.trim();
      
      // 대메뉴 제목 감지 (# )
      if (trimmedLine.startsWith('# ')) {
        final heading = trimmedLine.substring(2).toLowerCase();
        if (heading.contains('명대사') || heading.contains('명장면') || heading.contains('quote')) {
          currentSection = 'quotes';
        } else if (heading.contains('감상문') || heading.contains('review')) {
          currentSection = 'review';
        } else {
          currentSection = 'none';
        }
        continue;
      }

      // 섹션별 데이터 수집
      if (currentSection == 'review') {
        reviewBuffer.writeln(line);
      } else if (currentSection == 'quotes') {
        if (trimmedLine.startsWith('>')) {
          var quoteText = trimmedLine.substring(1).trim();
          if (quoteText.isNotEmpty) {
            quotes.add(quoteText);
          }
        } else if (trimmedLine.isNotEmpty) {
          if (!trimmedLine.startsWith('#') && !trimmedLine.startsWith('---')) {
            quotes.add(trimmedLine);
          }
        }
      }
    }

    final review = reviewBuffer.toString().trim();

    // ── UI Fusion: 공통 사전 DB 조인 ──
    String creator = yamlMap['creator']?.toString() ?? '';
    int? releaseYear = int.tryParse(yamlMap['release_year']?.toString() ?? '');
    String? posterPath = yamlMap['poster']?.toString();
    String description = '';

    RegistryWork? registryWork;
    if (workId.isNotEmpty) {
      registryWork = WorksRegistry.getWorkById(workId);
    } else if (title.isNotEmpty) {
      // 제목이 완전히 일치하는 사전 항목이 있는지 탐색 (공백/대소문자 무시)
      final matchedWorks = WorksRegistry.search(title);
      final exactMatch = matchedWorks.where((w) => w.title.replaceAll(' ', '').toLowerCase() == title.replaceAll(' ', '').toLowerCase());
      if (exactMatch.isNotEmpty) {
        registryWork = exactMatch.first;
        // 객체에도 workId를 바인딩하여 저장 시 반영되도록 함
        workId = registryWork.workId;
      }
    }

    if (registryWork != null) {
      // 공통 정보는 사전 DB에서 가져와 융합시킵니다.
      domain = registryWork.domain;
      creator = registryWork.creator;
      releaseYear = registryWork.releaseYear;
      posterPath = registryWork.posterPath ?? posterPath;
      description = registryWork.description;
      // 유저가 설정한 태그 외에 사전의 공통 장르 태그도 함께 노출되도록 머지합니다.
      for (final tag in registryWork.tags) {
        if (!tags.contains(tag)) {
          tags.add(tag);
        }
      }
    }

    final item = createItem(
      workId: workId,
      title: title,
      category: category,
      domain: domain,
      workStatus: workStatusStr,
      myStatus: myStatusStr,
      creator: creator,
      releaseYear: releaseYear,
      rating: rating,
      posterPath: posterPath,
      description: description,
      memorableQuotes: quotes,
      review: review,
      isHallOfFame: isHallOfFame,
      tags: tags,
    );
    item.addedAt = addedAt;
    return item;
  }
}
