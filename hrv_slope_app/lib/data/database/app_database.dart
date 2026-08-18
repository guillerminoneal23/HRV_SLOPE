/// Main Drift database definition for the HRV Slope App.
///
/// Includes all persistent tables and provides DAOs for data access.
/// Schema version 5 adds team assignments and grouped session events.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:hrv_slope_app/data/database/tables/tables.dart';
import 'package:hrv_slope_app/data/database/daos/athletes_dao.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/data/database/daos/session_events_dao.dart';
import 'package:hrv_slope_app/data/database/daos/settings_dao.dart';
import 'package:hrv_slope_app/data/database/daos/teams_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Athletes,
    Teams,
    SessionEvents,
    Sessions,
    AthleteTeamAssignments,
    MeasurementsHrv,
    IntensityVariables,
    NomogramModels,
    ImportBatches,
    ExclusionsOrNotes,
    AppSettings,
  ],
  daos: [AthletesDao, SessionsDao, SessionEventsDao, SettingsDao, TeamsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with an in-memory database.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Seed default settings
        await into(appSettings).insert(
          AppSettingsCompanion.insert(
            key: 'default_rmssd_exercise_ms',
            value: '4.0',
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );
        await into(appSettings).insert(
          AppSettingsCompanion.insert(
            key: 'slope_min_for_interpretation',
            value: '0.1',
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );
        await into(appSettings).insert(
          AppSettingsCompanion.insert(
            key: 'preferred_recovery_window_min',
            value: '10',
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );
        await into(appSettings).insert(
          AppSettingsCompanion.insert(
            key: 'nomogram_mode',
            value: 'population',
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );
        await into(appSettings).insert(
          AppSettingsCompanion.insert(
            key: 'population_nomogram_preset',
            value: 'excel_operational',
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );
        await into(appSettings).insert(
          AppSettingsCompanion.insert(
            key: 'locale',
            value: 'es',
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Phase 2 additions
          await m.addColumn(athletes, athletes.positionOrEvent);
          await m.addColumn(athletes, athletes.isArchived);
          await m.addColumn(sessions, sessions.sessionType);
          await m.addColumn(sessions, sessions.protocolName);
          await m.addColumn(sessions, sessions.contextEnvironment);
          await m.addColumn(sessions, sessions.isDraft);
          await m.addColumn(sessions, sessions.recoveryWindowEndMin);
          // Add default population preset setting
          await into(appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: 'population_nomogram_preset',
              value: 'excel_operational',
              updatedAt: DateTime.now().toIso8601String(),
            ),
          );
        }
        if (from < 3) {
          // Phase 2.1 additions
          await m.addColumn(sessions, sessions.hrvInputMode);
          await m.addColumn(sessions, sessions.rmssdRecoverySource);
          await m.addColumn(sessions, sessions.rmssdExerciseSource);
          await m.addColumn(sessions, sessions.rrQualityFlag);
          await m.addColumn(sessions, sessions.rrArtifactPercent);
        }
        if (from < 4) {
          // Phase 2.2 RR preprocessing audit metadata
          await m.addColumn(sessions, sessions.rrPreprocessingMode);
          await m.addColumn(sessions, sessions.rrCorrectionEnabled);
          await m.addColumn(sessions, sessions.rrCorrectionMethod);
          await m.addColumn(sessions, sessions.rrRawRmssd);
          await m.addColumn(sessions, sessions.rrCorrectedRmssd);
          await m.addColumn(sessions, sessions.rrRmssdUsed);
          await m.addColumn(sessions, sessions.rrArtifactCount);
          await m.addColumn(sessions, sessions.rrQualityDecision);
          await m.addColumn(sessions, sessions.rrQualityNotesJson);
          await m.addColumn(sessions, sessions.rrRmssdDeltaPercent);
        }
        if (from < 5) {
          // Team and multi-session event infrastructure.
          await m.createTable(teams);
          await m.createTable(sessionEvents);
          await m.createTable(athleteTeamAssignments);
          await m.addColumn(sessions, sessions.eventId);
          await _createV5Indexes();
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createV5Indexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_session_events_date '
      'ON session_events (date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_session_events_team_id_date '
      'ON session_events (team_id, date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_event_id '
      'ON sessions (event_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_athlete_id_event_id '
      'ON sessions (athlete_id, event_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_athlete_team_assignments_team_id '
      'ON athlete_team_assignments (team_id)',
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hrv_slope_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
