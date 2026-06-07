import 'package:hrv_slope_app/data/database/daos/settings_dao.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';

class NomogramModePreferenceService {
  final SettingsDao settingsDao;

  const NomogramModePreferenceService(this.settingsDao);

  static String keyForAthlete(int athleteId) =>
      'nomogram_mode_athlete_$athleteId';

  Future<NomogramMode> load(int athleteId) async {
    final value = await settingsDao.getSetting(keyForAthlete(athleteId));
    return parseNomogramMode(value);
  }

  Future<void> save(int athleteId, NomogramMode mode) {
    return settingsDao.setSetting(keyForAthlete(athleteId), mode.key);
  }
}
