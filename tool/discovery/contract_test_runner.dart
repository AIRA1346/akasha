/// Discovery Contract Test Runner — Source → Facts → Signal Gate → Minimal Core.
///
/// Raw JSON·candidate·Registry 쓰기 금지. KPI만 반환.
library;

import 'dart:io';

import 'anilist_facts.dart';
import 'discovery_contract_kpi.dart';
import 'discovery_source_fetch.dart';
import 'discovery_types.dart';
import 'registry_dedupe_index.dart';
import 'signal_gate.dart';
import 'wikidata_facts.dart';
import 'wikidata_q_validation.dart';

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
  final Set<String> registryExternalIds;

  const ContractTestRunner({
    required this.channelId,
    required this.config,
    required this.registryExternalIds,
  });

  factory ContractTestRunner.fromProject({
    required String channelId,
    required DiscoveryChannelConfig config,
    required Directory projectRoot,
  }) {
    final externalSource =
        config.source == 'wikidata_ko' ? 'wikidata' : config.source;
    return ContractTestRunner(
      channelId: channelId,
      config: config,
      registryExternalIds:
          loadRegistryExternalIds(projectRoot, externalSource),
    );
  }

  /// Fetch 없이 노드 목록으로 계약 검증 (CI·오프라인).
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

  /// HTTP fetch → in-memory pipeline. 디스크 쓰기 없음.
  Future<DiscoveryContractKpi> runLive({
    int? batchSize,
    Directory? projectRoot,
    HttpClient? httpClient,
    Future<List<Map<String, dynamic>>> Function({
      required DiscoveryChannelConfig config,
      Directory? projectRoot,
      int? offset,
      HttpClient? client,
    })? fetchBatch,
  }) async {
    final size = batchSize ?? config.trialBatchSize;
    final sizedConfig = DiscoveryChannelConfig(
      id: config.id,
      source: config.source,
      category: config.category,
      domain: config.domain,
      enabled: config.enabled,
      dailyLimit: config.dailyLimit,
      trialBatchSize: size,
      cursorPath: config.cursorPath,
    );
    final fetcher = fetchBatch ?? fetchDiscoveryBatch;
    final nodes = await fetcher(
      config: sizedConfig,
      projectRoot: projectRoot,
      client: httpClient,
    );
    return runOnNodes(nodes);
  }

  ContractNodeOutcome processNode(Map<String, dynamic> node) {
    return classifyNode(node).outcome;
  }

  ContractNodeRecord classifyNode(Map<String, dynamic> node) {
    if (config.source == 'anilist') {
      return const ContractNodeRecord(
        outcome: ContractNodeOutcome.policyRejected,
        externalId: '',
      );
    }
    if (config.source == 'wikidata' || config.source == 'wikidata_ko') {
      return _classifyWikidata(node);
    }
    return ContractNodeRecord(
      outcome: ContractNodeOutcome.policyRejected,
      externalId: node['qid']?.toString() ?? node['id']?.toString() ?? '',
    );
  }

  ContractNodeRecord _classifyWikidata(Map<String, dynamic> node) {
    final qid = node['qid']?.toString().trim() ?? '';
    final nodeCategory = node['category']?.toString() ?? config.category;

    if (nodeCategory != config.category) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.policyRejected,
        externalId: qid,
      );
    }

    if (config.source == 'wikidata_ko') {
      final titlesRaw = node['titles'];
      final ko = titlesRaw is Map
          ? titlesRaw['ko']?.toString().trim() ?? ''
          : '';
      if (ko.isEmpty) {
        return ContractNodeRecord(
          outcome: ContractNodeOutcome.policyRejected,
          externalId: qid,
          title: node['title']?.toString() ?? '',
        );
      }
    }

    final p31Raw = node['entityP31'];
    final p31Set = p31Raw is List
        ? p31Raw.map((e) => e.toString()).toSet()
        : (p31Raw?.toString().trim().isNotEmpty == true
            ? {p31Raw.toString()}
            : null);

    // V4 (registry duplicate Q)는 아래 dedupeCandidate 분기에서 처리 — 여기서 BLOCK 하지 않음
    final qValidation = validateWikidataQidForIngest(
      qid: qid,
      category: config.category,
      title: node['title']?.toString() ?? '',
      entityP31Qids: p31Set,
      entityEnLabel: node['entityEnLabel']?.toString(),
    );
    if (qValidation.verdict == WikidataQValidationVerdict.block) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.policyRejected,
        externalId: qid,
        title: node['title']?.toString() ?? '',
      );
    }

    final facts = extractWikidataFacts(node);
    final factsJson = facts.toJson();
    if (findForbiddenKeysInMap(factsJson).isNotEmpty) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.policyRejected,
        externalId: qid,
      );
    }

    if (facts.title.isEmpty) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.missingTitle,
        externalId: qid,
      );
    }

    final hasYear = facts.releaseYear != null;
    final hasExternal = qid.isNotEmpty;
    if (!hasYear && !hasExternal) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.missingYearOrExternalId,
        externalId: qid,
        title: facts.title,
      );
    }

    try {
      final signal = wikidataNodeToSignal(
        channelId: channelId,
        node: node,
        domain: config.domain,
      );

      final gateErrors = validateDiscoverySignal(signal);
      if (gateErrors.isNotEmpty) {
        return ContractNodeRecord(
          outcome: ContractNodeOutcome.policyRejected,
          externalId: qid,
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
          externalId: qid,
          title: facts.title,
        );
      }

      final outcome = registryExternalIds.contains(qid)
          ? ContractNodeOutcome.dedupeCandidate
          : ContractNodeOutcome.minimalCoreDraft;

      return ContractNodeRecord(
        outcome: outcome,
        externalId: qid,
        title: facts.title,
        draft: draft,
        signal: signal,
      );
    } catch (_) {
      return ContractNodeRecord(
        outcome: ContractNodeOutcome.policyRejected,
        externalId: qid,
      );
    }
  }

  DiscoverySignal buildSignal(Map<String, dynamic> node) {
    final record = classifyNode(node);
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
