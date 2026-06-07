import 'package:flutter/material.dart';
import '../services/user_registry_preferences.dart';
import '../services/works_registry.dart';

/// 숨긴 사전 항목 목록 조회·복원 다이얼로그
Future<void> showHiddenRegistryDialog(
  BuildContext context, {
  VoidCallback? onChanged,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _HiddenRegistryDialog(onChanged: onChanged),
  );
}

class _HiddenRegistryDialog extends StatefulWidget {
  final VoidCallback? onChanged;

  const _HiddenRegistryDialog({this.onChanged});

  @override
  State<_HiddenRegistryDialog> createState() => _HiddenRegistryDialogState();
}

class _HiddenRegistryDialogState extends State<_HiddenRegistryDialog> {
  late List<String> _hiddenIds;

  @override
  void initState() {
    super.initState();
    _hiddenIds = UserRegistryPreferences.instance.hiddenWorkIds.toList()
      ..sort();
  }

  Future<void> _unhide(String workId) async {
    await UserRegistryPreferences.instance.unhideWork(workId);
    setState(() {
      _hiddenIds = UserRegistryPreferences.instance.hiddenWorkIds.toList()
        ..sort();
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('숨긴 사전 항목'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: _hiddenIds.isEmpty
            ? Center(
                child: Text(
                  '숨긴 사전 항목이 없습니다.\n'
                  '가상 카드를 길게 눌러 숨길 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              )
            : ListView.separated(
                itemCount: _hiddenIds.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final workId = _hiddenIds[i];
                  final work = WorksRegistry.getWorkById(workId);
                  final title = work?.title ?? workId;
                  final category = work?.category;

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      category?.icon ?? Icons.visibility_off_outlined,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                    title: Text(title, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      category != null
                          ? '${category.label} · $workId'
                          : workId,
                      style: const TextStyle(fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: TextButton(
                      onPressed: () => _unhide(workId),
                      child: const Text('복원'),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
