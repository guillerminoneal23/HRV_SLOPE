import 'package:drift/drift.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/data/database/tables/tables.dart';

part 'session_events_dao.g.dart';

class SessionEventDetailBundle {
  final SessionEvent event;
  final Team? team;
  final List<SessionDetail> sessionDetails;

  const SessionEventDetailBundle({
    required this.event,
    required this.team,
    required this.sessionDetails,
  });

  int get participantCount => sessionDetails.length;
}

class SessionEventListItem {
  final SessionEvent event;
  final int participantCount;

  const SessionEventListItem({
    required this.event,
    required this.participantCount,
  });
}

@DriftAccessor(tables: [SessionEvents, Sessions])
class SessionEventsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionEventsDaoMixin {
  SessionEventsDao(super.db);

  Future<int> createEvent(SessionEventsCompanion event) {
    return into(sessionEvents).insert(event);
  }

  Future<SessionEvent?> getEventById(int id) {
    return (select(
      sessionEvents,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Future<List<SessionEvent>> getEventsForTeam(int teamId) {
    return (select(sessionEvents)
          ..where((e) => e.teamId.equals(teamId))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .get();
  }

  Future<List<SessionEvent>> getEventsInDateRange({
    String? dateFrom,
    String? dateTo,
    int? teamId,
  }) {
    final query = select(sessionEvents);
    if (teamId != null) {
      query.where((e) => e.teamId.equals(teamId));
    }
    if (dateFrom != null) {
      query.where((e) => e.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null) {
      query.where((e) => e.date.isSmallerOrEqualValue(dateTo));
    }
    query.orderBy([(e) => OrderingTerm.desc(e.date)]);
    return query.get();
  }

  Future<List<Session>> getSessionsForEvent(int eventId) {
    return (select(sessions)
          ..where((s) => s.eventId.equals(eventId))
          ..orderBy([(s) => OrderingTerm.asc(s.athleteId)]))
        .get();
  }

  Future<SessionEventDetailBundle?> getEventDetailBundle(int eventId) async {
    final event = await getEventById(eventId);
    if (event == null) return null;

    final team = event.teamId == null
        ? null
        : await (select(
            db.teams,
          )..where((t) => t.id.equals(event.teamId!))).getSingleOrNull();

    final eventSessions = await getSessionsForEvent(eventId);
    if (eventSessions.isEmpty) {
      return SessionEventDetailBundle(
        event: event,
        team: team,
        sessionDetails: const [],
      );
    }

    final sessionIds = eventSessions.map((session) => session.id).toList();
    final athleteIds = eventSessions
        .map((session) => session.athleteId)
        .toSet()
        .toList();

    final eventAthletes = await (select(
      db.athletes,
    )..where((a) => a.id.isIn(athleteIds))).get();
    final eventVariables =
        await (select(db.intensityVariables)
              ..where((v) => v.sessionId.isIn(sessionIds))
              ..orderBy([
                (v) => OrderingTerm.asc(v.sessionId),
                (v) => OrderingTerm.asc(v.category),
              ]))
            .get();
    final eventHrvMeasurements =
        await (select(db.measurementsHrv)
              ..where((m) => m.sessionId.isIn(sessionIds))
              ..orderBy([(m) => OrderingTerm.asc(m.sessionId)]))
            .get();
    final eventNotes =
        await (select(db.exclusionsOrNotes)
              ..where((n) => n.sessionId.isIn(sessionIds))
              ..orderBy([(n) => OrderingTerm.asc(n.sessionId)]))
            .get();

    final athletesById = {
      for (final athlete in eventAthletes) athlete.id: athlete,
    };
    final variablesBySession = _groupVariablesBySessionId(eventVariables);
    final hrvBySession = _groupHrvBySessionId(eventHrvMeasurements);
    final notesBySession = _groupNotesBySessionId(eventNotes);

    final details = <SessionDetail>[];
    for (final session in eventSessions) {
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

    return SessionEventDetailBundle(
      event: event,
      team: team,
      sessionDetails: details,
    );
  }

  Future<List<SessionEventListItem>> getRecentEventsForTeamWithCounts(
    int teamId, {
    int limit = 5,
  }) async {
    final events =
        await (select(sessionEvents)
              ..where((e) => e.teamId.equals(teamId))
              ..orderBy([(e) => OrderingTerm.desc(e.date)])
              ..limit(limit))
            .get();
    if (events.isEmpty) return const [];

    final eventIds = events.map((event) => event.id).toList();
    final linkedSessions = await (select(
      sessions,
    )..where((s) => s.eventId.isIn(eventIds))).get();
    final countsByEvent = <int, int>{};
    for (final session in linkedSessions) {
      final eventId = session.eventId;
      if (eventId == null) continue;
      countsByEvent[eventId] = (countsByEvent[eventId] ?? 0) + 1;
    }

    return [
      for (final event in events)
        SessionEventListItem(
          event: event,
          participantCount: countsByEvent[event.id] ?? 0,
        ),
    ];
  }

  Future<List<SessionDetail>> getSessionDetailsForEvent(int eventId) async {
    final bundle = await getEventDetailBundle(eventId);
    return bundle?.sessionDetails ?? const [];
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
