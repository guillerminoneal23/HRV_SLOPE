/// Session type constants for the HRV Slope App.
library;

/// Valid session types.
enum SessionType {
  training('Training'),
  endurance('Endurance'),
  speed('Speed'),
  conditioning('Conditioning'),
  technicalTactical('Technical/Tactical'),
  test('Test'),
  strength('Strength'),
  sit('SIT'),
  hiit('HIIT'),
  rsa('RSA'),
  intermittentTest('Intermittent Test'),
  strengthTraining('Strength Training'),
  incrementalTest('Incremental Test'),
  constantLoadTest('Constant Load Test'),
  timeToExhaustion('Time to Exhaustion'),
  match('Match'),
  postMatchRecovery('Post-match Recovery'),
  groupSession('Group Session'),
  other('Other');

  final String label;
  const SessionType(this.label);

  /// Parse from stored string.
  static SessionType? fromString(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    return SessionType.values.cast<SessionType?>().firstWhere(
      (t) => t!.name == value || t.label.toLowerCase() == normalized,
      orElse: () => null,
    );
  }

  bool get isLegacyNewSessionOption =>
      this == SessionType.groupSession || this == SessionType.postMatchRecovery;
}

/// Session type option sets.
abstract final class SessionTypeOptions {
  /// Values offered when creating a new session.
  static final List<SessionType> newSessionOptions = SessionType.values
      .where((type) => !type.isLegacyNewSessionOption)
      .toList(growable: false);

  /// Legacy labels remain representable for historical sessions.
  static const legacyLabels = [
    'Group Session',
    'Post-match Recovery',
    'Post Match Recovery',
  ];

  /// System task tags seeded into the reusable catalog.
  static final List<String> systemTaskTagNames = [
    for (final type in newSessionOptions) type.label,
  ];
}

/// Variable categories.
enum VariableCategory {
  external_('external', 'External Load'),
  internal_('internal', 'Internal Load'),
  hrv('hrv', 'HRV'),
  derived('derived', 'Derived'),
  context_('context', 'Context');

  final String value;
  final String label;
  const VariableCategory(this.value, this.label);
}

/// Standard variable definitions for the tagging system.
class VariableDefinition {
  final String name;
  final String label;
  final String? unit;
  final VariableCategory category;

  const VariableDefinition({
    required this.name,
    required this.label,
    this.unit,
    required this.category,
  });
}

/// All standard variable definitions.
abstract final class StandardVariables {
  // External Load
  static const speedKmh = VariableDefinition(
    name: 'speed_kmh',
    label: 'Speed',
    unit: 'km/h',
    category: VariableCategory.external_,
  );
  static const percentMas = VariableDefinition(
    name: 'percent_mas',
    label: '% MAS',
    unit: '%',
    category: VariableCategory.external_,
  );
  static const percentVvo2max = VariableDefinition(
    name: 'percent_vvo2max',
    label: '% vVO₂max',
    unit: '%',
    category: VariableCategory.external_,
  );
  static const powerW = VariableDefinition(
    name: 'power_w',
    label: 'Power',
    unit: 'W',
    category: VariableCategory.external_,
  );
  static const percentMap = VariableDefinition(
    name: 'percent_map',
    label: '% MAP',
    unit: '%',
    category: VariableCategory.external_,
  );
  static const distanceM = VariableDefinition(
    name: 'distance_m',
    label: 'Distance',
    unit: 'm',
    category: VariableCategory.external_,
  );
  static const durationMin = VariableDefinition(
    name: 'duration_min',
    label: 'Duration',
    unit: 'min',
    category: VariableCategory.external_,
  );
  static const playerLoad = VariableDefinition(
    name: 'player_load',
    label: 'Player Load',
    unit: 'AU',
    category: VariableCategory.external_,
  );
  static const accelerations = VariableDefinition(
    name: 'accelerations',
    label: 'Accelerations',
    unit: 'count',
    category: VariableCategory.external_,
  );
  static const decelerations = VariableDefinition(
    name: 'decelerations',
    label: 'Decelerations',
    unit: 'count',
    category: VariableCategory.external_,
  );

  // Internal Load
  static const rpe110 = VariableDefinition(
    name: 'rpe_1_10',
    label: 'RPE (1-10)',
    unit: '',
    category: VariableCategory.internal_,
  );
  static const srpe = VariableDefinition(
    name: 'srpe',
    label: 'sRPE',
    unit: 'AU',
    category: VariableCategory.internal_,
  );
  static const trimp = VariableDefinition(
    name: 'trimp',
    label: 'TRIMP',
    unit: 'AU',
    category: VariableCategory.internal_,
  );
  static const heartRateMean = VariableDefinition(
    name: 'heart_rate_mean',
    label: 'Mean HR',
    unit: 'bpm',
    category: VariableCategory.internal_,
  );
  static const percentHrmax = VariableDefinition(
    name: 'percent_hrmax',
    label: '% HRmax',
    unit: '%',
    category: VariableCategory.internal_,
  );
  static const lactateMmol = VariableDefinition(
    name: 'lactate_mmol',
    label: 'Lactate',
    unit: 'mmol/L',
    category: VariableCategory.internal_,
  );
  static const subjectiveFatigue = VariableDefinition(
    name: 'subjective_fatigue_1_10',
    label: 'Subjective Fatigue (1-10)',
    unit: '',
    category: VariableCategory.internal_,
  );

  // Context
  static const sleepHours = VariableDefinition(
    name: 'sleep_hours',
    label: 'Sleep Hours',
    unit: 'h',
    category: VariableCategory.context_,
  );
  static const soreness = VariableDefinition(
    name: 'soreness',
    label: 'Soreness',
    unit: '1-10',
    category: VariableCategory.context_,
  );
  static const temperature = VariableDefinition(
    name: 'temperature',
    label: 'Temperature',
    unit: '°C',
    category: VariableCategory.context_,
  );
  static const humidity = VariableDefinition(
    name: 'humidity',
    label: 'Humidity',
    unit: '%',
    category: VariableCategory.context_,
  );
  static const altitude = VariableDefinition(
    name: 'altitude',
    label: 'Altitude',
    unit: 'm',
    category: VariableCategory.context_,
  );

  static const externalVariables = [
    speedKmh,
    percentMas,
    percentVvo2max,
    powerW,
    percentMap,
    distanceM,
    durationMin,
    playerLoad,
    accelerations,
    decelerations,
  ];

  static const internalVariables = [
    rpe110,
    srpe,
    trimp,
    heartRateMean,
    percentHrmax,
    lactateMmol,
    subjectiveFatigue,
  ];

  static const contextVariables = [
    sleepHours,
    soreness,
    temperature,
    humidity,
    altitude,
  ];
}
