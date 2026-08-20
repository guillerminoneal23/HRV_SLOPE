library;

String formatDateOnly(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String formatSessionDateForDisplay(String raw) {
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return raw;
  final date = formatDateOnly(parsed);
  if (!_hasExplicitTime(raw)) return date;
  final time =
      '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

bool sessionDateHasExplicitTime(String raw) {
  return _hasExplicitTime(raw);
}

bool _hasExplicitTime(String raw) {
  final trimmed = raw.trim();
  return RegExp(r'(?:T|\s)\d{2}:\d{2}').hasMatch(trimmed);
}
