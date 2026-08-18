import 'package:drift/drift.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/data/database/tables/tables.dart';

part 'session_events_dao.g.dart';

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

  Future<List<SessionDetail>> getSessionDetailsForEvent(int eventId) async {
    final eventSessions = await getSessionsForEvent(eventId);
    final details = <SessionDetail>[];
    for (final session in eventSessions) {
      final detail = await db.sessionsDao.getSessionDetail(session.id);
      if (detail != null) details.add(detail);
    }
    return details;
  }
}
