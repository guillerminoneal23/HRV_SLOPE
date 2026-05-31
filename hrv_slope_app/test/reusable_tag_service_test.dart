import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/core/constants/session_constants.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/services/reusable_tag_service.dart';

void main() {
  group('ReusableTagService', () {
    late AppDatabase db;
    late ReusableTagService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = ReusableTagService(db.settingsDao);
    });

    tearDown(() async {
      await db.close();
    });

    test('" HIIT " and "hiit" do not create duplicates', () async {
      await service.addTagIfMissing(ReusableTagCategory.sessionTask, ' HIIT ');
      await service.addTagIfMissing(ReusableTagCategory.sessionTask, 'hiit');

      final tags = await service.getTagsByCategory(
        ReusableTagCategory.sessionTask,
      );
      final matches = tags.where((tag) => tag.normalizedName == 'hiit');

      expect(matches, hasLength(1));
      expect(matches.single.name, 'HIIT');
    });

    test('creates a new SessionTask tag', () async {
      final tag = await service.addTagIfMissing(
        ReusableTagCategory.sessionTask,
        'Tempo Run',
      );

      expect(tag!.name, 'Tempo Run');
      expect(
        await service.containsTag(
          ReusableTagCategory.sessionTask,
          ' tempo  run ',
        ),
        isTrue,
      );
    });

    test('creates a new Sport tag', () async {
      await service.addTagIfMissing(ReusableTagCategory.sport, 'Cycling');

      final tags = await service.getTagsByCategory(ReusableTagCategory.sport);
      expect(tags.map((tag) => tag.name), contains('Cycling'));
    });

    test('creates a new Protocol tag', () async {
      await service.addTagIfMissing(ReusableTagCategory.protocol, '5-10');

      final tags = await service.getTagsByCategory(
        ReusableTagCategory.protocol,
      );
      expect(tags.map((tag) => tag.name), contains('5-10'));
    });

    test('creates a new ContextEnvironment tag', () async {
      await service.addTagIfMissing(
        ReusableTagCategory.contextEnvironment,
        'Indoor',
      );

      final tags = await service.getTagsByCategory(
        ReusableTagCategory.contextEnvironment,
      );
      expect(tags.map((tag) => tag.name), contains('Indoor'));
    });

    test('system task tags include the new training/test options', () async {
      final tags = await service.getTagsByCategory(
        ReusableTagCategory.sessionTask,
      );
      final names = tags.map((tag) => tag.name).toSet();

      expect(names, containsAll(['SIT', 'HIIT', 'RSA']));
      expect(names, contains('Intermittent Test'));
      expect(names, contains('Strength Training'));
    });

    test('new session options do not include legacy labels', () {
      final labels = SessionTypeOptions.newSessionOptions
          .map((type) => type.label)
          .toSet();

      expect(labels, isNot(contains('Group Session')));
      expect(labels, isNot(contains('Post-match Recovery')));
      expect(labels, isNot(contains('Post Match Recovery')));
    });

    test('legacy values can still be represented for historical sessions', () {
      expect(SessionType.fromString('groupSession'), SessionType.groupSession);
      expect(
        SessionType.fromString('Post-match Recovery'),
        SessionType.postMatchRecovery,
      );

      final names = ReusableTagService.tagNamesIncludingValue(
        const [],
        'Group Session',
      );
      expect(names, contains('Group Session'));
    });

    test('saving a tag does not modify existing sessions', () async {
      final athleteId = await db.athletesDao.insertAthlete(
        AthletesCompanion.insert(
          name: 'Runner One',
          sport: const drift.Value('Running'),
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      final sessionId = await db.sessionsDao.insertSession(
        SessionsCompanion.insert(
          athleteId: athleteId,
          date: '2026-05-31',
          taskName: const drift.Value('Group Session'),
          sport: const drift.Value('Running'),
          sessionType: const drift.Value('groupSession'),
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      await service.addTagIfMissing(ReusableTagCategory.sessionTask, 'HIIT');

      final session = await db.sessionsDao.getSessionById(sessionId);
      expect(session!.taskName, 'Group Session');
      expect(session.sessionType, 'groupSession');
      expect(session.sport, 'Running');
    });
  });
}
