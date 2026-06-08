/// Discovery Contract Test Runner — AniList → Facts → Signal Gate → Minimal Core.
///
/// Raw JSON·candidate·Registry 쓰기 금지. KPI만 반환.
library;

import 'dart:io';

import 'anilist_client.dart';
import 'anilist_facts.dart';
import 'discovery_contract_kpi.dart';
import 'discovery_types.dart';
import 'registry_dedupe_index.dart';
import 'signal_gate.dart';

const contractDraftWorkId = 'wk_CONTRACT_DRAFT';

/// 단일 노드 처리 결과 (KPI 분류용)
enum ContractNodeOutcome {
  minimalCoreDraft,
  dedupeCandidate,
  policyRejected,
  missingTitle,
  missingYearOrExternalId,
}

class ContractTestRunner {
  final String channelId;
  final DiscoveryChannelConfig config;
  final Set<String> registryAnilistIds;

  const ContractTestRunner({
    required this.channelId,
    required this.config,
    required this.registryAnilistIds,
  });

  factory ContractTestRunner.fromProject({
    required String channelId,
    required DiscoveryChannelConfig config,
    required Directory projectRoot,
  }) {
    return ContractTestRunner(
      channelId: channelId,
      config: config,
      registryAnilistIds: loadRegistryAnilistIds(projectRoot),
    );
  }

  /// GraphQL fetch 없이 노드 목록으로 계약 검증 (CI·오프라인).
  DiscoveryContractKpi runOnNodes(List<Map<String, dynamic>> nodes) {
    var policyRejected = 0;
    var dedupeCandidates = 0;
    var minimalCoreDrafts = 0;
    var missingTitle = 0;
    var missingYearOrExternalId = 0;

    for (final node in nodes) {
      switch (processNode(node)) {
        case ContractNodeOutcome.minimalCoreDraft:
          minimalCoreDrafts++;
        case ContractNodeOutcome.dedupeCandidate:
          dedupeCandidates++;
        case ContractNodeOutcome.policyRejected:
          policyRejected++;
        case ContractNodeOutcome.missingTitle:
          missingTitle++;
        case ContractNodeOutcome.missingYearOrExternalId:
          missingYearOrExternalId++;
      }
    }

    return DiscoveryContractKpi(
      fetched: nodes.length,
      policyRejected: policyRejected,
      dedupeCandidates: dedupeCandidates,
      minimalCoreDrafts: minimalCoreDrafts,
      missingTitle: missingTitle,
      missingYearOrExternalId: missingYearOrExternalId,
    );
  }

  /// AniList HTTP → in-memory pipeline. 디스크 쓰기 없음.
  Future<DiscoveryContractKpi> runLive({
    int? batchSize,
    HttpClient? httpClient,
    Future<List<Map<String, dynamic>>> Function({
      required int batchSize,
      String requiredCategory,
      HttpClient? client,
    })? fetchBatch,
  }) async {
    final size = batchSize ?? config.trialBatchSize;
    final fetcher = fetchBatch ?? fetchAnilistAnimationBatch;
    final nodes = await fetcher(
      batchSize: size,
      requiredCategory: config.category,
      client: httpClient,
    );
    return runOnNodes(nodes);
  }

  ContractNodeOutcome processNode(Map<String, dynamic> media) {
    return classifyNode(media).outcome;
  }

  ContractNodeRecord classifyNode(Map<String, dynamic> media) {
    final externalId = media['id']?.toString().trim() ?? '';
    final format = media['format']?.toString();
    final category = anilistFormatToCategory(format);

    if (category != config.category) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.policyRejected,
        externalId: externalId,
      );
    }

    final facts = extractAnilistFacts(media);
    final factsJson = facts.toJson();
    if (findForbiddenKeysInMap(factsJson).isNotEmpty) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.policyRejected,
        externalId: externalId,
      );
    }

    if (facts.title.isEmpty) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.missingTitle,
        externalId: externalId,
      );
    }

    final hasYear = facts.releaseYear != null;
    final hasExternal = externalId.isNotEmpty;
    if (!hasYear && !hasExternal) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.missingYearOrExternalId,
        externalId: externalId,
        title: facts.title,
      );
    }

    try {
      final signal = DiscoverySignal(
        channelId: channelId,
        source: 'anilist',
        externalId: externalId,
        category: category!,
        domain: config.domain,
        facts: facts,
        discoveredAt: DateTime.now().toUtc(),
      );

      final gateErrors = validateDiscoverySignal(signal);
      if (gateErrors.isNotEmpty) {
        return ContractNodeRecord(
          outcome: ContractNodeOutcome.policyRejected,
          externalId: externalId,
          title: facts.title,
        );
      }

      final draft = signalToMinimalCoreDraft(
        signal: signal,
        workId: contractDraftWorkId,
      );
      if (findForbiddenKeysInMap(draft).isNotEmpty) {
        return ContractNodeRecord(
          outcome: ContractNodeOutcome.policyRejected,
          externalId: externalId,
          title: facts.title,
        );
      }

      final outcome = registryAnilistIds.contains(externalId)
          ? ContractNodeOutcome.dedupeCandidate
          : ContractNodeOutcome.minimalCoreDraft;

      return ContractNodeRecord(
        outcome: outcome,
        externalId: externalId,
        title: facts.title,
        draft: draft,
        signal: signal,
      );
    } catch (_) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.policyRejected,
        externalId: externalId,
      );
    }
  }

  DiscoverySignal buildSignal(Map<String, dynamic> media) {
    final record = classifyNode(media);
    if (record.signal == null) {
      throw StateError('cannot build signal: ${record.outcome.name}');
    }
    return record.signal!;
  }
}

class ContractNodeRecord {
  final ContractNodeOutcome outcome;
  final String externalId;
  final String title;
  final Map<String, dynamic>? draft;
  final DiscoverySignal? signal;

  const ContractNodeRecord({
    required this.outcome,
    required this.externalId,
    this.title = '',
    this.draft,
    this.signal,
  });
}
