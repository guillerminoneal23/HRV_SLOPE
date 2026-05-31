/// HRV Input Mode and Source constants for Phase 2.1.
library;

/// HRV input mode — how RMSSD values were obtained.
enum HrvInputMode {
  directRmssd('direct_rmssd', 'Direct RMSSD values'),
  rrIntervals('rr_intervals', 'RR interval data');

  final String value;
  final String label;
  const HrvInputMode(this.value, this.label);
}

/// Source of RMSSD recovery value.
enum RmssdRecoverySourceType {
  manual('manual', 'Manual entry'),
  eliteHrv('elite_hrv', 'Elite HRV'),
  kubios('kubios', 'Kubios'),
  hrvLogger('hrv_logger', 'HRV Logger'),
  polar('polar', 'Polar'),
  garmin('garmin', 'Garmin / Other device'),
  computedFromRr('computed_from_rr', 'Computed from RR intervals'),
  csvImport('csv_import', 'CSV import'),
  other('other', 'Other');

  final String value;
  final String label;
  const RmssdRecoverySourceType(this.value, this.label);

  static RmssdRecoverySourceType fromValue(String v) {
    return RmssdRecoverySourceType.values.firstWhere(
      (s) => s.value == v,
      orElse: () => RmssdRecoverySourceType.other,
    );
  }
}

/// Source of RMSSD exercise value.
enum RmssdExerciseSourceType {
  measured('measured', 'Measured'),
  fallback4ms('fallback_4_ms', 'Fallback 4 ms'),
  computedFromRr('computed_from_rr', 'Computed from RR intervals'),
  other('other', 'Other');

  final String value;
  final String label;
  const RmssdExerciseSourceType(this.value, this.label);

  static RmssdExerciseSourceType fromValue(String v) {
    return RmssdExerciseSourceType.values.firstWhere(
      (s) => s.value == v,
      orElse: () => RmssdExerciseSourceType.other,
    );
  }
}
