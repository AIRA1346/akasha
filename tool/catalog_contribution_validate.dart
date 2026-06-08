// ignore_for_file: avoid_print
/// Maintainer — 카탈로그 제안 JSON 검증 (자동 shard merge 없음)
library;

import 'poster_url_policy.dart';

const validCategories = {
  'manga',
  'webtoon',
  'animation',
  'game',
  'book',
  'movie',
  'drama',
};

const validDomains = {'subculture', 'generalCulture'};

const validStatusNames = {
  'submitted',
  'ai_verified',
  'accepted',
  'rejected',
  'merged',
};

List<String> validateContributionMap(Map<String, dynamic> contribution) {
  final errors = <String>[];
  final id = contribution['id']?.toString() ?? '(no-id)';
  final kind = contribution['kind']?.toString() ?? '';
  final status = contribution['status']?.toString() ?? 'submitted';
  if (!validStatusNames.contains(status)) {
    errors.add('$id: invalid status $status');
  }

  if (kind == 'addWork') {
    final add = contribution['addWork'];
    if (add is! Map) {
      errors.add('$id: addWork missing');
      return errors;
    }
    final map = Map<String, dynamic>.from(add);
    final title = map['title']?.toString().trim() ?? '';
    if (title.isEmpty) errors.add('$id: title required');
    final category = map['category']?.toString() ?? '';
    final domain = map['domain']?.toString() ?? '';
    if (!validCategories.contains(category)) {
      errors.add('$id: invalid category $category');
    }
    if (!validDomains.contains(domain)) {
      errors.add('$id: invalid domain $domain');
    }
    final poster = map['posterPath']?.toString();
    final posterErr = validatePosterUrlForShard(
      poster != null && poster.isNotEmpty ? poster : null,
    );
    if (posterErr != null) errors.add('$id: $posterErr');
  } else if (kind == 'fixWork') {
    final fix = contribution['fixWork'];
    if (fix is! Map) {
      errors.add('$id: fixWork missing');
      return errors;
    }
    final map = Map<String, dynamic>.from(fix);
    final target = map['targetWorkId']?.toString() ?? '';
    if (target.isEmpty) errors.add('$id: targetWorkId required');
    final issue = map['issue']?.toString().trim() ?? '';
    if (issue.isEmpty) errors.add('$id: issue description required');
    final fields = map['fields'];
    if (fields is! Map || fields.isEmpty) {
      errors.add('$id: fields must be non-empty');
    } else {
      if (fields.containsKey('posterPath')) {
        final poster = fields['posterPath']?.toString();
        if (poster != null && poster.isNotEmpty) {
          final posterErr = validatePosterUrlForShard(poster);
          if (posterErr != null) errors.add('$id: $posterErr');
        }
      }
    }
  } else {
    errors.add('$id: unknown kind $kind');
  }

  return errors;
}

List<String> validateContributionBundle(Map<String, dynamic> bundle) {
  final errors = <String>[];
  final version = bundle['version'];
  if (version != 1 && version != 2) {
    errors.add('Unsupported bundle version: $version (expected 1 or 2)');
  }
  final list = bundle['contributions'];
  if (list is! List || list.isEmpty) {
    errors.add('contributions array empty');
    return errors;
  }
  for (final entry in list) {
    if (entry is! Map) continue;
    errors.addAll(
      validateContributionMap(Map<String, dynamic>.from(entry)),
    );
  }
  return errors;
}
