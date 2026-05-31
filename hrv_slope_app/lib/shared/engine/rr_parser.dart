/// RR Interval Parser — Pure Dart logic for parsing RR interval input
/// from various text formats.
///
/// Supports: one-per-line, comma-separated, semicolon-separated,
/// tab-separated, CSV-like single column.
library;

/// Result of RR interval parsing.
class RrParseResult {
  /// Successfully parsed RR intervals in milliseconds.
  final List<double> rrIntervalsMs;

  /// Tokens that could not be parsed.
  final List<String> invalidTokens;

  /// Total number of tokens found.
  final int totalTokens;

  /// Whether the parse result is usable (at least one valid interval).
  bool get hasData => rrIntervalsMs.isNotEmpty;

  /// Whether there were any invalid tokens.
  bool get hasErrors => invalidTokens.isNotEmpty;

  const RrParseResult({
    required this.rrIntervalsMs,
    required this.invalidTokens,
    required this.totalTokens,
  });

  @override
  String toString() =>
      'RrParseResult(valid: ${rrIntervalsMs.length}, '
      'invalid: ${invalidTokens.length}, '
      'total: $totalTokens)';
}

/// Parses RR interval data from a text string.
///
/// Accepts:
/// - One value per line
/// - Comma-separated values
/// - Semicolon-separated values
/// - Tab-separated values
/// - Mixed separators
///
/// All values must be numeric (ms). Non-numeric tokens are collected
/// in [RrParseResult.invalidTokens].
RrParseResult parseRrIntervals(String input) {
  if (input.trim().isEmpty) {
    return const RrParseResult(
      rrIntervalsMs: [],
      invalidTokens: [],
      totalTokens: 0,
    );
  }

  // Split by any combination of newlines, commas, semicolons, tabs
  final tokens = input
      .split(RegExp(r'[\n\r,;\t]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  final validRr = <double>[];
  final invalidTokens = <String>[];

  for (final token in tokens) {
    final value = double.tryParse(token);
    if (value != null) {
      validRr.add(value);
    } else {
      invalidTokens.add(token);
    }
  }

  return RrParseResult(
    rrIntervalsMs: validRr,
    invalidTokens: invalidTokens,
    totalTokens: tokens.length,
  );
}
