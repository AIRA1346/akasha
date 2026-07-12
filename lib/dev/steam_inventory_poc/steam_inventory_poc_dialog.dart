import 'package:flutter/material.dart';

import 'steam_inventory_poc.dart';

/// Hidden harness — never a store UI. Debug, or Release with
/// `AKASHA_STEAM_INVENTORY_POC=true`.
Future<void> showSteamInventoryPocDialog(BuildContext context) async {
  if (!isSteamInventoryPocEnabled) return;

  final controller = await createSteamInventoryPocController();
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => _SteamInventoryPocDialog(controller: controller),
  );
  await controller.client.dispose();
}

class _SteamInventoryPocDialog extends StatefulWidget {
  const _SteamInventoryPocDialog({required this.controller});
  final SteamInventoryPocController controller;

  @override
  State<_SteamInventoryPocDialog> createState() =>
      _SteamInventoryPocDialogState();
}

class _SteamInventoryPocDialogState extends State<_SteamInventoryPocDialog> {
  String _log = '';
  Map<String, Object?> _diag = const {};
  bool _uiBusy = false;

  SteamInventoryPocController get c => widget.controller;

  bool get _actionsLocked => _uiBusy || c.isMutationPending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDiag());
  }

  void _append(String line) {
    if (!isSteamInventoryPocVerboseLog) return;
    setState(() => _log = '$_log\n$line');
  }

  Future<void> _runBusy(Future<void> Function() body) async {
    if (_actionsLocked) return;
    setState(() => _uiBusy = true);
    try {
      await body();
    } finally {
      if (mounted) setState(() => _uiBusy = false);
    }
  }

  Future<void> _refreshDiag() async {
    final client = c.client;
    if (client is! ChannelSteamInventoryClient) {
      setState(() => _diag = const {'client': 'fake'});
      return;
    }
    final d = await client.diagnostic();
    setState(() => _diag = d);
    _append(
      'diag overlay=${d['overlayEnabled']} loggedOn=${d['loggedOn']} '
      'subscribed=${d['subscribedApp'] ?? d['subscribed']} '
      'build=${d['buildMode']}',
    );
  }

  Future<void> _pump() async {
    final ops = await c.pump();
    setState(() {});
    for (final op in ops) {
      _append('${op.kind.name}: ${op.status.name} ${op.detail ?? ''}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = c.client is ChannelSteamInventoryClient;
    final showReset = isSteamInventoryPocDevResetEnabled;
    return AlertDialog(
      title: const Text('Steam Inventory POC (debug)'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                live
                    ? 'Client: native MethodChannel (process_startup Init)'
                    : 'Client: FakeSteamInventoryClient (not live Steamworks)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'overlayEnabled=${_diag['overlayEnabled']}  '
                'needsPresent=${_diag['overlayNeedsPresent']}  '
                'forceRedraw=${_diag['overlayForceRedrawCount']}\n'
                'timerTicks=${_diag['steamTimerTickCount']}  '
                'needsPresentTrue=${_diag['overlayNeedsPresentTrueCount']}\n'
                'loggedOn=${_diag['loggedOn']}  '
                'subscribed=${_diag['subscribedApp'] ?? _diag['subscribed']}\n'
                'steamId=${_diag['steamId']}  appId=${_diag['appId']}\n'
                'exe=${_diag['executablePath']}\n'
                'cwd=${_diag['currentWorkingDirectory']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                c.hasConfirmedInventory
                    ? 'Astra=${c.astra}  Echo=${c.echo}  '
                        'Theme Nocturne=${c.ownsNocturne}'
                    : 'Inventory NOT confirmed — balances pending re-query\n'
                        '(${c.activeOp.detail ?? c.lastSnapshot?.loadError ?? 'n/a'})',
              ),
              Text(
                'Op: ${c.activeOp.kind.name} / ${c.activeOp.status.name}'
                '${_actionsLocked ? ' (busy)' : ''}',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: _actionsLocked
                        ? null
                        : () => _runBusy(_refreshDiag),
                    child: const Text('Diagnostic'),
                  ),
                  FilledButton(
                    onPressed: _actionsLocked
                        ? null
                        : () => _runBusy(() async {
                              await c.refreshInventory();
                              setState(() {});
                              _append(
                                'GetAllItems failed=${c.lastSnapshot?.loadFailed} '
                                '${c.formatInventoryAudit()}',
                              );
                            }),
                    child: const Text('GetAllItems'),
                  ),
                  FilledButton(
                    onPressed: _actionsLocked
                        ? null
                        : () => _runBusy(() async {
                              await c.refreshPrices();
                              setState(() {});
                              _append('prices=${c.prices.length}');
                            }),
                    child: const Text('RequestPrices'),
                  ),
                  FilledButton(
                    onPressed: _actionsLocked
                        ? null
                        : () => _runBusy(() async {
                              final h = await c.buyAstraPack100();
                              _append('purchase handle=$h');
                              await Future<void>.delayed(
                                const Duration(milliseconds: 800),
                              );
                              await _pump();
                            }),
                    child: const Text('StartPurchase Astra100'),
                  ),
                  FilledButton(
                    onPressed: (_actionsLocked ||
                            !c.hasConfirmedInventory ||
                            c.ownsNocturne)
                        ? null
                        : () => _runBusy(() async {
                              _append(
                                'pre-exchange ${c.formatInventoryAudit()}',
                              );
                              final h = await c.unlockNocturneTheme(
                                preferAstra: true,
                              );
                              _append(
                                'exchange handle=$h detail=${c.activeOp.detail}',
                              );
                              await _pump();
                              _append(
                                'post-exchange ${c.formatInventoryAudit()}',
                              );
                            }),
                    child: Text(
                      !c.hasConfirmedInventory
                          ? 'Theme (pending)'
                          : (c.ownsNocturne
                              ? 'Theme owned'
                              : 'Exchange → Theme'),
                    ),
                  ),
                  if (showReset)
                    FilledButton(
                      onPressed: (_actionsLocked ||
                              !c.hasConfirmedInventory ||
                              !c.ownsNocturne)
                          ? null
                          : () => _runBusy(() async {
                                final astraBefore = c.astra;
                                _append(
                                  'pre-reset Astra=$astraBefore '
                                  '${c.formatInventoryAudit()}',
                                );
                                final h = await c.consumeThemeReset();
                                _append(
                                  'consumeThemeReset handle=$h '
                                  'detail=${c.activeOp.detail}',
                                );
                                await _pump();
                                _append(
                                  'post-reset Astra=${c.astra} '
                                  '(expect $astraBefore) '
                                  'Theme=${c.ownsNocturne} '
                                  '${c.formatInventoryAudit()}',
                                );
                              }),
                      child: const Text('Consume Theme Reset'),
                    ),
                  FilledButton(
                    onPressed: _actionsLocked
                        ? null
                        : () => _runBusy(() async {
                              final h = await c.claimEchoPromo();
                              _append('promo=$h');
                              await _pump();
                            }),
                    child: const Text('AddPromoItem Echo'),
                  ),
                  FilledButton(
                    onPressed: _actionsLocked
                        ? null
                        : () => _runBusy(() async {
                              final h = await c.claimEchoPlaytimeDrop();
                              _append('drop=$h');
                              await _pump();
                            }),
                    child: const Text('TriggerItemDrop'),
                  ),
                  OutlinedButton(
                    onPressed: _actionsLocked
                        ? null
                        : () => _runBusy(_pump),
                    child: const Text('Poll callbacks'),
                  ),
                ],
              ),
              if (isSteamInventoryPocVerboseLog) ...[
                const SizedBox(height: 12),
                Text(_log, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
