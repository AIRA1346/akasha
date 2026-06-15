import 'package:flutter/material.dart';

/// 태그를 칩 단위로 표시·추가·삭제 (워크벤치 작품정보 등)
class EditableTagChips extends StatefulWidget {
  const EditableTagChips({
    super.key,
    required this.tags,
    required this.onChanged,
    this.registryTags = const {},
    this.compact = true,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  /// 글로벌 사전에서 온 태그 — 스타일만 구분 (삭제는 허용, 저장 시 .md에만 반영)
  final Set<String> registryTags;
  final bool compact;

  @override
  State<EditableTagChips> createState() => _EditableTagChipsState();
}

class _EditableTagChipsState extends State<EditableTagChips> {
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  void _updateTags(List<String> next) {
    widget.onChanged(next);
  }

  void _removeTag(String tag) {
    _updateTags(widget.tags.where((t) => t != tag).toList());
  }

  void _addTagsFromRaw(String raw) {
    final incoming = raw
        .split(RegExp(r'[,，]'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty);
    final next = List<String>.from(widget.tags);
    for (final tag in incoming) {
      if (!next.contains(tag)) next.add(tag);
    }
    if (next.length != widget.tags.length) {
      _updateTags(next);
    }
    _addCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.compact ? 11.0 : 12.0;
    final chipHeight = widget.compact ? 26.0 : 32.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in widget.tags)
                Tooltip(
                  message: widget.registryTags.contains(tag)
                      ? '글로벌 사전 태그'
                      : '내 태그',
                  child: _TagChip(
                    label: tag,
                    fromRegistry: widget.registryTags.contains(tag),
                    height: chipHeight,
                    fontSize: fontSize,
                    onDeleted: () => _removeTag(tag),
                  ),
                ),
            ],
          ),
        SizedBox(height: widget.tags.isEmpty ? 0 : 6),
        TextField(
          controller: _addCtrl,
          style: TextStyle(fontSize: fontSize),
          decoration: InputDecoration(
            hintText: widget.tags.isEmpty ? '태그 추가 (쉼표 또는 Enter)' : '태그 추가',
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: widget.compact ? 6 : 8,
            ),
          ),
          onSubmitted: _addTagsFromRaw,
          onEditingComplete: () => _addTagsFromRaw(_addCtrl.text),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.fromRegistry,
    required this.height,
    required this.fontSize,
    required this.onDeleted,
  });

  final String label;
  final bool fromRegistry;
  final double height;
  final double fontSize;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = fromRegistry
        ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
        : cs.primaryContainer.withValues(alpha: 0.35);
    final side = fromRegistry
        ? BorderSide(color: cs.outline.withValues(alpha: 0.35))
        : BorderSide.none;

    return InputChip(
      label: Text(
        label,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
      deleteIcon: Icon(Icons.close, size: fontSize + 2),
      onDeleted: onDeleted,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      backgroundColor: bg,
      side: side,
    );
  }
}

/// 쉼표·중복 제거 파싱 (테스트·저장 공용)
List<String> parseTagList(Iterable<String> rawTags) {
  final out = <String>[];
  for (final raw in rawTags) {
    for (final part in raw.split(RegExp(r'[,，]'))) {
      final t = part.trim();
      if (t.isNotEmpty && !out.contains(t)) out.add(t);
    }
  }
  return out;
}
