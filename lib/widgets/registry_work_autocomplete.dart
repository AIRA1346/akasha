import 'dart:async';
import 'package:flutter/material.dart';
import '../services/works_registry.dart';

/// debounce + searchAsync 기반 작품 사전 Autocomplete
class RegistryWorkAutocomplete extends StatefulWidget {
  final RegistryWork? selectedWork;
  final ValueChanged<RegistryWork?> onSelected;
  final VoidCallback? onCleared;

  const RegistryWorkAutocomplete({
    super.key,
    this.selectedWork,
    required this.onSelected,
    this.onCleared,
  });

  @override
  State<RegistryWorkAutocomplete> createState() =>
      _RegistryWorkAutocompleteState();
}

class _RegistryWorkAutocompleteState extends State<RegistryWorkAutocomplete> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<RegistryWork> _options = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedWork != null) {
      _ctrl.text = widget.selectedWork!.title;
    }
  }

  @override
  void didUpdateWidget(RegistryWorkAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedWork == null && oldWidget.selectedWork != null) {
      _ctrl.clear();
      _options = [];
    } else if (widget.selectedWork != null &&
        widget.selectedWork != oldWidget.selectedWork) {
      _ctrl.text = widget.selectedWork!.title;
      _options = [];
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _options = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await WorksRegistry.searchAsync(trimmed);
        if (!mounted) return;
        setState(() {
          _options = results;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _options = [];
          _isSearching = false;
        });
      }
    });
  }

  void _clearSelection() {
    _ctrl.clear();
    setState(() => _options = []);
    widget.onCleared?.call();
    widget.onSelected(null);
  }

  void _pick(RegistryWork work) {
    _ctrl.text = work.title;
    setState(() => _options = []);
    _focusNode.unfocus();
    widget.onSelected(work);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '사전에서 작품을 검색하여 선택해 보세요...',
            border: const OutlineInputBorder(),
            isDense: true,
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: widget.selectedWork != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: _clearSelection,
                  )
                : _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
          ),
          onChanged: _onQueryChanged,
        ),
        if (_options.isNotEmpty && widget.selectedWork == null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 140),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _options.length,
              itemBuilder: (_, i) {
                final work = _options[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    work.title,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    work.category.label,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => _pick(work),
                );
              },
            ),
          ),
      ],
    );
  }
}
