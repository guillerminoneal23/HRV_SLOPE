import 'package:drift/drift.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/tables/tables.dart';

part 'athletes_dao.g.dart';

@DriftAccessor(tables: [Athletes, Sessions])
class AthletesDao extends DatabaseAccessor<AppDatabase>
    with _$AthletesDaoMixin {
  AthletesDao(super.db);

  /// Get all active (non-archived) athletes ordered by name.
  Future<List<Athlete>> getAllAthletes({bool includeArchived = false}) {
    final query = select(athletes);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  /// Get a single athlete by ID.
  Future<Athlete?> getAthleteById(int id) {
    return (select(athletes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Find athlete by name (case-insensitive).
  Future<Athlete?> getAthleteByName(String name) {
    return (select(athletes)
          ..where((t) => t.name.lower().equals(name.toLowerCase())))
        .getSingleOrNull();
  }

  /// Watch all active athletes (for reactive UI).
  Stream<List<Athlete>> watchAllAthletes({bool includeArchived = false}) {
    final query = select(athletes);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Insert a new athlete.
  Future<int> insertAthlete(AthletesCompanion athlete) {
    return into(athletes).insert(athlete);
  }

  /// Update an existing athlete.
  Future<bool> updateAthlete(Athlete athlete) {
    return update(athletes).replace(athlete);
  }

  /// Archive an athlete (soft delete).
  Future<void> archiveAthlete(int id) async {
    await (update(athletes)..where((t) => t.id.equals(id))).write(
      const AthletesCompanion(isArchived: Value(true)),
    );
  }

  /// Unarchive an athlete.
  Future<void> unarchiveAthlete(int id) async {
    await (update(athletes)..where((t) => t.id.equals(id))).write(
      const AthletesCompanion(isArchived: Value(false)),
    );
  }

  /// Delete an athlete by ID (hard delete).
  Future<int> deleteAthlete(int id) {
    return (delete(athletes)..where((t) => t.id.equals(id))).go();
  }

  /// Get the number of sessions for an athlete.
  Future<int> getSessionCount(int athleteId) async {
    final count = countAll();
    final query = selectOnly(sessions)
      ..addColumns([count])
      ..where(sessions.athleteId.equals(athleteId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Get the latest session for an athlete (for summary display).
  Future<Session?> getLatestSession(int athleteId) async {
    return (select(sessions)
          ..where((s) => s.athleteId.equals(athleteId))
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..limit(1))
        .getSingleOrNull();
  }
}
