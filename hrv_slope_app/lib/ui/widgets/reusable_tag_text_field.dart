library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/services/reusable_tag_service.dart';

class ReusableTagTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final List<String> options;
  final bool required;
  final int maxLines;
  final String? hintText;
  final Future<void> Function(String value)? onSaveTag;

  const ReusableTagTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.options,
    this.required = true,
    this.maxLines = 1,
    this.hintText,
    this.onSaveTag,
  });

  @override
  State<ReusableTagTextField> createState() => _ReusableTagTextFieldState();
}

class _ReusableTagTextFieldState extends State<ReusableTagTextField> {
  late final FocusNode _focusNode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ReusableTagTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSave {
    final normalized = ReusableTagService.normalizeName(widget.controller.text);
    if (normalized.isEmpty || widget.onSaveTag == null) return false;
    return !widget.options.any(
      (option) => ReusableTagService.normalizeName(option) == normalized,
    );
  }

  Future<void> _saveTag() async {
    final value = ReusableTagService.displayName(widget.controller.text);
    if (value.isEmpty || widget.onSaveTag == null) return;
    setState(() => _saving = true);
    try {
      await widget.onSaveTag!(value);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        final query = ReusableTagService.normalizeName(value.text);
        final options = widget.options;
        if (query.isEmpty) return options;
        return options.where(
          (option) => ReusableTagService.normalizeName(option).contains(query),
        );
      },
      onSelected: (selection) {
        widget.controller.text = selection;
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              maxLines: widget.maxLines,
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                suffixIcon: _canSave
                    ? IconButton(
                        tooltip: 'Save for future sessions',
                        onPressed: _saving ? null : _saveTag,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.bookmark_add_outlined),
                      )
                    : null,
              ),
              validator: widget.required
                  ? (v) => v == null || v.trim().isEmpty
                        ? '${widget.labelText} is required'
                        : null
                  : null,
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        final optionList = options.toList(growable: false);
        if (optionList.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionList.length,
                itemBuilder: (context, index) {
                  final option = optionList[index];
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
