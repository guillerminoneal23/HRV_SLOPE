/// Session Wizard — Step-based manual data entry for HRV Slope sessions.
/// Phase 2.1: Dual HRV input mode (direct RMSSD / RR intervals).
// ignore_for_file: deprecated_member_use

library;

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:hrv_slope_app/core/constants/hrv_constants.dart';
import 'package:hrv_slope_app/core/constants/hrv_sources.dart';
import 'package:hrv_slope_app/core/constants/session_constants.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/services/reusable_tag_service.dart';
import 'package:hrv_slope_app/shared/engine/calculation_preview.dart';
import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/reusable_tag_text_field.dart';
import 'package:hrv_slope_app/ui/widgets/rr_input_widget.dart';

class SessionWizardScreen extends StatefulWidget {
  final AppDatabase? database;

  const SessionWizardScreen({super.key, this.database});

  @override
  State<SessionWizardScreen> createState() => _SessionWizardScreenState();
}

class _SessionWizardScreenState extends State<SessionWizardScreen> {
  late final AppDatabase _db;
  late final bool _ownsDatabase;
  int _step = 0;

  // Step 0: Athlete
  List<Athlete> _athletes = [];
  Athlete? _selectedAthlete;

  // Step 1: Session info
  final _sessionNameCtrl = TextEditingController();
  final _sportCtrl = TextEditingController();
  final _protocolCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _sessionDate = DateTime.now();
  SessionType _sessionType = SessionType.training;
  late final ReusableTagService _tagService;
  Map<ReusableTagCategory, List<ReusableTag>> _tags = {};

  // Step 2: External load
  final Map<String, TextEditingController> _extCtrls = {};

  // Step 3: Internal load
  final Map<String, TextEditingController> _intCtrls = {};

  // Step 4: HRV data — dual mode
  HrvInputMode _hrvMode = HrvInputMode.directRmssd;
  RmssdRecoverySourceType _rmssdRecSource = RmssdRecoverySourceType.manual;
  final _rmssdRecCtrl = TextEditingController();
  final _rmssdExCtrl = TextEditingController();
  final _winStartCtrl = TextEditingController(text: '5');
  final _winEndCtrl = TextEditingController(text: '10');
  // RR-derived results
  RrInputResult? _rrRecResult;
  RrInputResult? _rrExResult;

  // Step 5: Preview
  CalculationPreview? _preview;
  String? _previewError;

  // Nomogram preset
  PopulationNomogramSource _nomogramPreset = kDefaultPopulationNomogramSource;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _db = widget.database ?? AppDatabase();
    _ownsDatabase = widget.database == null;
    _tagService = ReusableTagService(_db.settingsDao);
    _loadAthletes();
    _loadPreset();
    _loadTags();
    for (final v in StandardVariables.externalVariables) {
      _extCtrls[v.name] = TextEditingController();
    }
    for (final v in StandardVariables.internalVariables) {
      _intCtrls[v.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _sessionNameCtrl.dispose();
    _sportCtrl.dispose();
    _protocolCtrl.dispose();
    _contextCtrl.dispose();
    _notesCtrl.dispose();
    _rmssdRecCtrl.dispose();
    _rmssdExCtrl.dispose();
    _winStartCtrl.dispose();
    _winEndCtrl.dispose();
    for (final c in _extCtrls.values) {
      c.dispose();
    }
    for (final c in _intCtrls.values) {
      c.dispose();
    }
    if (_ownsDatabase) {
      _db.close();
    }
    super.dispose();
  }

  Future<void> _loadAthletes() async {
    final list = await _db.athletesDao.getAllAthletes();
    if (mounted) setState(() => _athletes = list);
  }

  Future<void> _loadPreset() async {
    final val = await _db.settingsDao.getSetting('population_nomogram_preset');
    if (mounted) {
      setState(() => _nomogramPreset = parsePopulationNomogramSource(val));
    }
  }

  Future<void> _loadTags() async {
    await _tagService.ensureSystemTags();
    final entries = await Future.wait(
      ReusableTagCategory.values.map((category) async {
        final tags = await _tagService.getTagsByCategory(category);
        return MapEntry(category, tags);
      }),
    );
    if (mounted) {
      setState(() => _tags = Map.fromEntries(entries));
    }
  }

  List<String> _tagOptions(ReusableTagCategory category, String? value) {
    return ReusableTagService.tagNamesIncludingValue(
      _tags[category] ?? const [],
      value,
    );
  }

  Future<void> _saveTag(ReusableTagCategory category, String value) async {
    final tag = await _tagService.addTagIfMissing(category, value);
    if (tag == null) return;
    await _loadTags();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tag.name} saved for future sessions')),
      );
    }
  }

  // ── Helpers ──

  Map<String, double> _collectValues(Map<String, TextEditingController> ctrls) {
    final m = <String, double>{};
    for (final e in ctrls.entries) {
      final v = double.tryParse(e.value.text);
      if (v != null) m[e.key] = v;
    }
    return m;
  }

  List<String> _validateOptionalNumericValues(
    Iterable<VariableDefinition> variables,
    Map<String, TextEditingController> ctrls,
  ) {
    final errs = <String>[];
    for (final variable in variables) {
      final text = ctrls[variable.name]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      if (double.tryParse(text) == null) {
        errs.add('${variable.label} must be a number');
      }
    }
    return errs;
  }

  List<String> _validateStep(int step) {
    final errs = <String>[];
    switch (step) {
      case 0:
        if (_selectedAthlete == null) {
          errs.add('Select an athlete');
        }
      case 1:
        if (_sportCtrl.text.trim().isEmpty) {
          errs.add('Sport is required');
        }
        if (_sessionNameCtrl.text.trim().isEmpty) {
          errs.add('Session name is required');
        }
      case 2:
        errs.addAll(
          _validateOptionalNumericValues(
            StandardVariables.externalVariables,
            _extCtrls,
          ),
        );
      case 3:
        errs.addAll(
          _validateOptionalNumericValues(
            StandardVariables.internalVariables,
            _intCtrls,
          ),
        );
      case 4:
        if (_hrvMode == HrvInputMode.directRmssd) {
          final v = double.tryParse(_rmssdRecCtrl.text);
          if (v == null || v <= 0) {
            errs.add('RMSSD recovery must be > 0');
          }
          final ex = double.tryParse(_rmssdExCtrl.text);
          if (ex != null && ex <= 0) {
            errs.add('RMSSD exercise must be > 0 if provided');
          }
        } else {
          if (_rrRecResult == null) {
            errs.add('Parse recovery RR intervals first');
          }
        }
        if (double.tryParse(_winStartCtrl.text) == null) {
          errs.add('Window start required');
        }
        if (double.tryParse(_winEndCtrl.text) == null) {
          errs.add('Window end required');
        }
        final ws = double.tryParse(_winStartCtrl.text);
        final we = double.tryParse(_winEndCtrl.text);
        if (ws != null && we != null) {
          if (ws < 5) {
            errs.add('Window start must be ≥ 5 min');
          }
          if (we > 30) {
            errs.add('Window end must be ≤ 30 min');
          }
          if ((we - ws - 5).abs() > 0.01) {
            errs.add('Window duration must be 5 min');
          }
        }
    }
    return errs;
  }

  void _next() {
    final errs = _validateStep(_step);
    if (errs.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errs.join('; '))));
      return;
    }
    if (_step == 4) {
      _buildPreview();
    }
    setState(() => _step++);
  }

  void _back() => setState(() => _step--);

  void _buildPreview() {
    try {
      final ext = _collectValues(_extCtrls);
      final int_ = _collectValues(_intCtrls);
      final a = _selectedAthlete!;

      // Build tagged variables
      final extVars = ext.entries.map((e) {
        final def = StandardVariables.externalVariables
            .where((d) => d.name == e.key)
            .firstOrNull;
        return TaggedVariable(
          category: 'external',
          name: e.key,
          unit: def?.unit,
          value: e.value,
          source: 'manual',
        );
      }).toList();

      final intVars = int_.entries.map((e) {
        final def = StandardVariables.internalVariables
            .where((d) => d.name == e.key)
            .firstOrNull;
        return TaggedVariable(
          category: 'internal',
          name: e.key,
          unit: def?.unit,
          value: e.value,
          source: 'manual',
        );
      }).toList();

      // Intensity resolution
      final resolution = resolveIntensityPercent(
        inputs: IntensityInputs(
          percentMas: ext['percent_mas'],
          percentVvo2max: ext['percent_vvo2max'],
          percentMap: ext['percent_map'],
          speedKmh: ext['speed_kmh'],
          powerW: ext['power_w'],
          rpe110: int_['rpe_1_10'],
          subjectiveFatigue110: int_['subjective_fatigue_1_10'],
          percentHrmax: int_['percent_hrmax'],
        ),
        athlete: AthleteReferenceValues(
          masKmh: a.masKmh,
          vvo2maxKmh: a.vvo2maxKmh,
          mapW: a.mapW,
        ),
      );

      // Resolve RMSSD based on input mode
      double rmssdRec;
      double? rmssdEx;
      RmssdSource exSource;
      if (_hrvMode == HrvInputMode.rrIntervals) {
        if (_rrRecResult == null) throw Exception('Recovery RR not parsed');
        rmssdRec = _rrRecResult!.rmssd;
        rmssdEx = _rrExResult?.rmssd;
        exSource = rmssdEx != null
            ? RmssdSource.computedFromRr
            : RmssdSource.fallback4Ms;
      } else {
        rmssdRec = double.parse(_rmssdRecCtrl.text);
        rmssdEx = double.tryParse(_rmssdExCtrl.text);
        exSource = rmssdEx != null
            ? RmssdSource.measured
            : RmssdSource.fallback4Ms;
      }
      final winStart = double.parse(_winStartCtrl.text);
      final winEnd = double.parse(_winEndCtrl.text);

      final dateStr =
          '${_sessionDate.year}-${_sessionDate.month.toString().padLeft(2, '0')}-${_sessionDate.day.toString().padLeft(2, '0')}';

      _preview = buildCalculationPreview(
        athleteName: a.name,
        sessionDate: dateStr,
        sessionName: _sessionNameCtrl.text.trim(),
        sport: _sportCtrl.text.trim(),
        externalVariables: extVars,
        internalVariables: intVars,
        intensityResolution: resolution,
        rmssdExercise: rmssdEx,
        rmssdExerciseSource: exSource,
        rmssdRecovery: rmssdRec,
        hrvInputMode: _hrvMode,
        recoveryRrPreprocessing: _rrRecResult?.preprocessing,
        exerciseRrPreprocessing: _rrExResult?.preprocessing,
        recoveryWindowStartMin: winStart,
        recoveryWindowEndMin: winEnd,
        populationPreset: _nomogramPreset,
      );
      _previewError = null;
    } catch (e) {
      _previewError = e.toString();
      _preview = null;
    }
  }

  Future<void> _save() async {
    if (_preview == null) return;
    setState(() => _saving = true);
    try {
      final p = _preview!;
      final now = DateTime.now().toIso8601String();
      final dateStr = p.sessionDate;

      // Determine HRV metadata
      final hrvModeStr = _hrvMode.value;
      final recSourceStr = _hrvMode == HrvInputMode.rrIntervals
          ? RmssdRecoverySourceType.computedFromRr.value
          : _rmssdRecSource.value;
      final exSourceStr = p.rmssdExerciseSource.name;
      final rrPrep = p.recoveryRrPreprocessing;
      final rrQuality = _hrvMode == HrvInputMode.rrIntervals && rrPrep != null
          ? rrPrep.qualityDecision.name
          : null;
      final rrArtPct = _hrvMode == HrvInputMode.rrIntervals && rrPrep != null
          ? rrPrep.artifactPercent
          : null;

      // Insert session
      final sessionId = await _db.sessionsDao.insertSession(
        SessionsCompanion.insert(
          athleteId: _selectedAthlete!.id,
          date: dateStr,
          taskName: drift.Value(p.sessionName),
          sport: drift.Value(p.sport),
          sessionType: drift.Value(_sessionType.name),
          protocolName: drift.Value(
            _protocolCtrl.text.trim().isEmpty
                ? null
                : _protocolCtrl.text.trim(),
          ),
          contextEnvironment: drift.Value(
            _contextCtrl.text.trim().isEmpty ? null : _contextCtrl.text.trim(),
          ),
          isDraft: const drift.Value(false),
          intensityPercent: drift.Value(p.intensityPercent),
          intensitySource: drift.Value(p.intensityResolution?.method),
          recoveryTimeMin: drift.Value(p.tUsedForSlope),
          recoveryWindowStartMin: drift.Value(p.recoveryWindowStartMin),
          recoveryWindowEndMin: drift.Value(p.recoveryWindowEndMin),
          rmssdExercise: drift.Value(p.rmssdExercise),
          rmssdExerciseIsDefault: drift.Value(p.usedFallbackExercise),
          rmssdRecovery: drift.Value(p.rmssdRecovery),
          slopeRaw: drift.Value(p.rawSlope),
          slopeInterpreted: drift.Value(p.interpretedSlope),
          itlIndex: drift.Value(p.itlIndex),
          classification: drift.Value(p.classification),
          hrvInputMode: drift.Value(hrvModeStr),
          rmssdRecoverySource: drift.Value(recSourceStr),
          rmssdExerciseSource: drift.Value(exSourceStr),
          rrQualityFlag: drift.Value(rrQuality),
          rrArtifactPercent: drift.Value(rrArtPct),
          rrPreprocessingMode: drift.Value(p.rrPreprocessingMode?.name),
          rrCorrectionEnabled: drift.Value(p.correctionEnabled),
          rrCorrectionMethod: drift.Value(p.correctionMethod?.name),
          rrRawRmssd: drift.Value(p.rawRmssd),
          rrCorrectedRmssd: drift.Value(p.correctedRmssd),
          rrRmssdUsed: drift.Value(
            _hrvMode == HrvInputMode.rrIntervals ? p.rmssdUsedForSlope : null,
          ),
          rrArtifactCount: drift.Value(p.artifactCount),
          rrQualityDecision: drift.Value(p.qualityDecision?.name),
          rrQualityNotesJson: drift.Value(
            p.qualityNotes.isEmpty ? null : jsonEncode(p.qualityNotes),
          ),
          rrRmssdDeltaPercent: drift.Value(rrPrep?.rmssdDeltaPercent),
          notes: drift.Value(
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          ),
          createdAt: now,
        ),
      );

      // Insert HRV measurement
      await _db.sessionsDao.insertHrvMeasurement(
        MeasurementsHrvCompanion.insert(
          sessionId: sessionId,
          phase: 'recovery',
          windowStartMin: drift.Value(p.recoveryWindowStartMin),
          windowEndMin: drift.Value(p.recoveryWindowEndMin),
          rmssd: drift.Value(p.rmssdRecovery),
          createdAt: now,
        ),
      );

      // Insert variables
      final vars = <IntensityVariablesCompanion>[];
      for (final v in p.externalVariables) {
        vars.add(
          IntensityVariablesCompanion.insert(
            sessionId: sessionId,
            category: v.category,
            name: v.name,
            unit: drift.Value(v.unit),
            value: v.value,
            source: drift.Value(v.source),
            createdAt: now,
          ),
        );
      }
      for (final v in p.internalVariables) {
        vars.add(
          IntensityVariablesCompanion.insert(
            sessionId: sessionId,
            category: v.category,
            name: v.name,
            unit: drift.Value(v.unit),
            value: v.value,
            source: drift.Value(v.source),
            createdAt: now,
          ),
        );
      }
      // Derived variables
      vars.add(
        IntensityVariablesCompanion.insert(
          sessionId: sessionId,
          category: 'derived',
          name: 'raw_slope',
          value: p.rawSlope,
          source: const drift.Value('calculated'),
          createdAt: now,
        ),
      );
      vars.add(
        IntensityVariablesCompanion.insert(
          sessionId: sessionId,
          category: 'derived',
          name: 'interpreted_slope',
          value: p.interpretedSlope,
          source: const drift.Value('calculated'),
          createdAt: now,
        ),
      );
      vars.add(
        IntensityVariablesCompanion.insert(
          sessionId: sessionId,
          category: 'derived',
          name: 'itl_index',
          value: p.itlIndex,
          source: const drift.Value('calculated'),
          createdAt: now,
        ),
      );
      if (p.intensityPercent != null) {
        vars.add(
          IntensityVariablesCompanion.insert(
            sessionId: sessionId,
            category: 'derived',
            name: 'intensity_percent',
            value: p.intensityPercent!,
            source: drift.Value(p.intensityResolution?.method),
            isPrimaryForNomogram: const drift.Value(true),
            createdAt: now,
          ),
        );
      }
      await _db.sessionsDao.insertVariables(vars);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved successfully')),
        );
        _resetWizard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetWizard() {
    setState(() {
      _step = 0;
      _selectedAthlete = null;
      _sessionNameCtrl.clear();
      _sportCtrl.clear();
      _protocolCtrl.clear();
      _contextCtrl.clear();
      _notesCtrl.clear();
      _rmssdRecCtrl.clear();
      _rmssdExCtrl.clear();
      _winStartCtrl.text = '5';
      _winEndCtrl.text = '10';
      _sessionDate = DateTime.now();
      _sessionType = SessionType.training;
      _hrvMode = HrvInputMode.directRmssd;
      _rmssdRecSource = RmssdRecoverySourceType.manual;
      _rrRecResult = null;
      _rrExResult = null;
      for (final c in _extCtrls.values) {
        c.clear();
      }
      for (final c in _intCtrls.values) {
        c.clear();
      }
      _preview = null;
      _previewError = null;
    });
    _loadAthletes();
  }

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Athlete',
      'Session',
      'External',
      'Internal',
      'HRV',
      'Preview',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('New Session — ${steps[_step]}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / steps.length,
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _buildStep(),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _stepAthlete();
      case 1:
        return _stepSession();
      case 2:
        return _stepExternal();
      case 3:
        return _stepInternal();
      case 4:
        return _stepHrv();
      case 5:
        return _stepPreview();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_step > 0)
              OutlinedButton(onPressed: _back, child: const Text('Back')),
            const Spacer(),
            if (_step < 5)
              ElevatedButton(onPressed: _next, child: const Text('Next')),
            if (_step == 5)
              ElevatedButton(
                onPressed: _saving || _preview == null ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Session'),
              ),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Athlete ──
  Widget _stepAthlete() {
    return ListView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Select Athlete', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_athletes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No athletes. Create one first from the Athletes tab.',
              ),
            ),
          )
        else
          ..._athletes.map(
            (a) => RadioListTile<int>(
              value: a.id,
              groupValue: _selectedAthlete?.id,
              title: Text(a.name),
              subtitle: Text(a.sport ?? ''),
              onChanged: (id) => setState(
                () =>
                    _selectedAthlete = _athletes.firstWhere((x) => x.id == id),
              ),
            ),
          ),
      ],
    );
  }

  // ── Step 1: Session ──
  Widget _stepSession() {
    return ListView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Session Details', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ReusableTagTextField(
          controller: _sessionNameCtrl,
          labelText: 'Session / Task Name *',
          options: _tagOptions(
            ReusableTagCategory.sessionTask,
            _sessionNameCtrl.text,
          ),
          onSaveTag: (value) =>
              _saveTag(ReusableTagCategory.sessionTask, value),
        ),
        const SizedBox(height: 12),
        ReusableTagTextField(
          controller: _sportCtrl,
          labelText: 'Sport *',
          hintText: _selectedAthlete?.sport ?? '',
          options: _tagOptions(
            ReusableTagCategory.sport,
            _sportCtrl.text.isEmpty ? _selectedAthlete?.sport : _sportCtrl.text,
          ),
          onSaveTag: (value) => _saveTag(ReusableTagCategory.sport, value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<SessionType>(
          value: _sessionType,
          decoration: const InputDecoration(labelText: 'Session Type'),
          items: SessionTypeOptions.newSessionOptions
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _sessionType = v);
          },
        ),
        const SizedBox(height: 12),
        ReusableTagTextField(
          controller: _protocolCtrl,
          labelText: 'Protocol name',
          required: false,
          options: _tagOptions(
            ReusableTagCategory.protocol,
            _protocolCtrl.text,
          ),
          onSaveTag: (value) => _saveTag(ReusableTagCategory.protocol, value),
        ),
        const SizedBox(height: 12),
        ReusableTagTextField(
          controller: _contextCtrl,
          labelText: 'Context / environment',
          required: false,
          options: _tagOptions(
            ReusableTagCategory.contextEnvironment,
            _contextCtrl.text,
          ),
          onSaveTag: (value) =>
              _saveTag(ReusableTagCategory.contextEnvironment, value),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(
            '${_sessionDate.year}-${_sessionDate.month.toString().padLeft(2, '0')}-${_sessionDate.day.toString().padLeft(2, '0')}',
          ),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _sessionDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (d != null) setState(() => _sessionDate = d);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesCtrl,
          decoration: const InputDecoration(labelText: 'Notes'),
          maxLines: 2,
        ),
      ],
    );
  }

  // ── Step 2: External Load ──
  Widget _stepExternal() {
    return ListView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'External Load Variables',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Optional but recommended',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          'External intensity is used when available. If it is not recorded, internal intensity such as RPE can be used for slope interpretation.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...StandardVariables.externalVariables.map(
          (v) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              controller: _extCtrls[v.name],
              decoration: InputDecoration(
                labelText: '${v.label} ${v.unit != null ? "(${v.unit})" : ""}',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Internal Load ──
  Widget _stepInternal() {
    return ListView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Internal Load Variables',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Optional but recommended',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          'External intensity is used when available. If it is not recorded, internal intensity such as RPE can be used for slope interpretation.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...StandardVariables.internalVariables.map(
          (v) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              controller: _intCtrls[v.name],
              decoration: InputDecoration(
                labelText:
                    '${v.label} ${v.unit != null && v.unit!.isNotEmpty ? "(${v.unit})" : ""}',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 4: HRV — Dual Mode ──
  Widget _stepHrv() {
    return ListView(
      key: const ValueKey('step4'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'HRV / RMSSD Data',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        // Mode selector
        SegmentedButton<HrvInputMode>(
          segments: [
            ButtonSegment(
              value: HrvInputMode.directRmssd,
              label: const Text('Direct RMSSD'),
              icon: const Icon(Icons.edit, size: 16),
            ),
            ButtonSegment(
              value: HrvInputMode.rrIntervals,
              label: const Text('RR Intervals'),
              icon: const Icon(Icons.timeline, size: 16),
            ),
          ],
          selected: {_hrvMode},
          onSelectionChanged: (s) => setState(() => _hrvMode = s.first),
        ),
        const SizedBox(height: 4),
        Text(
          _hrvMode == HrvInputMode.directRmssd
              ? 'Use this if you already have RMSSD from Elite HRV, Kubios, HRV Logger, Polar, or another app.'
              : 'Use this if you have raw RR intervals in milliseconds and want the app to calculate RMSSD.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        // Mode-specific inputs
        if (_hrvMode == HrvInputMode.directRmssd) ...[
          // Source selector
          DropdownButtonFormField<RmssdRecoverySourceType>(
            value: _rmssdRecSource,
            decoration: const InputDecoration(labelText: 'RMSSD Source'),
            items: RmssdRecoverySourceType.values
                .where(
                  (s) =>
                      s != RmssdRecoverySourceType.computedFromRr &&
                      s != RmssdRecoverySourceType.csvImport,
                )
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _rmssdRecSource = v);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rmssdRecCtrl,
            decoration: const InputDecoration(
              labelText: 'RMSSD Recovery (ms) *',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rmssdExCtrl,
            decoration: const InputDecoration(
              labelText: 'RMSSD Exercise (ms)',
              hintText: 'Leave empty → fallback 4 ms',
            ),
            keyboardType: TextInputType.number,
          ),
          if (_rmssdExCtrl.text.trim().isEmpty) ..._fallbackNotice(),
        ] else ...[
          // RR Intervals mode
          RrInputWidget(
            label: 'Recovery RR (last 5 min of recovery)',
            onResult: (r) => setState(() => _rrRecResult = r),
          ),
          const SizedBox(height: 16),
          RrInputWidget(
            label: 'Exercise RR (last 5 min of exercise) — optional',
            onResult: (r) => setState(() => _rrExResult = r),
          ),
          if (_rrExResult == null) ..._fallbackNotice(),
        ],
        const SizedBox(height: 16),
        Text('Recovery Window', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _winStartCtrl,
                decoration: const InputDecoration(labelText: 'Start (min)'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _winEndCtrl,
                decoration: const InputDecoration(labelText: 'End (min)'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _windowInfoCard(),
      ],
    );
  }

  List<Widget> _fallbackNotice() {
    return [
      const SizedBox(height: 4),
      Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'RMSSD exercise was not provided. The calculation uses the validated $kDefaultRmssdExerciseMs ms fallback.',
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _windowInfoCard() {
    return Card(
      color: AppColors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slope denominator t = recovery_window_end_min',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Window 5–10 → t = 10 · Window 10–15 → t = 15 · Window 25–30 → t = 30',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 4),
            Text(
              'First 5 min excluded. Duration must be 5 min. Max end = 30 min.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 5: Preview ──
  Widget _stepPreview() {
    if (_previewError != null) {
      return ListView(
        key: const ValueKey('step5err'),
        padding: const EdgeInsets.all(16),
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'Calculation Error',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(_previewError!, style: TextStyle(color: AppColors.error)),
        ],
      );
    }
    final p = _preview;
    if (p == null) return const Center(child: Text('No preview available'));

    return ListView(
      key: const ValueKey('step5'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Calculation Preview',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Preset: ${p.populationNomogramPreset}',
          style: TextStyle(fontSize: 12, color: AppColors.secondary),
        ),
        const SizedBox(height: 12),
        _previewCard('Session', [
          _pRow('Athlete', p.athleteName),
          _pRow('Date', p.sessionDate),
          _pRow('Session', p.sessionName ?? '-'),
          _pRow('Sport', p.sport ?? '-'),
          _pRow(
            'Protocol',
            _protocolCtrl.text.trim().isEmpty ? '-' : _protocolCtrl.text.trim(),
          ),
          _pRow(
            'Context',
            _contextCtrl.text.trim().isEmpty ? '-' : _contextCtrl.text.trim(),
          ),
        ]),
        _previewCard('External Variables', [
          for (final v in p.externalVariables)
            _pRow(v.name, '${v.value} ${v.unit ?? ""}'),
          if (p.externalVariables.isEmpty) _pRow('-', 'none'),
        ]),
        _previewCard('Internal Variables', [
          for (final v in p.internalVariables)
            _pRow(v.name, '${v.value} ${v.unit ?? ""}'),
          if (p.internalVariables.isEmpty) _pRow('-', 'none'),
        ]),
        _previewCard('Intensity', [
          _pRow(
            'Intensity %',
            p.intensityPercent?.toStringAsFixed(1) ?? 'NOT RESOLVED',
          ),
          _pRow('Method', p.intensityResolution?.method ?? '-'),
          _pRow('Source', p.intensitySourceForSlope.label),
          _pRow('Primary metric', p.primaryIntensityMetric ?? '-'),
          _pRow(
            'Internal fallback',
            p.usedInternalIntensityFallback ? 'yes' : 'no',
          ),
        ]),
        _previewCard('HRV / RMSSD', [
          _pRow('Input mode', p.hrvInputMode.value),
          if (p.hrvInputMode == HrvInputMode.rrIntervals) ...[
            _pRow('RR preprocessing', p.rrPreprocessingMode?.name ?? '-'),
            _pRow('Correction enabled', p.correctionEnabled ? 'yes' : 'no'),
            _pRow('Correction method', p.correctionMethod?.name ?? '-'),
            _pRow('Raw RMSSD', '${p.rawRmssd?.toStringAsFixed(2)} ms'),
            _pRow(
              'Corrected RMSSD',
              p.correctedRmssd == null
                  ? '-'
                  : '${p.correctedRmssd!.toStringAsFixed(2)} ms',
            ),
            _pRow(
              'RMSSD used for slope',
              '${p.rmssdUsedForSlope.toStringAsFixed(2)} ms',
            ),
            _pRow('Artifact count', '${p.artifactCount ?? 0}'),
            _pRow(
              'Artifact %',
              '${(p.artifactPercent ?? 0).toStringAsFixed(2)}%',
            ),
            _pRow('Quality decision', p.qualityDecision?.name ?? '-'),
          ],
          _pRow('RMSSD exercise', '${p.rmssdExercise?.toStringAsFixed(2)} ms'),
          _pRow('Source', p.rmssdExerciseSource.name),
          if (p.usedFallbackExercise)
            _pRow('⚠ Fallback', '$kDefaultRmssdExerciseMs ms used'),
          _pRow('RMSSD recovery', '${p.rmssdRecovery.toStringAsFixed(2)} ms'),
        ]),
        _previewCard('Recovery Window', [
          _pRow('Start', '${p.recoveryWindowStartMin} min'),
          _pRow('End', '${p.recoveryWindowEndMin} min'),
          _pRow('Duration', '${p.recoveryWindowDurationMin} min'),
          _pRow('t (slope denom.)', '${p.tUsedForSlope} min'),
        ]),
        _previewCard('Slope Results', [
          _pRow('Raw slope', p.rawSlope.toStringAsFixed(4)),
          _pRow('Interpreted slope', p.interpretedSlope.toStringAsFixed(4)),
          _pRow('ITL index (1/slope)', p.itlIndex.toStringAsFixed(4)),
        ]),
        if (p.canClassify)
          _previewCard('Nomogram Classification', [
            _pRow('Expected lower', p.expectedLower!.toStringAsFixed(3)),
            _pRow('Expected mean', p.expectedMean!.toStringAsFixed(3)),
            _pRow('Expected upper', p.expectedUpper!.toStringAsFixed(3)),
            _pRow('Classification', p.classification ?? '-'),
            _pRow('Residual', p.residual!.toStringAsFixed(3)),
            _pRow('Residual %', '${p.residualPercent!.toStringAsFixed(1)}%'),
          ])
        else
          _previewCard('Nomogram Classification', [
            _pRow('Status', 'Cannot classify — intensity % missing'),
          ]),
        if (p.warnings.isNotEmpty)
          _previewCard('Warnings', [for (final w in p.warnings) _pRow('⚠', w)]),
      ],
    );
  }

  Widget _previewCard(String title, List<Widget> rows) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _pRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
