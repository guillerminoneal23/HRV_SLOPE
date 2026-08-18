import 'package:flutter/material.dart';
import 'package:hrv_slope_app/core/constants/session_constants.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/services/multi_session_entry_validation_service.dart';
import 'package:hrv_slope_app/data/services/multi_session_save_service.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class MultiSessionEntryScreen extends StatefulWidget {
  final AppDatabase? database;

  const MultiSessionEntryScreen({super.key, this.database});

  @override
  State<MultiSessionEntryScreen> createState() =>
      _MultiSessionEntryScreenState();
}

class _MultiSessionEntryScreenState extends State<MultiSessionEntryScreen> {
  late final AppDatabase _db;
  late final bool _ownsDatabase;
  final _validationService = const MultiSessionEntryValidationService();

  final _sportCtrl = TextEditingController();
  final _taskCtrl = TextEditingController();
  final _protocolCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  final _windowStartCtrl = TextEditingController(text: '5');
  final _windowEndCtrl = TextEditingController(text: '10');
  final _loadUnitCtrl = TextEditingController(text: '%');

  DateTime _dateTime = DateTime.now();
  String _loadType = 'external';
  String _loadMetricName = StandardVariables.percentMas.name;
  SessionType _sessionType = SessionType.training;
  PopulationNomogramSource _nomogramPreset =
      PopulationNomogramSource.excelOperational;

  List<Team> _activeTeams = [];
  List<Athlete> _activeAthletes = [];
  final Map<int, AthleteTeamAssignment> _assignmentsByAthlete = {};
  final Map<int, Team> _teamsById = {};
  final List<_MultiSessionUiRow> _rows = [];
  int? _selectedTeamId;
  int? _selectedAthleteToAdd;
  int _nextRowId = 1;
  bool _loading = true;
  bool _saving = false;
  bool _showValidation = false;
  String? _teamLoadMessage;

  @override
  void initState() {
    super.initState();
    _db = widget.database ?? AppDatabase();
    _ownsDatabase = widget.database == null;
    for (final controller in [
      _sportCtrl,
      _taskCtrl,
      _protocolCtrl,
      _contextCtrl,
      _windowStartCtrl,
      _windowEndCtrl,
      _loadUnitCtrl,
    ]) {
      controller.addListener(_markChanged);
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _sportCtrl.dispose();
    _taskCtrl.dispose();
    _protocolCtrl.dispose();
    _contextCtrl.dispose();
    _windowStartCtrl.dispose();
    _windowEndCtrl.dispose();
    _loadUnitCtrl.dispose();
    if (_ownsDatabase) _db.close();
    super.dispose();
  }

  void _markChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInitialData() async {
    final teams = await _db.teamsDao.getActiveTeams();
    final allTeams = await _db.teamsDao.getAllTeams(includeArchived: true);
    final athletes = await _db.athletesDao.getAllAthletes();
    final assignments = await _db.teamsDao.getAllAssignments();
    final preset = await _db.settingsDao.getSetting(
      'population_nomogram_preset',
    );
    if (!mounted) return;
    setState(() {
      _activeTeams = teams;
      _activeAthletes = athletes
          .where((athlete) => !athlete.isArchived)
          .toList(growable: false);
      _teamsById
        ..clear()
        ..addEntries(allTeams.map((team) => MapEntry(team.id, team)));
      _assignmentsByAthlete
        ..clear()
        ..addEntries(assignments.map((item) => MapEntry(item.athleteId, item)));
      _nomogramPreset = parsePopulationNomogramSource(preset);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = _evaluation();
    return Scaffold(
      appBar: AppBar(title: const Text('Multiple / Team Entry')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderCard(child: _buildHeader(evaluation)),
                        const SizedBox(height: 12),
                        _buildToolbar(evaluation),
                        const SizedBox(height: 12),
                        _buildValidationSummary(evaluation),
                        const SizedBox(height: 12),
                        _buildTable(evaluation),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(evaluation),
              ],
            ),
    );
  }

  Widget _buildHeader(MultiSessionTableEvaluation evaluation) {
    final metrics = _loadVariables;
    final selectedMetric = metrics.any((item) => item.name == _loadMetricName)
        ? _loadMetricName
        : metrics.first.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<int?>(
                key: const Key('multi_team_dropdown'),
                initialValue: _selectedTeamId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Team',
                  prefixIcon: Icon(Icons.groups),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('No team'),
                  ),
                  ..._activeTeams.map(
                    (team) => DropdownMenuItem<int?>(
                      value: team.id,
                      child: Text(team.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (teamId) => _selectTeam(teamId),
              ),
            ),
            SizedBox(
              width: 240,
              child: ListTile(
                key: const Key('multi_date_time_picker'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(_formatDateTime(_dateTime)),
                subtitle: const Text('Date / time'),
                onTap: _pickDateTime,
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<SessionType>(
                key: const Key('multi_session_type'),
                initialValue: _sessionType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Session type'),
                items: SessionTypeOptions.newSessionOptions
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _sessionType = value);
                },
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                key: const Key('multi_sport'),
                controller: _sportCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sport *',
                  prefixIcon: Icon(Icons.sports),
                ),
              ),
            ),
            SizedBox(
              width: 260,
              child: TextField(
                key: const Key('multi_task'),
                controller: _taskCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task *',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                key: const Key('multi_protocol'),
                controller: _protocolCtrl,
                decoration: const InputDecoration(
                  labelText: 'Protocol',
                  prefixIcon: Icon(Icons.rule),
                ),
              ),
            ),
            SizedBox(
              width: 260,
              child: TextField(
                key: const Key('multi_context'),
                controller: _contextCtrl,
                decoration: const InputDecoration(
                  labelText: 'Context',
                  prefixIcon: Icon(Icons.place),
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                key: const Key('multi_window_start'),
                controller: _windowStartCtrl,
                decoration: const InputDecoration(labelText: 'Start min'),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                key: const Key('multi_window_end'),
                controller: _windowEndCtrl,
                decoration: const InputDecoration(labelText: 'End min'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<String>(
              key: const Key('multi_load_type'),
              segments: const [
                ButtonSegment(
                  value: 'external',
                  icon: Icon(Icons.speed, size: 18),
                  label: Text('External'),
                ),
                ButtonSegment(
                  value: 'internal',
                  icon: Icon(Icons.monitor_heart_outlined, size: 18),
                  label: Text('Internal'),
                ),
              ],
              selected: {_loadType},
              onSelectionChanged: (value) => _setLoadType(value.first),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                key: const Key('multi_load_metric'),
                initialValue: selectedMetric,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Load metric'),
                items: metrics
                    .map(
                      (metric) => DropdownMenuItem(
                        value: metric.name,
                        child: Text(
                          '${metric.label}'
                          '${metric.unit == null || metric.unit!.isEmpty ? '' : ' (${metric.unit})'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final definition = _definitionFor(_loadType, value);
                  setState(() {
                    _loadMetricName = value;
                    _loadUnitCtrl.text = definition?.unit ?? '';
                  });
                },
              ),
            ),
            SizedBox(
              width: 150,
              child: TextField(
                key: const Key('multi_load_unit'),
                controller: _loadUnitCtrl,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
            ),
          ],
        ),
        if (_teamLoadMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _teamLoadMessage!,
            style: const TextStyle(color: AppColors.secondary, fontSize: 13),
          ),
        ],
        if (_showValidation && evaluation.headerErrors.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ErrorPanel(errors: evaluation.headerErrors),
        ],
      ],
    );
  }

  Widget _buildToolbar(MultiSessionTableEvaluation evaluation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 340,
              child: DropdownButtonFormField<int>(
                key: const Key('multi_add_athlete_dropdown'),
                initialValue: _selectedAthleteToAdd,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Add athlete',
                  prefixIcon: Icon(Icons.person_add_alt),
                ),
                items: _activeAthletes
                    .map(
                      (athlete) => DropdownMenuItem(
                        value: athlete.id,
                        child: Text(
                          _athleteOptionLabel(athlete),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedAthleteToAdd = value);
                },
              ),
            ),
            ElevatedButton.icon(
              key: const Key('multi_add_athlete_button'),
              onPressed: _selectedAthleteToAdd == null
                  ? null
                  : () {
                      final athlete = _activeAthletes.firstWhere(
                        (item) => item.id == _selectedAthleteToAdd,
                      );
                      _addRow(athlete);
                      setState(() => _selectedAthleteToAdd = null);
                    },
              icon: const Icon(Icons.add),
              label: const Text('Add row'),
            ),
            OutlinedButton.icon(
              key: const Key('multi_load_team_players'),
              onPressed: _selectedTeamId == null
                  ? null
                  : () => _loadPlayersForSelectedTeam(),
              icon: const Icon(Icons.group_add),
              label: const Text('Load team players'),
            ),
            _SummaryPill(
              text:
                  '${evaluation.rowCount} players  |  '
                  '${evaluation.validCount} valid  |  '
                  '${evaluation.errorCount} errors',
              hasError: evaluation.errorCount > 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationSummary(MultiSessionTableEvaluation evaluation) {
    final shouldShow =
        _showValidation ||
        evaluation.errorCount > 0 ||
        evaluation.validCount > 0 ||
        evaluation.omittedCount > 0;
    if (!shouldShow) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusChip(
              icon: Icons.people,
              text: '${evaluation.rowCount} players',
              color: AppColors.primary,
            ),
            _StatusChip(
              icon: Icons.check_circle,
              text: '${evaluation.validCount} valid',
              color: AppColors.success,
            ),
            _StatusChip(
              icon: Icons.error_outline,
              text: '${evaluation.errorCount} with errors',
              color: evaluation.errorCount == 0
                  ? AppColors.textSecondary
                  : AppColors.error,
            ),
            _StatusChip(
              icon: Icons.remove_circle_outline,
              text: '${evaluation.omittedCount} omitted',
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(MultiSessionTableEvaluation evaluation) {
    if (_rows.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Select a team or add athletes to start entering data.'),
        ),
      );
    }
    final evaluationsByRow = {
      for (final item in evaluation.rows) item.localId: item,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 82,
              columns: const [
                DataColumn(label: Text('Athlete')),
                DataColumn(label: Text('RMSSD exercise')),
                DataColumn(label: Text('RMSSD recovery')),
                DataColumn(label: Text('Load')),
                DataColumn(label: Text('RMSSD-Slope')),
                DataColumn(label: Text('Status')),
              ],
              rows: _rows.map((row) {
                final rowEvaluation = evaluationsByRow[row.localId];
                return DataRow(
                  color: WidgetStateProperty.resolveWith(
                    (_) => rowEvaluation?.isInvalid == true
                        ? AppColors.error.withValues(alpha: 0.08)
                        : null,
                  ),
                  cells: [
                    DataCell(_athleteCell(row, rowEvaluation)),
                    DataCell(
                      _numberCell(
                        key: Key('multi_row_${row.localId}_exercise'),
                        controller: row.rmssdExerciseCtrl,
                        error: rowEvaluation
                            ?.fieldErrors[MultiSessionField.rmssdExercise],
                        suffix:
                            rowEvaluation?.usesExerciseFallback == true &&
                                rowEvaluation?.isValid == true
                            ? '4.0 default'
                            : null,
                      ),
                    ),
                    DataCell(
                      _numberCell(
                        key: Key('multi_row_${row.localId}_recovery'),
                        controller: row.rmssdRecoveryCtrl,
                        error: rowEvaluation
                            ?.fieldErrors[MultiSessionField.rmssdRecovery],
                      ),
                    ),
                    DataCell(
                      _numberCell(
                        key: Key('multi_row_${row.localId}_load'),
                        controller: row.loadCtrl,
                        error:
                            rowEvaluation?.fieldErrors[MultiSessionField.load],
                      ),
                    ),
                    DataCell(_slopeCell(rowEvaluation)),
                    DataCell(_statusCell(rowEvaluation)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(MultiSessionTableEvaluation evaluation) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                evaluation.canSave
                    ? '${evaluation.validCount} sessions ready'
                    : 'Fix validation errors before saving',
                style: TextStyle(
                  color: evaluation.canSave
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('multi_validate_button'),
              onPressed: () => setState(() => _showValidation = true),
              icon: const Icon(Icons.fact_check),
              label: const Text('Validate'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              key: const Key('multi_save_button'),
              onPressed: _saving ? null : () => _save(evaluation),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save event'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _athleteCell(
    _MultiSessionUiRow row,
    MultiSessionRowEvaluation? evaluation,
  ) {
    return SizedBox(
      width: 240,
      child: Row(
        children: [
          IconButton(
            key: Key('multi_row_${row.localId}_remove'),
            tooltip: 'Remove from this entry',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _removeRow(row),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.athlete.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'ID ${row.athlete.id}',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
                if (evaluation?.fieldErrors[MultiSessionField.athlete] != null)
                  Text(
                    evaluation!.fieldErrors[MultiSessionField.athlete]!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberCell({
    required Key key,
    required TextEditingController controller,
    String? error,
    String? suffix,
  }) {
    return SizedBox(
      width: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: key,
            controller: controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              isDense: true,
              errorText: _showValidation ? error : null,
              suffixIcon: suffix == null
                  ? null
                  : Tooltip(
                      message: 'Missing exercise RMSSD uses fallback 4.0 ms',
                      child: const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.warning,
                      ),
                    ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                suffix,
                style: const TextStyle(color: AppColors.warning, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slopeCell(MultiSessionRowEvaluation? evaluation) {
    final preview = evaluation?.preview;
    return SizedBox(
      width: 120,
      child: Text(
        preview == null ? '-' : preview.interpretedSlope.toStringAsFixed(3),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statusCell(MultiSessionRowEvaluation? evaluation) {
    if (evaluation == null) {
      return const SizedBox(width: 220, child: Text('-'));
    }
    final color = evaluation.isValid
        ? AppColors.success
        : evaluation.isInvalid
        ? AppColors.error
        : AppColors.textSecondary;
    return SizedBox(
      width: 260,
      child: Row(
        children: [
          Icon(
            evaluation.isValid
                ? Icons.check_circle
                : evaluation.isInvalid
                ? Icons.error_outline
                : Icons.remove_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              evaluation.statusLabel,
              style: TextStyle(color: color, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  MultiSessionTableEvaluation _evaluation() {
    return _validationService.evaluate(
      header: _header(),
      rows: _rows
          .map(
            (row) => MultiSessionDraftRow(
              localId: row.localId,
              athlete: row.athlete,
              rmssdExerciseText: row.rmssdExerciseCtrl.text,
              rmssdRecoveryText: row.rmssdRecoveryCtrl.text,
              loadText: row.loadCtrl.text,
            ),
          )
          .toList(growable: false),
      populationPreset: _nomogramPreset,
    );
  }

  MultiSessionEntryHeader _header() {
    return MultiSessionEntryHeader(
      teamId: _selectedTeamId,
      date: _dateTime.toIso8601String(),
      taskName: _taskCtrl.text,
      sport: _sportCtrl.text,
      sessionType: _sessionType.name,
      protocolName: _protocolCtrl.text,
      contextEnvironment: _contextCtrl.text,
      recoveryWindowStartMin: _parseDouble(_windowStartCtrl.text),
      recoveryWindowEndMin: _parseDouble(_windowEndCtrl.text),
      loadType: _loadType,
      loadMetricName: _loadMetricName,
      loadUnit: _loadUnitCtrl.text,
    );
  }

  Future<void> _selectTeam(int? teamId) async {
    setState(() {
      _selectedTeamId = teamId;
      _teamLoadMessage = null;
    });
    if (teamId == null) return;
    final team = _activeTeams.firstWhere((item) => item.id == teamId);
    if (team.sport != null && _sportCtrl.text.trim().isEmpty) {
      _sportCtrl.text = team.sport!;
    }
    await _loadPlayersForSelectedTeam();
  }

  Future<void> _loadPlayersForSelectedTeam() async {
    final teamId = _selectedTeamId;
    if (teamId == null) return;
    final team = _activeTeams.firstWhere((item) => item.id == teamId);
    if (team.isArchived) {
      setState(() => _teamLoadMessage = 'Archived teams cannot be used.');
      return;
    }
    final athletes = await _db.teamsDao.getAthletesForTeam(teamId);
    var added = 0;
    for (final athlete in athletes) {
      if (_rows.any((row) => row.athlete.id == athlete.id)) continue;
      _rows.add(_createRow(athlete));
      added++;
    }
    if (!mounted) return;
    setState(() {
      _teamLoadMessage =
          '$added players added from ${team.name} (${athletes.length} available).';
    });
  }

  void _addRow(Athlete athlete) {
    setState(() {
      _rows.add(_createRow(athlete));
      _showValidation = true;
    });
  }

  _MultiSessionUiRow _createRow(Athlete athlete) {
    final row = _MultiSessionUiRow(localId: _nextRowId++, athlete: athlete);
    row.addListener(_markChanged);
    return row;
  }

  void _removeRow(_MultiSessionUiRow row) {
    setState(() {
      _rows.remove(row);
      row.dispose();
    });
  }

  void _setLoadType(String loadType) {
    final defaultMetric = loadType == 'external'
        ? StandardVariables.percentMas
        : StandardVariables.rpe110;
    setState(() {
      _loadType = loadType;
      _loadMetricName = defaultMetric.name;
      _loadUnitCtrl.text = defaultMetric.unit ?? '';
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (!mounted) return;
    setState(() {
      _dateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _dateTime.hour,
        pickedTime?.minute ?? _dateTime.minute,
      );
    });
  }

  Future<void> _save(MultiSessionTableEvaluation evaluation) async {
    setState(() => _showValidation = true);
    final refreshed = _evaluation();
    if (!refreshed.canSave) return;
    setState(() => _saving = true);
    try {
      final result = await MultiSessionSaveService(_db).saveEventWithSessions(
        event: _header().toSaveInput(),
        rows: refreshed.toSaveRows(),
      );
      if (!mounted) return;
      await _showSavedDialog(
        eventId: result.eventId,
        savedCount: result.sessionIds.length,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSavedDialog({
    required int eventId,
    required int savedCount,
  }) {
    final teamName = _selectedTeamId == null
        ? 'No team'
        : _teamsById[_selectedTeamId!]?.name ?? 'Team $_selectedTeamId';
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Group session saved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team: $teamName'),
            Text('Date: ${_formatDateTime(_dateTime)}'),
            Text('Players saved: $savedCount'),
            Text('Event ID: $eventId'),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('multi_save_summary_back'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Back'),
          ),
          ElevatedButton(
            key: const Key('multi_save_summary_new'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _resetAfterSave();
            },
            child: const Text('Start another'),
          ),
        ],
      ),
    );
  }

  void _resetAfterSave() {
    for (final row in _rows) {
      row.dispose();
    }
    setState(() {
      _rows.clear();
      _selectedAthleteToAdd = null;
      _teamLoadMessage = null;
      _showValidation = false;
      _dateTime = DateTime.now();
    });
  }

  List<VariableDefinition> get _loadVariables {
    return _loadType == 'external'
        ? StandardVariables.externalVariables
        : StandardVariables.internalVariables;
  }

  VariableDefinition? _definitionFor(String loadType, String metricName) {
    final variables = loadType == 'external'
        ? StandardVariables.externalVariables
        : StandardVariables.internalVariables;
    final normalized = metricName.trim().toLowerCase();
    for (final item in variables) {
      if (item.name.toLowerCase() == normalized) return item;
    }
    return null;
  }

  String _athleteOptionLabel(Athlete athlete) {
    final assignment = _assignmentsByAthlete[athlete.id];
    final team = assignment == null ? null : _teamsById[assignment.teamId];
    final teamText = team == null ? 'No team' : team.name;
    return '${athlete.name}  -  $teamText  -  ID ${athlete.id}';
  }
}

class _HeaderCard extends StatelessWidget {
  final Widget child;

  const _HeaderCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String text;
  final bool hasError;

  const _SummaryPill({required this.text, required this.hasError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (hasError ? AppColors.error : AppColors.primary).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: hasError ? AppColors.error : AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(text),
      labelStyle: TextStyle(color: color),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final List<String> errors;

  const _ErrorPanel({required this.errors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final error in errors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                error,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _MultiSessionUiRow {
  final int localId;
  final Athlete athlete;
  final TextEditingController rmssdExerciseCtrl = TextEditingController();
  final TextEditingController rmssdRecoveryCtrl = TextEditingController();
  final TextEditingController loadCtrl = TextEditingController();
  final List<VoidCallback> _listeners = [];

  _MultiSessionUiRow({required this.localId, required this.athlete});

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    rmssdExerciseCtrl.addListener(listener);
    rmssdRecoveryCtrl.addListener(listener);
    loadCtrl.addListener(listener);
  }

  void dispose() {
    for (final listener in _listeners) {
      rmssdExerciseCtrl.removeListener(listener);
      rmssdRecoveryCtrl.removeListener(listener);
      loadCtrl.removeListener(listener);
    }
    rmssdExerciseCtrl.dispose();
    rmssdRecoveryCtrl.dispose();
    loadCtrl.dispose();
  }
}

double? _parseDouble(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || !value.isFinite) return null;
  return value;
}

String _formatDateTime(DateTime dateTime) {
  final date =
      '${dateTime.year.toString().padLeft(4, '0')}-'
      '${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')}';
  final time =
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
