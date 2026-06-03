/// Settings Screen — Population nomogram preset selection.
// ignore_for_file: deprecated_member_use

library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppDatabase _db;
  PopulationNomogramSource _preset = kDefaultPopulationNomogramSource;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    _load();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> _load() async {
    final val = await _db.settingsDao.getSetting('population_nomogram_preset');
    if (mounted) {
      setState(() {
        _preset = parsePopulationNomogramSource(val);
        _loading = false;
      });
    }
  }

  Future<void> _setPreset(PopulationNomogramSource source) async {
    await _db.settingsDao.setSetting(
      'population_nomogram_preset',
      source.presetName,
    );
    setState(() => _preset = source);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nomogram preset set to ${source.presetName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Population Nomogram Preset',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Active in calculation preview and recovery-response interpretation.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                RadioListTile<PopulationNomogramSource>(
                  value: PopulationNomogramSource.excelOperational,
                  groupValue: _preset,
                  title: const Text('excel_operational'),
                  subtitle: const Text(
                    'Operational preset from the reference Excel workbook.\nIntensity anchors: 60%, 80%, 100%.',
                  ),
                  onChanged: (v) {
                    if (v != null) _setPreset(v);
                  },
                ),
                RadioListTile<PopulationNomogramSource>(
                  value: PopulationNomogramSource.slopeOrellana19,
                  groupValue: _preset,
                  title: const Text('slope_Orellana_19'),
                  subtitle: const Text(
                    'Original 2019 paper values from Naranjo Orellana et al.\nIntensity anchors: 64.39%, 83.11%, 100%.',
                  ),
                  onChanged: (v) {
                    if (v != null) _setPreset(v);
                  },
                ),
                const SizedBox(height: 24),
                Card(
                  color: AppColors.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Current Preset',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _preset.presetName,
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text('About', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  'HRV Slope App v0.2.0 — Phase 2\n'
                  'Internal Training Load Monitor based on RMSSD-Slope\n'
                  'Reference: Naranjo Orellana et al. (2019)\n'
                  'Local-only · No cloud · No telemetry',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
    );
  }
}
