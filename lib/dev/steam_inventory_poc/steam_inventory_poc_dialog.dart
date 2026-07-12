import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'steam_inventory_poc.dart';

/// Hidden debug harness — never a store UI. Only in [kDebugMode].
Future<void> showSteamInventoryPocDialog(BuildContext context) async {
  if (!kDebugMode) return;

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
  State<_SteamInventoryPocDialog> createState() => _SteamInventoryPocDialogState();
}

class _SteamInventoryPocDialogState extends State<_SteamInventoryPocDialog> {
  String _log = '';

  SteamInventoryPocController get c => widget.controller;

  void _append(String line) => setState(() => _log = '$_log\n$line');

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
    return AlertDialog(
      title: const Text('Steam Inventory POC (debug)'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                live
                    ? 'Client: native MethodChannel (requires SteamAPI_Init)'
                    : 'Client: FakeSteamInventoryClient (not live Steamworks)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                c.hasConfirmedInventory
                    ? 'Astra=${c.astra}  Echo=${c.echo}  '
                        'Theme Nocturne=${c.ownsNocturne}'
                    : 'Inventory NOT confirmed — no local balance invention '
                        '(${c.lastSnapshot?.loadError ?? 'n/a'})',
              ),
              Text('Op: ${c.activeOp.kind.name} / ${c.activeOp.status.name}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () async {
                      await c.refreshInventory();
                      setState(() {});
                      _append('refresh done failed=${c.lastSnapshot?.loadFailed}');
                    },
                    child: const Text('GetAllItems'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await c.refreshPrices();
                      setState(() {});
                      _append('prices=${c.prices.length}');
                    },
                    child: const Text('RequestPrices'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final h = await c.buyAstraPack100();
                      _append('purchase handle=$h');
                      await _pump();
                    },
                    child: const Text('StartPurchase Astra100'),
                  ),
                  FilledButton(
                    onPressed: c.ownsNocturne
                        ? null
                        : () async {
                            final h =
                                await c.unlockNocturneTheme(preferAstra: true);
                            _append('exchange handle=$h');
                            await _pump();
                          },
                    child: Text(
                      c.ownsNocturne ? 'Theme owned' : 'Exchange → Theme',
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final h = await c.claimEchoPromo();
                      _append('promo=$h');
                      await _pump();
                    },
                    child: const Text('AddPromoItem Echo'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final h = await c.claimEchoPlaytimeDrop();
                      _append('drop=$h');
                      await _pump();
                    },
                    child: const Text('TriggerItemDrop'),
                  ),
                  OutlinedButton(
                    onPressed: _pump,
                    child: const Text('Poll callbacks'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_log, style: Theme.of(context).textTheme.bodySmall),
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
