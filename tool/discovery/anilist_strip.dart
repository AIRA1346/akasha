/// AniList 출처·참조 제거 — Independence Test용.
library;

/// `externalIds.anilist` 및 AniList ingest 메타 제거.
Map<String, dynamic> stripAnilistFromDraft(Map<String, dynamic> draft) {
  final copy = Map<String, dynamic>.from(draft);

  final ext = copy['externalIds'];
  if (ext is Map) {
    final e = Map<String, dynamic>.from(ext);
    e.remove('anilist');
    if (e.isEmpty) {
      copy.remove('externalIds');
    } else {
      copy['externalIds'] = e;
    }
  }

  final extensions = copy['extensions'];
  if (extensions is Map) {
    final x = Map<String, dynamic>.from(extensions);
    for (final key in [
      'anilist',
      'anilistId',
      'ingestSource',
      'ingestChannel',
      'seedSource',
    ]) {
      x.remove(key);
    }
    if (x.isEmpty) {
      copy.remove('extensions');
    } else {
      copy['extensions'] = x;
    }
  }

  return copy;
}

bool draftHasAnilistReference(Map<String, dynamic> draft) {
  final ext = draft['externalIds'];
  if (ext is Map && ext['anilist']?.toString().trim().isNotEmpty == true) {
    return true;
  }
  final extensions = draft['extensions'];
  if (extensions is Map) {
    for (final key in ['anilist', 'anilistId', 'ingestChannel']) {
      if (extensions[key]?.toString().trim().isNotEmpty == true) return true;
    }
  }
  return false;
}
