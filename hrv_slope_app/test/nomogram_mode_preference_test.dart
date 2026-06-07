import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/services/nomogram_mode_preference_service.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';

void main() {
  group('NomogramModePreferenceService', () {
    late AppDatabase db;
    late NomogramModePreferenceService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = NomogramModePreferenceService(db.settingsDao);
    });

    tearDown(() async {
      await db.close();
    });

    test('defaults to study mode when no preference exists', () async {
      expect(await service.load(7), NomogramMode.population);
    });

    test('saves modes independently per athlete', () async {
      await service.save(7, NomogramMode.hybrid);
      await service.save(8, NomogramMode.individual);

      expect(await service.load(7), NomogramMode.hybrid);
      expect(await service.load(8), NomogramMode.individual);
    });

    test('invalid stored value falls back to study mode', () async {
      await db.settingsDao.setSetting(
        NomogramModePreferenceService.keyForAthlete(7),
        'invalid-mode',
      );

      expect(await service.load(7), NomogramMode.population);
    });
  });
}
