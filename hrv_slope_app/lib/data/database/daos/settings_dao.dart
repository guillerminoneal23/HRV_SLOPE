import 'package:drift/drift.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/tables/tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings, NomogramModels])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  // ── App Settings ────────────────────────────────────────────────────────

  /// Get a setting by key.
  Future<String?> getSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Set a setting value.
  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: key,
        value: value,
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Get all settings as a map.
  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(appSettings).get();
    return {for (final row in rows) row.key: row.value};
  }

  // ── Nomogram Models ─────────────────────────────────────────────────────

  /// Get the nomogram model for an athlete.
  Future<NomogramModel?> getNomogramModel(int athleteId) {
    return (select(
      nomogramModels,
    )..where((m) => m.athleteId.equals(athleteId))).getSingleOrNull();
  }

  /// Save or update a nomogram model for an athlete.
  Future<void> saveNomogramModel(NomogramModelsCompanion model) async {
    await into(nomogramModels).insertOnConflictUpdate(model);
  }

  /// Delete the nomogram model for an athlete.
  Future<int> deleteNomogramModel(int athleteId) {
    return (delete(
      nomogramModels,
    )..where((m) => m.athleteId.equals(athleteId))).go();
  }
}
