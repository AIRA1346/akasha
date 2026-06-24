import 'package:yaml/yaml.dart';
import '../core/archiving/entity_frontmatter.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../models/work_id_codec.dart';
import '../utils/helpers.dart';
import 'markdown_body_merger.dart';
import 'works_registry.dart';

class MarkdownParser {
  /// work_id가 비어 있거나 레거시일 때 사전 매칭 → 마스터 ID 생성
  static String ensureWorkId(AkashaItem item) {
    final resolved = WorksRegistry.resolveWorkId(item.workId);
    if (resolved.isNotEmpty && WorkIdCodec.isMasterFormat(resolved)) {
      return resolved;
    }

    if (item.title.trim().isNotEmpty) {
      final q = item.title.trim().toLowerCase().replaceAll(' ', '');
      final hits = WorksRegistry.search(item.title).where((w) {
        final t = w.title.toLowerCase().replaceAll(' ', '');
        return t == q && w.category == item.category;
      });
      if (hits.isNotEmpty) return hits.first.workId;
    }

    return WorkIdCodec.buildUserLocal();
  }

  /// YAML `poster:` 필드에 저장할지 판별합니다.
  ///
  /// - `posters/` 상대 경로 (사용자 업로드): 저장
  /// - Registry 기본 CDN URL: 저장 금지 (런타임 UI Fusion 전용)
  /// - 사용자가 스마트 이미지 교정 등으로 지정한 커스텀 URL: 저장
  static bool shouldPersistPosterToYaml(AkashaItem item) {
    final path = item.posterPath;
    if (path == null || path.isEmpty) return false;

    final normalized = path.replaceAll('\\', '/');
    if (normalized.startsWith('posters/')) return true;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      final resolvedId = WorksRegistry.resolveWorkId(item.workId);
      if (resolvedId.isNotEmpty) {
        final registryPoster = WorksRegistry.resolvePosterPath(resolvedId);
        if (registryPoster != null && registryPoster == path) {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  /// AkashaItem을 마크다운 파일 내용(YAML Front-matter + Markdown Body)으로 직렬화합니다.
  /// Registry 기본 CDN 포스터는 YAML에 저장하지 않으며, `posters/` 상대경로 또는
  /// 사용자가 명시적으로 지정한 커스텀 URL만 `poster:` 필드에 기록합니다.
  static String serialize(AkashaItem item) {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('work_id: "${item.workId}"');
    if (item.workId.isNotEmpty) {
      final entityFields = EntityFrontmatter.forWorkItem(
        workId: item.workId,
        category: item.category,
      ).toLazyWriteFields();
      for (final entry in entityFields.entries) {
        if (entry.key == 'entity_id') {
          buffer.writeln('${entry.key}: "${entry.value.replaceAll('"', '\\"')}"');
        } else {
          buffer.writeln('${entry.key}: ${entry.value}');
        }
      }
    }
    buffer.writeln('title: "${item.title.replaceAll('"', '\\"')}"'); // YAML title (외부 편집기 호환)
    buffer.writeln('category: ${item.category.name}');
    buffer.writeln('domain: ${item.domain.name}');
    buffer.writeln('# poster: "https://..." 또는 "posters/파일명.jpg"');
    if (shouldPersistPosterToYaml(item)) {
      buffer.writeln('poster: "${item.posterPath!.replaceAll('"', '\\"')}"');
    } else {
      buffer.writeln('poster: ""');
    }
    buffer.writeln('rating: ${item.rating}');
    
    // 작품 상태 및 나의 상태 저장 (Sanctum vault 호환성 극대화)
    buffer.writeln('work_status: "${item.workStatusLabel}"');
    buffer.writeln('status: "${item.myStatusLabel}"');
    buffer.writeln('my_status: "${item.myStatusLabel}"');
    buffer.writeln('is_hall_of_fame: ${item.isHallOfFame}');
    
    if (item.creator.isNotEmpty) {
      buffer.writeln('creator: "${item.creator.replaceAll('"', '\\"')}"');
    }
    if (item.releaseYear != null) {
      buffer.writeln('release_year: ${item.releaseYear}');
    }
    
    if (item.tags.isNotEmpty) {
      buffer.writeln('tags: [${item.tags.map((t) => '"${t.replaceAll('"', '\\"')}"').join(', ')}]');
    } else {
      buffer.writeln('tags: []');
    }
    
    buffer.writeln('added_at: "${item.addedAt.toIso8601String()}"');
    buffer.writeln('---');
    buffer.writeln();

    final bodyToWrite = item.bodyRaw.trim().isNotEmpty
        ? item.bodyRaw
        : MarkdownBodyMerger.mergeBody(
            bodyRaw: '',
            synopsis: item.description,
            quotes: item.memorableQuotes,
            memo: item.review,
          );
    if (bodyToWrite.isNotEmpty) {
      buffer.write(bodyToWrite);
    }

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
          'entity_id': regExtract('entity_id', yamlStr),
          'entity_type': regExtract('entity_type', yamlStr),
          'subtype': regExtract('subtype', yamlStr),
          'record_kind': regExtract('record_kind', yamlStr),
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
    MediaCategory category = MediaCategory.manga;
    for (final cat in MediaCategory.values) {
      if (cat.name == (yamlMap['category']?.toString() ?? 'manga')) {
        category = cat;
        break;
      }
    }

    final entityMeta = EntityFrontmatter.inferFromYaml(
      yamlMap,
      categoryFallback: category,
    );
    category = entityMeta.subtype;

    String workId = WorksRegistry.resolveWorkId(entityMeta.resolvedWorkId);
    if (workId.isEmpty && yamlMap['work_id'] != null) {
      workId = WorksRegistry.resolveWorkId(yamlMap['work_id']?.toString() ?? '');
    }

    final title = yamlMap['title']?.toString() ?? fallbackTitle;

    AppDomain domain = AppDomain.fromStorage(yamlMap['domain']?.toString());

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

    // 마크다운 바디 — 원문 보존 + 슬롯 필드 추출
    final bodyRaw =
        lines.sublist(bodyStartLine).join('\n').replaceFirst(RegExp(r'^\n+'), '');
    final slots = MarkdownBodyMerger.parseSlots(bodyRaw);
    final quotes = slots.quotes;
    final userSynopsis = slots.synopsis;
    final review = slots.memo;

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
      // 공통 정보는 사전 DB에서 가져오되, 사용자 정의 값(YAML)이 있으면 그것을 최우선으로 적용합니다.
      domain = registryWork.domain;
      creator = creator.isNotEmpty ? creator : registryWork.creator;
      releaseYear = releaseYear ?? registryWork.releaseYear;
      posterPath = (posterPath != null && posterPath.isNotEmpty)
          ? posterPath
          : null;
      description = registryWork.description;
      // 유저가 설정한 태그 외에 사전의 공통 장르 태그도 함께 노출되도록 머지합니다.
      for (final tag in registryWork.tags) {
        if (!tags.contains(tag)) {
          tags.add(tag);
        }
      }
    }

    if (userSynopsis.isNotEmpty) {
      description = userSynopsis;
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
    item.bodyRaw = bodyRaw;
    if (workId.isEmpty || !WorkIdCodec.isMasterFormat(workId)) {
      item.workId = ensureWorkId(item);
    }
    return item;
  }
}
