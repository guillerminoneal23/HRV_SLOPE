import 'package:drift/drift.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/tables/tables.dart';

part 'sessions_dao.g.dart';

class SessionDetail {
  final Athlete athlete;
  final Session session;
  final List<IntensityVariable> variables;
  final List<MeasurementsHrvData> hrvMeasurements;
  final List<ExclusionsOrNote> notes;

  const SessionDetail({
    required this.athlete,
    required this.session,
    required this.variables,
    required this.hrvMeasurements,
    required this.notes,
  });

  List<IntensityVariable> variablesByCategory(String category) {
    return variables.where((v) => v.category == category).toList();
  }
}

@DriftAccessor(
  tables: [
    Sessions,
    MeasurementsHrv,
    IntensityVariables,
    ImportBatches,
    ExclusionsOrNotes,
  ],
)
class SessionsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionsDaoMixin {
  SessionsDao(super.db);

  // ── Sessions ────────────────────────────────────────────────────────────

  /// Get all sessions for an athlete, ordered by date descending.
  Future<List<Session>> getSessionsForAthlete(int athleteId) {
    return (select(sessions)
          ..where((s) => s.athleteId.equals(athleteId))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .get();
  }

  /// Alias used by edit/detail flows.
  Future<List<Session>> listSessionsForAthlete(int athleteId) {
    return getSessionsForAthlete(athleteId);
  }

  /// Get all sessions, ordered by date descending.
  Future<List<Session>> getAllSessions() {
    return (select(
      sessions,
    )..orderBy([(s) => OrderingTerm.desc(s.date)])).get();
  }

  /// Get a single session by ID.
  Future<Session?> getSessionById(int id) {
    return (select(sessions)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Get the complete session detail aggregate used by detail/edit screens.
  Future<SessionDetail?> getSessionDetail(int sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return null;

    final athlete = await (select(
      db.athletes,
    )..where((a) => a.id.equals(session.athleteId))).getSingleOrNull();
    if (athlete == null) return null;

    final variables = await getVariablesForSession(sessionId);
    final hrvMeasurements = await getHrvMeasurements(sessionId);
    final notes = await (select(
      exclusionsOrNotes,
    )..where((e) => e.sessionId.equals(sessionId))).get();

    return SessionDetail(
      athlete: athlete,
      session: session,
      variables: variables,
      hrvMeasurements: hrvMeasurements,
      notes: notes,
    );
  }

  /// Get detail aggregates for all sessions.
  Future<List<SessionDetail>> getAllSessionDetails() async {
    final allSessions = await getAllSessions();
    return _buildSessionDetailsBatch(allSessions);
  }

  /// Get detail aggregates for one athlete, ordered by session date.
  Future<List<SessionDetail>> getSessionDetailsForAthlete(int athleteId) async {
    final athleteSessions = await getSessionsForAthlete(athleteId);
    return _buildSessionDetailsBatch(athleteSessions.reversed.toList());
  }

  Future<List<SessionDetail>> _buildSessionDetailsBatch(
    List<Session> orderedSessions,
  ) async {
    if (orderedSessions.isEmpty) return const [];

    final sessionIds = orderedSessions.map((session) => session.id).toList();
    final athleteIds = orderedSessions
        .map((session) => session.athleteId)
        .toSet()
        .toList();

    final detailAthletes = await (select(
      db.athletes,
    )..where((a) => a.id.isIn(athleteIds))).get();
    final detailVariables =
        await (select(intensityVariables)
              ..where((v) => v.sessionId.isIn(sessionIds))
              ..orderBy([
                (v) => OrderingTerm.asc(v.sessionId),
                (v) => OrderingTerm.asc(v.category),
                (v) => OrderingTerm.asc(v.id),
              ]))
            .get();
    final detailHrvMeasurements =
        await (select(measurementsHrv)
              ..where((m) => m.sessionId.isIn(sessionIds))
              ..orderBy([
                (m) => OrderingTerm.asc(m.sessionId),
                (m) => OrderingTerm.asc(m.id),
              ]))
            .get();
    final detailNotes =
        await (select(exclusionsOrNotes)
              ..where((e) => e.sessionId.isIn(sessionIds))
              ..orderBy([
                (e) => OrderingTerm.asc(e.sessionId),
                (e) => OrderingTerm.asc(e.id),
              ]))
            .get();

    final athletesById = {
      for (final athlete in detailAthletes) athlete.id: athlete,
    };
    final variablesBySession = _groupVariablesBySessionId(detailVariables);
    final hrvBySession = _groupHrvBySessionId(detailHrvMeasurements);
    final notesBySession = _groupNotesBySessionId(detailNotes);

    final details = <SessionDetail>[];
    for (final session in orderedSessions) {
      final athlete = athletesById[session.athleteId];
      if (athlete == null) continue;
      details.add(
        SessionDetail(
          athlete: athlete,
          session: session,
          variables: variablesBySession[session.id] ?? const [],
          hrvMeasurements: hrvBySession[session.id] ?? const [],
          notes: notesBySession[session.id] ?? const [],
        ),
      );
    }
    return details;
  }

  /// Get sessions for a specific date and optional task (for group reports).
  Future<List<Session>> getSessionsByDateAndTask(
    String date, {
    String? taskName,
  }) {
    return (select(sessions)
          ..where((s) {
            final dateFilter = s.date.equals(date);
            if (taskName != null) {
              return dateFilter & s.taskName.equals(taskName);
            }
            return dateFilter;
          })
          ..orderBy([(s) => OrderingTerm.asc(s.athleteId)]))
        .get();
  }

  /// Watch sessions for an athlete (reactive).
  Stream<List<Session>> watchSessionsForAthlete(int athleteId) {
    return (select(sessions)
          ..where((s) => s.athleteId.equals(athleteId))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  /// Insert a new session.
  Future<int> insertSession(SessionsCompanion session) {
    return into(sessions).insert(session);
  }

  /// Update a session.
  Future<bool> updateSession(Session session) {
    return update(sessions).replace(session);
  }

  /// Update a session with companion (partial update).
  Future<void> updateSessionPartial(int id, SessionsCompanion companion) async {
    await (update(sessions)..where((s) => s.id.equals(id))).write(companion);
  }

  Future<void> updateSessionMetadata({
    required int sessionId,
    required String date,
    String? taskName,
    String? sport,
    String? sessionType,
    String? protocolName,
    String? contextEnvironment,
    String? notes,
    bool? isDraft,
  }) async {
    await updateSessionPartial(
      sessionId,
      SessionsCompanion(
        date: Value(date),
        taskName: Value(taskName),
        sport: Value(sport),
        sessionType: Value(sessionType),
        protocolName: Value(protocolName),
        contextEnvironment: Value(contextEnvironment),
        notes: Value(notes),
        isDraft: isDraft == null ? const Value.absent() : Value(isDraft),
      ),
    );
  }

  /// Replace external/internal/derived variables for a session.
  Future<void> updateSessionVariables(
    int sessionId,
    List<IntensityVariablesCompanion> variables,
  ) async {
    await transaction(() async {
      await deleteVariablesForSession(sessionId);
      if (variables.isNotEmpty) {
        await insertVariables(variables);
      }
    });
  }

  /// Replace HRV measurements for a session.
  Future<void> updateSessionHrvMeasurement(
    int sessionId,
    List<MeasurementsHrvCompanion> measurements,
  ) async {
    await transaction(() async {
      await deleteHrvMeasurementsForSession(sessionId);
      await batch((batch) {
        batch.insertAll(measurementsHrv, measurements);
      });
    });
  }

  /// Delete a session by ID, removing dependent rows first.
  Future<void> deleteSession(int id) => deleteSessionCascade(id);

  /// Hard delete a session and dependent application-owned rows.
  Future<void> deleteSessionCascade(int id) async {
    await transaction(() async {
      await (delete(
        measurementsHrv,
      )..where((m) => m.sessionId.equals(id))).go();
      await (delete(
        intensityVariables,
      )..where((v) => v.sessionId.equals(id))).go();
      await (delete(
        exclusionsOrNotes,
      )..where((e) => e.sessionId.equals(id))).go();
      await (delete(sessions)..where((s) => s.id.equals(id))).go();
    });
  }

  // ── Intensity Variables ─────────────────────────────────────────────────

  /// Get all variables for a session.
  Future<List<IntensityVariable>> getVariablesForSession(int sessionId) {
    return (select(intensityVariables)
          ..where((v) => v.sessionId.equals(sessionId))
          ..orderBy([(v) => OrderingTerm.asc(v.category)]))
        .get();
  }

  /// Get variables for a session filtered by category.
  Future<List<IntensityVariable>> getVariablesByCategory(
    int sessionId,
    String category,
  ) {
    return (select(intensityVariables)..where(
          (v) => v.sessionId.equals(sessionId) & v.category.equals(category),
        ))
        .get();
  }

  /// Insert a variable.
  Future<int> insertVariable(IntensityVariablesCompanion variable) {
    return into(intensityVariables).insert(variable);
  }

  /// Insert multiple variables.
  Future<void> insertVariables(
    List<IntensityVariablesCompanion> variables,
  ) async {
    await batch((batch) {
      batch.insertAll(intensityVariables, variables);
    });
  }

  /// Delete all variables for a session.
  Future<void> deleteVariablesForSession(int sessionId) async {
    await (delete(
      intensityVariables,
    )..where((v) => v.sessionId.equals(sessionId))).go();
  }

  // ── HRV Measurements ───────────────────────────────────────────────────

  /// Get HRV measurements for a session.
  Future<List<MeasurementsHrvData>> getHrvMeasurements(int sessionId) {
    return (select(
      measurementsHrv,
    )..where((m) => m.sessionId.equals(sessionId))).get();
  }

  /// Insert an HRV measurement.
  Future<int> insertHrvMeasurement(MeasurementsHrvCompanion measurement) {
    return into(measurementsHrv).insert(measurement);
  }

  /// Delete all HRV measurements for a session.
  Future<void> deleteHrvMeasurementsForSession(int sessionId) async {
    await (delete(
      measurementsHrv,
    )..where((m) => m.sessionId.equals(sessionId))).go();
  }

  // ── Import Batches ──────────────────────────────────────────────────────

  /// Create an import batch and return its ID.
  Future<int> createImportBatch(ImportBatchesCompanion batch) {
    return into(importBatches).insert(batch);
  }

  /// Get all import batches.
  Future<List<ImportBatche>> getAllImportBatches() {
    return (select(
      importBatches,
    )..orderBy([(b) => OrderingTerm.desc(b.createdAt)])).get();
  }

  // ── Nomogram Data ───────────────────────────────────────────────────────

  /// Get all valid (intensity, slope) pairs for an athlete for nomogram fitting.
  Future<List<({double intensityPercent, double slope})>> getNomogramDataPoints(
    int athleteId,
  ) async {
    final rows =
        await (select(sessions)..where(
              (s) =>
                  s.athleteId.equals(athleteId) &
                  s.intensityPercent.isNotNull() &
                  s.slopeInterpreted.isNotNull(),
            ))
            .get();

    return rows
        .map(
          (s) => (
            intensityPercent: s.intensityPercent!,
            slope: s.slopeInterpreted!,
          ),
        )
        .toList();
  }
}

Map<int, List<IntensityVariable>> _groupVariablesBySessionId(
  List<IntensityVariable> rows,
) {
  final grouped = <int, List<IntensityVariable>>{};
  for (final row in rows) {
    grouped.putIfAbsent(row.sessionId, () => []).add(row);
  }
  return grouped;
}

Map<int, List<MeasurementsHrvData>> _groupHrvBySessionId(
  List<MeasurementsHrvData> rows,
) {
  final grouped = <int, List<MeasurementsHrvData>>{};
  for (final row in rows) {
    grouped.putIfAbsent(row.sessionId, () => []).add(row);
  }
  return grouped;
}

Map<int, List<ExclusionsOrNote>> _groupNotesBySessionId(
  List<ExclusionsOrNote> rows,
) {
  final grouped = <int, List<ExclusionsOrNote>>{};
  for (final row in rows) {
    final sessionId = row.sessionId;
    if (sessionId == null) continue;
    grouped.putIfAbsent(sessionId, () => []).add(row);
  }
  return grouped;
}
