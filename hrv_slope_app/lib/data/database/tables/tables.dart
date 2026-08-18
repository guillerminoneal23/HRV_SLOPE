/// Drift table definitions for the HRV Slope App database.
///
/// All 11 tables as defined in DATA_MODEL.md.
/// Phase 2 additions: session_type, protocol_name, context_environment,
/// position_or_event, is_archived.
library;

import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// 1. Athletes
// ---------------------------------------------------------------------------

class Athletes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get sport => text().nullable()();
  TextColumn get birthDate => text().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get positionOrEvent => text().nullable()();
  RealColumn get masKmh => real().nullable()();
  RealColumn get vvo2maxKmh => real().nullable()();
  RealColumn get mapW => real().nullable()();
  RealColumn get fcMax => real().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

// ---------------------------------------------------------------------------
// 2. Teams
// ---------------------------------------------------------------------------

class Teams extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get normalizedName =>
      text().withLength(min: 1, max: 200).unique()();
  TextColumn get sport => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

// ---------------------------------------------------------------------------
// 3. Session Events
// ---------------------------------------------------------------------------

@TableIndex(name: 'idx_session_events_date', columns: {#date})
@TableIndex(name: 'idx_session_events_team_id_date', columns: {#teamId, #date})
class SessionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get teamId => integer().nullable().references(
    Teams,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get date => text()();
  TextColumn get taskName => text().nullable()();
  TextColumn get sport => text().nullable()();
  TextColumn get sessionType => text().nullable()();
  TextColumn get protocolName => text().nullable()();
  TextColumn get contextEnvironment => text().nullable()();
  RealColumn get recoveryWindowStartMin => real()();
  RealColumn get recoveryWindowEndMin => real()();
  TextColumn get loadType => text()();
  TextColumn get loadMetricName => text().withLength(min: 1, max: 200)();
  TextColumn get loadUnit => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  List<String> get customConstraints => [
    "CHECK (load_type IN ('internal', 'external'))",
  ];
}

// ---------------------------------------------------------------------------
// 4. Sessions
// ---------------------------------------------------------------------------

@TableIndex(name: 'idx_sessions_event_id', columns: {#eventId})
@TableIndex(
  name: 'idx_sessions_athlete_id_event_id',
  columns: {#athleteId, #eventId},
)
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get athleteId => integer().references(Athletes, #id)();
  IntColumn get eventId => integer().nullable().references(
    SessionEvents,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get date => text()();
  TextColumn get taskName => text().nullable()();
  TextColumn get sport => text().nullable()();
  TextColumn get sessionType => text().nullable()();
  TextColumn get protocolName => text().nullable()();
  TextColumn get contextEnvironment => text().nullable()();
  BoolColumn get isDraft => boolean().withDefault(const Constant(false))();
  RealColumn get intensityPercent => real().nullable()();
  TextColumn get intensitySource => text().nullable()();
  RealColumn get recoveryTimeMin => real().nullable()();
  RealColumn get recoveryWindowStartMin => real().nullable()();
  RealColumn get recoveryWindowEndMin => real().nullable()();
  RealColumn get rmssdExercise => real().nullable()();
  BoolColumn get rmssdExerciseIsDefault =>
      boolean().withDefault(const Constant(false))();
  RealColumn get rmssdRecovery => real().nullable()();
  RealColumn get slopeRaw => real().nullable()();
  RealColumn get slopeInterpreted => real().nullable()();
  RealColumn get itlIndex => real().nullable()();
  TextColumn get classification => text().nullable()();
  TextColumn get hrvInputMode =>
      text().nullable()(); // direct_rmssd / rr_intervals
  TextColumn get rmssdRecoverySource => text()
      .nullable()(); // manual / elite_hrv / kubios / computed_from_rr / etc.
  TextColumn get rmssdExerciseSource =>
      text().nullable()(); // measured / fallback_4_ms / computed_from_rr / etc.
  TextColumn get rrQualityFlag =>
      text().nullable()(); // valid / warning / invalid
  RealColumn get rrArtifactPercent => real().nullable()();
  TextColumn get rrPreprocessingMode => text().nullable()();
  BoolColumn get rrCorrectionEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get rrCorrectionMethod => text().nullable()();
  RealColumn get rrRawRmssd => real().nullable()();
  RealColumn get rrCorrectedRmssd => real().nullable()();
  RealColumn get rrRmssdUsed => real().nullable()();
  IntColumn get rrArtifactCount => integer().nullable()();
  TextColumn get rrQualityDecision => text().nullable()();
  TextColumn get rrQualityNotesJson => text().nullable()();
  RealColumn get rrRmssdDeltaPercent => real().nullable()();
  IntColumn get importBatchId =>
      integer().nullable().references(ImportBatches, #id)();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
}

// ---------------------------------------------------------------------------
// 5. Athlete Team Assignments
// ---------------------------------------------------------------------------

@TableIndex(name: 'idx_athlete_team_assignments_team_id', columns: {#teamId})
class AthleteTeamAssignments extends Table {
  IntColumn get athleteId =>
      integer().references(Athletes, #id, onDelete: KeyAction.cascade)();
  IntColumn get teamId =>
      integer().references(Teams, #id, onDelete: KeyAction.cascade)();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {athleteId};
}

// ---------------------------------------------------------------------------
// 6. Measurements HRV
// ---------------------------------------------------------------------------

class MeasurementsHrv extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(Sessions, #id)();
  TextColumn get phase => text()(); // exercise / recovery / rest
  RealColumn get windowStartMin => real().nullable()();
  RealColumn get windowEndMin => real().nullable()();
  TextColumn get rrIntervalsJson => text().nullable()();
  RealColumn get rmssd => real().nullable()();
  RealColumn get meanHr => real().nullable()();
  RealColumn get sdnn => real().nullable()();
  TextColumn get createdAt => text()();
}

// ---------------------------------------------------------------------------
// 7. Intensity Variables
// ---------------------------------------------------------------------------

class IntensityVariables extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(Sessions, #id)();
  TextColumn get category =>
      text()(); // external / internal / hrv / derived / context
  TextColumn get name => text()();
  TextColumn get unit => text().nullable()();
  RealColumn get value => real()();
  TextColumn get source =>
      text().nullable()(); // manual / csv / xlsx / device / calculated
  BoolColumn get isPrimaryForNomogram =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
}

// ---------------------------------------------------------------------------
// 8. Nomogram Models
// ---------------------------------------------------------------------------

class NomogramModels extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get athleteId => integer().unique().references(Athletes, #id)();
  RealColumn get paramA => real()();
  RealColumn get paramB => real()();
  RealColumn get paramC => real()();
  RealColumn get rSquared => real().nullable()();
  IntColumn get nPoints => integer()();
  IntColumn get nIntensityRanges => integer()();
  TextColumn get confidenceLevel =>
      text()(); // insufficient / initial / acceptable / robust
  TextColumn get lastUpdated => text()();
}

// ---------------------------------------------------------------------------
// 9. Import Batches
// ---------------------------------------------------------------------------

class ImportBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filename => text().nullable()();
  TextColumn get importType => text()(); // csv / xlsx / manual / rr_intervals
  IntColumn get rowCount => integer().nullable()();
  IntColumn get errorCount => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
}

// ---------------------------------------------------------------------------
// 10. Exclusions or Notes
// ---------------------------------------------------------------------------

class ExclusionsOrNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().nullable().references(Sessions, #id)();
  IntColumn get athleteId => integer().nullable().references(Athletes, #id)();
  TextColumn get type => text()(); // exclusion / note / flag
  TextColumn get reason => text()();
  TextColumn get createdAt => text()();
}

// ---------------------------------------------------------------------------
// 11. App Settings
// ---------------------------------------------------------------------------

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {key};
}
