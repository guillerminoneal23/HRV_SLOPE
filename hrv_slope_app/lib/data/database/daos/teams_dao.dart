import 'package:drift/drift.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/tables/tables.dart';

part 'teams_dao.g.dart';

@DriftAccessor(tables: [Teams, AthleteTeamAssignments, Athletes, Sessions])
class TeamsDao extends DatabaseAccessor<AppDatabase> with _$TeamsDaoMixin {
  TeamsDao(super.db);

  static String normalizeTeamName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<int> createTeam({required String name, String? sport, String? notes}) {
    final now = DateTime.now().toIso8601String();
    final cleanName = _requiredTrimmed(name, 'Team name');
    return into(teams).insert(
      TeamsCompanion.insert(
        name: cleanName,
        normalizedName: normalizeTeamName(cleanName),
        sport: Value(_blankToNull(sport)),
        notes: Value(_blankToNull(notes)),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateTeam({
    required int id,
    required String name,
    String? sport,
    String? notes,
  }) async {
    final cleanName = _requiredTrimmed(name, 'Team name');
    await (update(teams)..where((t) => t.id.equals(id))).write(
      TeamsCompanion(
        name: Value(cleanName),
        normalizedName: Value(normalizeTeamName(cleanName)),
        sport: Value(_blankToNull(sport)),
        notes: Value(_blankToNull(notes)),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> archiveTeam(int id) async {
    await (update(teams)..where((t) => t.id.equals(id))).write(
      TeamsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> restoreTeam(int id) async {
    await (update(teams)..where((t) => t.id.equals(id))).write(
      TeamsCompanion(
        isArchived: const Value(false),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<Team?> getTeamById(int id) {
    return (select(teams)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Team?> getTeamByNormalizedName(String name) {
    final normalized = normalizeTeamName(name);
    return (select(
      teams,
    )..where((t) => t.normalizedName.equals(normalized))).getSingleOrNull();
  }

  Future<List<Team>> getAllTeams({bool includeArchived = false}) {
    final query = select(teams);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  Future<List<Team>> getActiveTeams() {
    return getAllTeams();
  }

  Future<List<Team>> getArchivedTeams() {
    return (select(teams)
          ..where((t) => t.isArchived.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<AthleteTeamAssignment?> getAssignmentForAthlete(int athleteId) {
    return (select(
      athleteTeamAssignments,
    )..where((a) => a.athleteId.equals(athleteId))).getSingleOrNull();
  }

  Future<List<AthleteTeamAssignment>> getAllAssignments() {
    return select(athleteTeamAssignments).get();
  }

  Future<void> assignAthleteToTeam({
    required int athleteId,
    required int teamId,
  }) async {
    final team = await getTeamById(teamId);
    if (team == null) {
      throw StateError('Team not found.');
    }
    if (team.isArchived) {
      throw StateError('Archived teams cannot receive athletes.');
    }

    final now = DateTime.now().toIso8601String();
    final existing = await getAssignmentForAthlete(athleteId);
    if (existing == null) {
      await into(athleteTeamAssignments).insert(
        AthleteTeamAssignmentsCompanion.insert(
          athleteId: Value(athleteId),
          teamId: teamId,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return;
    }

    await (update(
      athleteTeamAssignments,
    )..where((a) => a.athleteId.equals(athleteId))).write(
      AthleteTeamAssignmentsCompanion(
        teamId: Value(teamId),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> moveAthleteToTeam({
    required int athleteId,
    required int teamId,
  }) {
    return assignAthleteToTeam(athleteId: athleteId, teamId: teamId);
  }

  Future<void> removeAthleteFromTeam(int athleteId) async {
    await (delete(
      athleteTeamAssignments,
    )..where((a) => a.athleteId.equals(athleteId))).go();
  }

  Future<List<Athlete>> getAthletesForTeam(
    int teamId, {
    bool includeArchivedAthletes = false,
  }) async {
    final query = select(athletes).join([
      innerJoin(
        athleteTeamAssignments,
        athleteTeamAssignments.athleteId.equalsExp(athletes.id),
      ),
    ]);
    query.where(athleteTeamAssignments.teamId.equals(teamId));
    if (!includeArchivedAthletes) {
      query.where(athletes.isArchived.equals(false));
    }
    query.orderBy([OrderingTerm.asc(athletes.name)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(athletes)).toList();
  }

  Future<List<Athlete>> getAthletesWithoutTeam({
    bool includeArchivedAthletes = false,
  }) async {
    final query = select(athletes).join([
      leftOuterJoin(
        athleteTeamAssignments,
        athleteTeamAssignments.athleteId.equalsExp(athletes.id),
      ),
    ]);
    query.where(athleteTeamAssignments.athleteId.isNull());
    if (!includeArchivedAthletes) {
      query.where(athletes.isArchived.equals(false));
    }
    query.orderBy([OrderingTerm.asc(athletes.name)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(athletes)).toList();
  }
}

String _requiredTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$fieldName cannot be empty.');
  }
  return trimmed;
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
