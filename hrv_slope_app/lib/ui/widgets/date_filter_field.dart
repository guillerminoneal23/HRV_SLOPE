library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFilterField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<String?>? onChanged;

  const DateFilterField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText = 'YYYY-MM-DD',
    this.firstDate,
    this.lastDate,
    this.onChanged,
  });

  @override
  State<DateFilterField> createState() => _DateFilterFieldState();
}

class _DateFilterFieldState extends State<DateFilterField> {
  static final _formatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_controllerChanged);
  }

  @override
  void didUpdateWidget(DateFilterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_controllerChanged);
    widget.controller.addListener(_controllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerChanged);
    super.dispose();
  }

  void _controllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = widget.firstDate ?? DateTime(2000);
    final lastDate = widget.lastDate ?? DateTime(2100);
    final parsed = DateTime.tryParse(widget.controller.text.trim());
    final initialDate = _clampDate(parsed ?? now, firstDate, lastDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    widget.controller.text = _formatter.format(picked);
    widget.onChanged?.call(widget.controller.text);
  }

  void _clearDate() {
    widget.controller.clear();
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = widget.controller.text.trim().isNotEmpty;
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Pick date',
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
            ),
            if (hasDate)
              IconButton(
                tooltip: 'Clear date',
                onPressed: _clearDate,
                icon: const Icon(Icons.clear),
              ),
          ],
        ),
      ),
      onTap: _pickDate,
    );
  }
}

DateTime _clampDate(DateTime value, DateTime firstDate, DateTime lastDate) {
  if (value.isBefore(firstDate)) return firstDate;
  if (value.isAfter(lastDate)) return lastDate;
  return value;
}
