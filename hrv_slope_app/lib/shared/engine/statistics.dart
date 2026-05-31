/// Statistics utilities — Rolling averages and fatigue flag detection
/// for longitudinal monitoring.
library;

/// Summary data for a single session used in longitudinal analysis.
class SessionSummary {
  final DateTime date;
  final double slopeInterpreted;
  final double intensityPercent;
  final double? expectedSlope;
  final double? rpe;
  final double? srpe;
  final double? trimp;

  const SessionSummary({
    required this.date,
    required this.slopeInterpreted,
    required this.intensityPercent,
    this.expectedSlope,
    this.rpe,
    this.srpe,
    this.trimp,
  });
}

/// Fatigue flag severity levels.
enum FatigueSeverity { none, warning, alert }

/// A detected fatigue flag with context.
class FatigueFlag {
  final FatigueSeverity severity;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;

  const FatigueFlag({
    required this.severity,
    required this.reason,
    required this.startDate,
    required this.endDate,
  });
}

/// Computes a rolling average of [values] over a [windowSize] window.
///
/// Returns a list of the same length as [values].
/// The first (windowSize - 1) entries use whatever data is available
/// (partial window average).
List<double?> rollingAverage(List<double?> values, int windowSize) {
  if (values.isEmpty || windowSize <= 0) return [];

  final result = <double?>[];

  for (int i = 0; i < values.length; i++) {
    final start = (i - windowSize + 1).clamp(0, values.length);
    final window = values.sublist(start, i + 1);
    final validValues = window.whereType<double>().toList();

    if (validValues.isEmpty) {
      result.add(null);
    } else {
      result.add(validValues.reduce((a, b) => a + b) / validValues.length);
    }
  }

  return result;
}

/// Detects fatigue flags in a sequence of sessions.
///
/// Rules:
/// 1. Slope residual < -0.5 for ≥3 consecutive sessions → alert.
/// 2. Rolling 7-day slope avg drops >30% vs 28-day avg → warning.
/// 3. ITL rolling 7-day avg increases >50% vs 28-day avg → warning.
List<FatigueFlag> detectFatigueFlags(List<SessionSummary> sessions) {
  if (sessions.length < 3) return [];

  final flags = <FatigueFlag>[];

  // Sort by date
  final sorted = List<SessionSummary>.from(sessions)
    ..sort((a, b) => a.date.compareTo(b.date));

  // Rule 1: Consecutive negative residuals
  int consecutiveNeg = 0;
  int negStartIdx = 0;

  for (int i = 0; i < sorted.length; i++) {
    final s = sorted[i];
    if (s.expectedSlope != null) {
      final residual = s.slopeInterpreted - s.expectedSlope!;
      if (residual < -0.5) {
        if (consecutiveNeg == 0) negStartIdx = i;
        consecutiveNeg++;
        if (consecutiveNeg >= 3) {
          flags.add(
            FatigueFlag(
              severity: FatigueSeverity.alert,
              reason:
                  'Slope below expected for $consecutiveNeg consecutive sessions',
              startDate: sorted[negStartIdx].date,
              endDate: sorted[i].date,
            ),
          );
        }
      } else {
        consecutiveNeg = 0;
      }
    }
  }

  // Rule 2 & 3: Rolling averages comparison
  final slopes = sorted.map((s) => s.slopeInterpreted as double?).toList();
  final rolling7 = rollingAverage(slopes, 7);
  final rolling28 = rollingAverage(slopes, 28);

  for (int i = 7; i < sorted.length; i++) {
    if (rolling7[i] != null && rolling28[i] != null && rolling28[i]! > 0) {
      final dropPercent = (rolling28[i]! - rolling7[i]!) / rolling28[i]! * 100;
      if (dropPercent > 30) {
        flags.add(
          FatigueFlag(
            severity: FatigueSeverity.warning,
            reason:
                '7-day slope average dropped ${dropPercent.toStringAsFixed(1)}% '
                'vs 28-day average',
            startDate: sorted[i].date,
            endDate: sorted[i].date,
          ),
        );
      }
    }
  }

  return flags;
}
