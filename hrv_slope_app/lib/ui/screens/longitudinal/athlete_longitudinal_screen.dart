library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/data/export/csv_export_service.dart';
import 'package:hrv_slope_app/data/export/export_file_writer.dart';
import 'package:hrv_slope_app/shared/engine/longitudinal_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/ui/screens/nomogram/individual_nomogram_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/individual_report_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/longitudinal_chart.dart';
import 'package:hrv_slope_app/ui/widgets/rpe_slope_quadrant_chart.dart';

enum _OverlayMetric { intensity, rpe, fatigue, srpe, trimp }

String longitudinalIntensitySourceLabel(String source) {
  return switch (source) {
    'External' => 'External load',
    'Internal' => 'Internal load',
    'Unknown' => 'Unknown',
    _ => _humanizeMetricName(source),
  };
}

String longitudinalIntensityMetricLabel(String metric) {
  return switch (metric) {
    'direct_percent_mas' || 'percent_mas' => '%MAS',
    'internal_rpe_1_10' || 'rpe_1_10' => 'RPE 1-10',
    'session_rpe_1_10' => 'Session RPE 1-10',
    'percent_map' => '%MAP',
    'percent_vvo2max' || 'percent_vvo2_max' => '%vVO2max',
    'percent_vam' => '%VAM',
    'subjective_fatigue_1_10' || 'internal_fatigue_1_10' => 'Fatigue 1-10',
    'subjective_intensity_1_10' => 'Subjective intensity 1-10',
    'subjective_intensity_percent' => 'Subjective intensity %',
    'internal_load_percent' => 'Internal load %',
    'percent_hrmax' || 'percent_hr_max' => '%HRmax',
    'speed_kmh' => 'Speed',
    'power_w' => 'Power',
    _ => _humanizeMetricName(metric),
  };
}

String _humanizeMetricName(String value) {
  final words = value
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  return words
      .map((word) {
        final lower = word.toLowerCase();
        if (lower == 'rpe') return 'RPE';
        if (lower == 'itl') return 'ITL';
        if (lower == 'hrv') return 'HRV';
        if (lower == 'mas') return 'MAS';
        if (lower == 'map') return 'MAP';
        if (lower == 'vam') return 'VAM';
        if (lower == 'vvo2max') return 'vVO2max';
        if (lower == 'hrmax') return 'HRmax';
        if (lower == 'kmh') return 'km/h';
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

class AthleteLongitudinalScreen extends StatefulWidget {
  final AppDatabase database;
  final int athleteId;

  const AthleteLongitudinalScreen({
    super.key,
    required this.database,
    required this.athleteId,
  });

  @override
  State<AthleteLongitudinalScreen> createState() =>
      _AthleteLongitudinalScreenState();
}

class _AthleteLongitudinalScreenState extends State<AthleteLongitudinalScreen> {
  static const _slopeReferenceHelp =
      'Slope trend summarizes RMSSD-Slope changes across sessions.';
  static const _itlReferenceHelp =
      'ITL trend contextualizes response against internal training load.';
  static const _referenceZonesHelp =
      'Colors compare each session with its selected reference zone.';

  LongitudinalSeries? _series;
  Athlete? _athlete;
  List<SessionDetail> _details = [];
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  bool _refreshingNomogram = false;
  NomogramMode _selectedNomogramMode = NomogramMode.population;
  _OverlayMetric _overlay = _OverlayMetric.intensity;
  LongitudinalDashboardFilter _filter = const LongitudinalDashboardFilter();
  LongitudinalXAxisMode _xAxisMode = LongitudinalXAxisMode.sessionOrder;
  bool _colorByOrellanaZone = true;
  int? _selectedSessionId;
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  final _notesController = TextEditingController();
  final _intensityMinController = TextEditingController();
  final _intensityMaxController = TextEditingController();
  final _rpeMinController = TextEditingController();
  final _rpeMaxController = TextEditingController();
  final _fatigueMinController = TextEditingController();
  final _fatigueMaxController = TextEditingController();
  final _slopeMinController = TextEditingController();
  final _slopeMaxController = TextEditingController();
  final _itlMinController = TextEditingController();
  final _itlMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncPendingFields(_filter);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _notesController.dispose();
    _intensityMinController.dispose();
    _intensityMaxController.dispose();
    _rpeMinController.dispose();
    _rpeMaxController.dispose();
    _fatigueMinController.dispose();
    _fatigueMaxController.dispose();
    _slopeMinController.dispose();
    _slopeMaxController.dispose();
    _itlMinController.dispose();
    _itlMaxController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final athlete = await widget.database.athletesDao.getAthleteById(
      widget.athleteId,
    );
    if (athlete == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final details = await widget.database.sessionsDao
        .getSessionDetailsForAthlete(widget.athleteId);
    final series = buildLongitudinalSeries(
      athlete: athlete,
      details: details,
      filter: _filter,
      requestedNomogramMode: _selectedNomogramMode,
    );
    if (mounted) {
      setState(() {
        _athlete = athlete;
        _details = details;
        _series = series;
        _loading = false;
      });
    }
  }

  void _applyFilter(LongitudinalDashboardFilter filter) {
    final athlete = _athlete;
    if (athlete == null) return;
    final series = buildLongitudinalSeries(
      athlete: athlete,
      details: _details,
      filter: filter,
      requestedNomogramMode: _selectedNomogramMode,
    );
    setState(() {
      _filter = filter;
      _series = series;
      if (!series.points.any(
        (point) => point.sessionId == _selectedSessionId,
      )) {
        _selectedSessionId = null;
      }
    });
  }

  Future<void> _applyNomogramMode(NomogramMode mode) async {
    if (mode == _selectedNomogramMode) return;
    final athlete = _athlete;
    if (athlete == null) return;

    setState(() {
      _refreshingNomogram = true;
      _selectedNomogramMode = mode;
    });

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    if (mode != _selectedNomogramMode) return;

    setState(() {
      _series = buildLongitudinalSeries(
        athlete: athlete,
        details: _details,
        filter: _filter,
        requestedNomogramMode: mode,
      );
      _refreshingNomogram = false;
    });
  }

  void _clearFilters() {
    final cleared = _filter.clear();
    _syncPendingFields(cleared);
    _applyFilter(cleared);
  }

  void _applyPendingFilter() {
    _applyFilter(
      _filter.copyWith(
        dateFrom: _trimmedOrNull(_dateFromController.text),
        clearDateFrom: _trimmedOrNull(_dateFromController.text) == null,
        dateTo: _trimmedOrNull(_dateToController.text),
        clearDateTo: _trimmedOrNull(_dateToController.text) == null,
        notesTextSearch: _trimmedOrNull(_notesController.text),
        clearNotesTextSearch: _trimmedOrNull(_notesController.text) == null,
        intensityValueMin: _parseNullableDouble(_intensityMinController.text),
        clearIntensityValueMin:
            _parseNullableDouble(_intensityMinController.text) == null,
        intensityValueMax: _parseNullableDouble(_intensityMaxController.text),
        clearIntensityValueMax:
            _parseNullableDouble(_intensityMaxController.text) == null,
        rpeMin: _parseNullableDouble(_rpeMinController.text),
        clearRpeMin: _parseNullableDouble(_rpeMinController.text) == null,
        rpeMax: _parseNullableDouble(_rpeMaxController.text),
        clearRpeMax: _parseNullableDouble(_rpeMaxController.text) == null,
        fatigueMin: _parseNullableDouble(_fatigueMinController.text),
        clearFatigueMin:
            _parseNullableDouble(_fatigueMinController.text) == null,
        fatigueMax: _parseNullableDouble(_fatigueMaxController.text),
        clearFatigueMax:
            _parseNullableDouble(_fatigueMaxController.text) == null,
        slopeMin: _parseNullableDouble(_slopeMinController.text),
        clearSlopeMin: _parseNullableDouble(_slopeMinController.text) == null,
        slopeMax: _parseNullableDouble(_slopeMaxController.text),
        clearSlopeMax: _parseNullableDouble(_slopeMaxController.text) == null,
        itlMin: _parseNullableDouble(_itlMinController.text),
        clearItlMin: _parseNullableDouble(_itlMinController.text) == null,
        itlMax: _parseNullableDouble(_itlMaxController.text),
        clearItlMax: _parseNullableDouble(_itlMaxController.text) == null,
      ),
    );
  }

  void _syncPendingFields(LongitudinalDashboardFilter filter) {
    _dateFromController.text = filter.dateFrom ?? '';
    _dateToController.text = filter.dateTo ?? '';
    _notesController.text = filter.notesTextSearch ?? '';
    _intensityMinController.text = _fieldNumber(filter.intensityValueMin);
    _intensityMaxController.text = _fieldNumber(filter.intensityValueMax);
    _rpeMinController.text = _fieldNumber(filter.rpeMin);
    _rpeMaxController.text = _fieldNumber(filter.rpeMax);
    _fatigueMinController.text = _fieldNumber(filter.fatigueMin);
    _fatigueMaxController.text = _fieldNumber(filter.fatigueMax);
    _slopeMinController.text = _fieldNumber(filter.slopeMin);
    _slopeMaxController.text = _fieldNumber(filter.slopeMax);
    _itlMinController.text = _fieldNumber(filter.itlMin);
    _itlMaxController.text = _fieldNumber(filter.itlMax);
  }

  String _visibleActiveFilterLabel(String label) {
    if (label.startsWith('Intensity source: ')) {
      return _mapFilterValues(
        label,
        'Intensity source: ',
        longitudinalIntensitySourceLabel,
      );
    }
    if (label.startsWith('Intensity metric: ')) {
      return _mapFilterValues(
        label,
        'Metric used for slope: ',
        longitudinalIntensityMetricLabel,
      );
    }
    if (label.startsWith('Intensity: ')) {
      return label.replaceFirst(
        'Intensity: ',
        'Primary intensity used for slope (%): ',
      );
    }
    return label;
  }

  String _mapFilterValues(
    String label,
    String visiblePrefix,
    String Function(String value) displayLabel,
  ) {
    final rawValues = label.substring(label.indexOf(':') + 1).trim();
    final values = rawValues
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map(displayLabel)
        .join(', ');
    return '$visiblePrefix$values';
  }

  void _selectSession(int sessionId) {
    setState(() => _selectedSessionId = sessionId);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final athlete = _athlete;
    final series = _series;
    if (athlete == null || series == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Longitudinal')),
        body: const Center(child: Text('Athlete not found')),
      );
    }
    final intensityOverlayMax = resolvePrimaryIntensityOverlayMax(
      series.points.map((point) => point.primaryIntensityValue),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Longitudinal Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _header(athlete, series),
          _filtersPanel(series),
          _summary(series),
          _dataCompleteness(series),
          if (series.points.isEmpty)
            _emptyFilteredState(series)
          else ...[
            _xAxisSelector(),
            _referenceToggle(series),
            _trendCharts(series),
            RpeSlopeQuadrantChart(
              data: series.rpeSlopeQuadrantData,
              selectedSessionId: _selectedSessionId,
              onPointSelected: _selectSession,
            ),
            _advancedCharts(series, intensityOverlayMax),
            if (_selectedPoint(series) != null) _selectedSession(series),
            _flags(series),
            _sessionList(series),
          ],
        ],
      ),
    );
  }

  Widget _header(Athlete athlete, LongitudinalSeries series) {
    final sourcePoints = series.allPoints.isEmpty
        ? series.points
        : series.allPoints;
    final dateRange = sourcePoints.isEmpty
        ? 'No sessions'
        : '${sourcePoints.first.date} to ${sourcePoints.last.date}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              athlete.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (athlete.sport != null)
              Text(
                athlete.sport!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const Divider(height: 20),
            _row('Date range', dateRange),
            _row(
              'Sessions',
              '${series.completeness.includedSessions} of ${series.completeness.totalSessions}',
            ),
            _row('Complete sessions', '${series.summary.nComplete}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => IndividualNomogramScreen(
                      database: widget.database,
                      athleteId: widget.athleteId,
                    ),
                  ),
                ),
                icon: const Icon(Icons.scatter_plot),
                label: const Text('Nomogram'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtersPanel(LongitudinalSeries series) {
    final options = series.filterOptions;
    final labels = series.activeFilterLabels;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: _filter.activeFilterCount > 0,
        title: Text('Filters (${_filter.activeFilterCount})'),
        subtitle: labels.isEmpty
            ? const Text('Compare similar sessions')
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final label in labels)
                    Chip(label: Text(_visibleActiveFilterLabel(label))),
                ],
              ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _filterActions(),
          CheckboxListTile(
            value: _filter.comparableSessionsOnly,
            contentPadding: EdgeInsets.zero,
            title: const Text('Comparable sessions only'),
            subtitle: const Text(
              'Comparable mode uses the latest included session as reference.',
            ),
            onChanged: (value) => _applyFilter(
              _filter.copyWith(comparableSessionsOnly: value ?? false),
            ),
          ),
          if (_filter.comparableSessionsOnly)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${series.comparableIncludedCount} of ${series.comparableTotalCount} sessions match comparable criteria.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          _filterSection(
            title: 'Session similarity',
            help:
                'Use these filters to compare sessions with similar sport, task, protocol, and context.',
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateFromController,
                      decoration: InputDecoration(
                        labelText: 'Date from',
                        hintText: options.dateMin ?? 'YYYY-MM-DD',
                      ),
                      onEditingComplete: _applyPendingFilter,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _dateToController,
                      decoration: InputDecoration(
                        labelText: 'Date to',
                        hintText: options.dateMax ?? 'YYYY-MM-DD',
                      ),
                      onEditingComplete: _applyPendingFilter,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _filterGroup('Sport', options.sports, _filter.sports, (values) {
                _applyFilter(_filter.copyWith(sports: values));
              }),
              _filterGroup(
                'Session task/name',
                options.sessionTasks,
                _filter.sessionTasks,
                (values) {
                  _applyFilter(_filter.copyWith(sessionTasks: values));
                },
              ),
              _filterGroup(
                'Session type',
                options.sessionTypes,
                _filter.sessionTypes,
                (values) {
                  _applyFilter(_filter.copyWith(sessionTypes: values));
                },
              ),
              _filterGroup(
                'Protocol name',
                options.protocolNames,
                _filter.protocolNames,
                (values) {
                  _applyFilter(_filter.copyWith(protocolNames: values));
                },
              ),
              _filterGroup(
                'Context / Environment',
                options.contextEnvironmentTags,
                _filter.contextEnvironmentTags,
                (values) {
                  _applyFilter(
                    _filter.copyWith(contextEnvironmentTags: values),
                  );
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes contains'),
                onEditingComplete: _applyPendingFilter,
              ),
            ],
          ),
          _filterSection(
            title: 'Intensity used for slope',
            help:
                'External intensity is used when available. If it is missing, internal intensity such as RPE or subjective fatigue can be used for slope interpretation.',
            children: [
              _filterGroup(
                'Source used for slope',
                options.intensitySourcesForSlope,
                _filter.intensitySourcesForSlope,
                (values) {
                  _applyFilter(
                    _filter.copyWith(intensitySourcesForSlope: values),
                  );
                },
                displayLabel: longitudinalIntensitySourceLabel,
              ),
              _filterGroup(
                'Metric used for slope',
                options.intensityMetricNames,
                _filter.intensityMetricNames,
                (values) {
                  _applyFilter(_filter.copyWith(intensityMetricNames: values));
                },
                displayLabel: longitudinalIntensityMetricLabel,
              ),
              _rangeFields(
                label: 'Primary intensity used for slope (%)',
                minController: _intensityMinController,
                maxController: _intensityMaxController,
              ),
            ],
          ),
          _filterSection(
            title: 'Subjective response',
            help:
                'These filters use the original subjective values, not the normalized primary intensity.',
            children: [
              _rangeFields(
                label: 'RPE 1-10',
                minController: _rpeMinController,
                maxController: _rpeMaxController,
              ),
              _rangeFields(
                label: 'Fatigue 1-10',
                minController: _fatigueMinController,
                maxController: _fatigueMaxController,
              ),
            ],
          ),
          _filterSection(
            title: 'Recovery response',
            help:
                'Use these filters to inspect sessions with similar recovery-response outcomes.',
            children: [
              _rangeFields(
                label: 'Slope',
                minController: _slopeMinController,
                maxController: _slopeMaxController,
              ),
              _rangeFields(
                label: 'ITL',
                minController: _itlMinController,
                maxController: _itlMaxController,
              ),
            ],
          ),
          _filterSection(
            title: 'Advanced filters',
            children: [
              _filterGroup(
                'HRV input mode',
                options.hrvInputModes,
                _filter.hrvInputModes,
                (values) {
                  _applyFilter(_filter.copyWith(hrvInputModes: values));
                },
              ),
              _filterGroup(
                'Recovery window',
                options.recoveryWindows,
                _filter.recoveryWindows,
                (values) {
                  _applyFilter(_filter.copyWith(recoveryWindows: values));
                },
              ),
            ],
          ),
          _filterActions(),
        ],
      ),
    );
  }

  Widget _filterGroup(
    String label,
    Set<String> options,
    Set<String> selected,
    ValueChanged<Set<String>> onChanged, {
    String Function(String value)? displayLabel,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(displayLabel?.call(option) ?? option),
                  selected: selected.contains(option),
                  onSelected: (_) => onChanged(_toggleValue(selected, option)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterSection({
    required String title,
    String? help,
    required List<Widget> children,
  }) {
    final visibleChildren = children
        .where((child) => child is! SizedBox || child.width != 0)
        .toList();
    if (visibleChildren.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          if (help != null) ...[
            const SizedBox(height: 4),
            Text(help, style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          ...visibleChildren,
        ],
      ),
    );
  }

  Widget _filterActions() {
    final hasActiveFilters = _filter.activeFilterCount > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (hasActiveFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear filters'),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _applyPendingFilter,
            icon: const Icon(Icons.check),
            label: const Text('Apply filters'),
          ),
        ],
      ),
    );
  }

  Widget _rangeFields({
    required String label,
    required TextEditingController minController,
    required TextEditingController maxController,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: minController,
              decoration: const InputDecoration(labelText: 'Min'),
              keyboardType: TextInputType.number,
              onEditingComplete: _applyPendingFilter,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: maxController,
              decoration: const InputDecoration(labelText: 'Max'),
              keyboardType: TextInputType.number,
              onEditingComplete: _applyPendingFilter,
            ),
          ),
        ],
      ),
    );
  }

  Set<String> _toggleValue(Set<String> values, String value) {
    final next = Set<String>.from(values);
    if (!next.add(value)) next.remove(value);
    return next;
  }

  Widget _summary(LongitudinalSeries series) {
    final s = series.summary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _metric('Latest slope', _fixed(s.latestSlope, 3)),
            _metric('Latest ITL', _fixed(s.latestItl, 3)),
            _metric('Latest response', _classLabel(s.latestClassification)),
            _metric('Mean slope', _fixed(s.meanSlope, 3)),
            _metric('Trend', _trendLabel(s.trendDirection)),
            _metric('Active flags', '${series.fatigueFlags.length}'),
          ],
        ),
      ),
    );
  }

  Widget _dataCompleteness(LongitudinalSeries series) {
    final c = series.completeness;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metric(
              'Included / total',
              '${c.includedSessions}/${c.totalSessions}',
            ),
            _metric('With slope', '${c.withSlope}'),
            _metric('With ITL', '${c.withItl}'),
            _metric('External intensity', '${c.withExternalIntensity}'),
            _metric('Internal fallback', '${c.withInternalFallback}'),
            _metric('With RPE', '${c.withRpe}'),
            _metric('With fatigue', '${c.withFatigue}'),
            _metric(
              'slope_Orellana_19 reference',
              '${c.withSlopeOrellana19Reference}',
            ),
            _metric(
              'Missing reference intensity',
              '${c.missingReferencePrimaryIntensity}',
            ),
            _metric('Lower-than-expected', '${c.referenceZoneLow}'),
            _metric('Expected', '${c.referenceZoneNormal}'),
            _metric('Favorable', '${c.referenceZoneFavorable}'),
            _metric('Missing key data', '${c.missingKeyData}'),
          ],
        ),
      ),
    );
  }

  Widget _emptyFilteredState(LongitudinalSeries series) {
    final hasActiveFilters = !series.filter.isEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              hasActiveFilters
                  ? 'No sessions match the selected filters.'
                  : 'Not enough complete sessions to draw this trend.',
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _applyFilter(_filter.clear()),
                icon: const Icon(Icons.clear),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _xAxisSelector() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<LongitudinalXAxisMode>(
          initialValue: _xAxisMode,
          decoration: const InputDecoration(labelText: 'X-axis'),
          items: const [
            DropdownMenuItem(
              value: LongitudinalXAxisMode.sessionOrder,
              child: Text('Session order'),
            ),
            DropdownMenuItem(
              value: LongitudinalXAxisMode.date,
              child: Text('Date'),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _xAxisMode = value);
          },
        ),
      ),
    );
  }

  Widget _referenceToggle(LongitudinalSeries series) {
    final available = series.nomogramReferenceSeries.availableCount;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _nomogramModelSelection(),
            const SizedBox(height: 12),
            _nomogramModelMetadata(series.nomogramReferenceSeries),
            const Divider(height: 16),
            SwitchListTile(
              value: _colorByOrellanaZone,
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: const [
                  Expanded(
                    child: Text('Color points by slope_Orellana_19 zone'),
                  ),
                  Tooltip(
                    message:
                        "Points are colored by the session's slope_Orellana_19 zone. The reference is calculated per session from primary intensity.",
                    triggerMode: TooltipTriggerMode.tap,
                    child: Icon(Icons.help_outline, size: 18),
                  ),
                ],
              ),
              subtitle: Text(
                available == 0
                    ? 'slope_Orellana_19 reference requires primary intensity and slope data.'
                    : '$available sessions have slope_Orellana_19 zone data.',
              ),
              onChanged: (value) =>
                  setState(() => _colorByOrellanaZone = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nomogramModelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Model selection',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<NomogramMode>(
            segments: const [
              ButtonSegment(
                value: NomogramMode.population,
                label: Text('Study model'),
              ),
              ButtonSegment(
                value: NomogramMode.hybrid,
                label: Text('Hybrid model'),
              ),
              ButtonSegment(
                value: NomogramMode.individual,
                label: Text('Individual model'),
              ),
            ],
            selected: {_selectedNomogramMode},
            onSelectionChanged: _refreshingNomogram
                ? null
                : (selection) => _applyNomogramMode(selection.first),
          ),
        ),
        if (_refreshingNomogram) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Updating model...',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _nomogramModelMetadata(LongitudinalNomogramReferenceSeries reference) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(
            'Requested model',
            _modeLabel(reference.requestedMode),
            help: 'Model selected by the user.',
          ),
          _row(
            'Active model',
            _modeLabel(reference.activeMode),
            help: 'Model actually used after readiness and fallback rules.',
          ),
          _row(
            'Blend',
            '${reference.athleteWeightPercent.toStringAsFixed(0)}% athlete / '
                '${reference.populationWeightPercent.toStringAsFixed(0)}% study',
            help:
                'Percentage contribution from athlete history and study reference.',
          ),
          if (reference.requestedMode != reference.activeMode)
            _referenceInfo(
              'Requested ${_modeLabel(reference.requestedMode).toLowerCase()} is not available yet. '
              'Using ${_modeLabel(reference.activeMode).toLowerCase()}.',
            ),
          if (reference.activeMode == NomogramMode.hybrid)
            _referenceInfo(
              'Hybrid model blends athlete history with the study reference.',
            ),
          if (reference.hasExtrapolatedPoints)
            _referenceInfo(
              'Estimated zone: some intensities are outside the validated reference range.',
            ),
          for (final warning in reference.warnings)
            if (!reference.hasExtrapolatedPoints ||
                !warning.contains('extrapolated'))
              _referenceInfo(warning),
          if (reference.readinessGaps.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Individual model not available yet:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            for (final gap in reference.readinessGaps)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• ${gap.criterion}: ${gap.currentValue}; required ${gap.requiredValue}.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _referenceInfo(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendCharts(LongitudinalSeries series) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slopePanel = _trendChartPanel(
          chart: _slopeTrendChart(series),
          helpText: '$_slopeReferenceHelp $_referenceZonesHelp',
        );
        final itlPanel = _trendChartPanel(
          chart: _itlTrendChart(series),
          helpText: '$_itlReferenceHelp $_referenceZonesHelp',
        );

        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: slopePanel),
              const SizedBox(width: 12),
              Expanded(child: itlPanel),
            ],
          );
        }

        return Column(children: [slopePanel, itlPanel]);
      },
    );
  }

  Widget _trendChartPanel({required Widget chart, required String helpText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chart,
        if (_colorByOrellanaZone) ...[
          _zoneLegend(),
          _referenceHelpText(helpText),
        ],
      ],
    );
  }

  Widget _slopeTrendChart(LongitudinalSeries series) {
    return LongitudinalChart(
      title: 'Slope Trend',
      valueLabel: 'Slope',
      points: [
        for (final point in series.points)
          _chartPoint(
            point,
            value: point.interpretedSlope,
            color: _slopePointColor(point),
            tooltip: _slopeTooltip(point),
          ),
      ],
      selectedSessionId: _selectedSessionId,
      onPointSelected: _selectSession,
      xAxisLabel: _xAxisLabel,
    );
  }

  Widget _itlTrendChart(LongitudinalSeries series) {
    return LongitudinalChart(
      title: 'ITL Trend',
      valueLabel: 'ITL',
      points: [
        for (final point in series.points)
          _chartPoint(
            point,
            value: point.itlIndex,
            color: _itlPointColor(point),
            tooltip: _itlTooltip(point),
          ),
      ],
      selectedSessionId: _selectedSessionId,
      onPointSelected: _selectSession,
      xAxisLabel: _xAxisLabel,
      emptyMessage: 'No ITL values available for this athlete yet.',
    );
  }

  Widget _zoneLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: const [
          _ZoneLegendItem(
            color: AppColors.warning,
            label: 'Lower-than-expected: below reference',
          ),
          _ZoneLegendItem(
            color: AppColors.primary,
            label: 'Expected: within reference',
          ),
          _ZoneLegendItem(
            color: AppColors.success,
            label: 'Favorable: above threshold',
          ),
          _ZoneLegendItem(
            color: AppColors.textHint,
            label: 'Unavailable: missing reference',
          ),
        ],
      ),
    );
  }

  Widget _referenceHelpText(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _overlaySelector() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<_OverlayMetric>(
          initialValue: _overlay,
          decoration: const InputDecoration(labelText: 'Overlay metric'),
          items: const [
            DropdownMenuItem(
              value: _OverlayMetric.intensity,
              child: Text('Primary intensity (%)'),
            ),
            DropdownMenuItem(value: _OverlayMetric.rpe, child: Text('RPE')),
            DropdownMenuItem(
              value: _OverlayMetric.fatigue,
              child: Text('Fatigue'),
            ),
            DropdownMenuItem(value: _OverlayMetric.srpe, child: Text('sRPE')),
            DropdownMenuItem(value: _OverlayMetric.trimp, child: Text('TRIMP')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _overlay = value);
          },
        ),
      ),
    );
  }

  Widget _advancedCharts(
    LongitudinalSeries series,
    double intensityOverlayMax,
  ) {
    return ExpansionTile(
      title: const Text('Advanced charts'),
      subtitle: const Text('Primary intensity overlay and residual trend'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: EdgeInsets.zero,
      children: [
        _overlaySelector(),
        LongitudinalChart(
          title: _overlayTitle(),
          valueLabel: _overlayLabel(),
          points: [
            for (final point in series.points)
              _chartPoint(
                point,
                value: _overlayValue(point),
                color: AppColors.secondary,
                tooltip: _overlayTooltip(point),
              ),
          ],
          selectedSessionId: _selectedSessionId,
          onPointSelected: _selectSession,
          xAxisLabel: _xAxisLabel,
          yMin: _overlay == _OverlayMetric.intensity ? 0 : null,
          yMax: _overlay == _OverlayMetric.intensity
              ? intensityOverlayMax
              : null,
          yInterval: _overlay == _OverlayMetric.intensity
              ? resolvePrimaryIntensityOverlayInterval(intensityOverlayMax)
              : null,
          emptyMessage: 'No values available for this selected overlay.',
        ),
        LongitudinalChart(
          title: 'Residual Trend',
          valueLabel: 'Residual',
          points: [
            for (final point in series.points)
              _chartPoint(
                point,
                value: point.residual,
                color: point.residual != null && point.residual! < 0
                    ? AppColors.warning
                    : AppColors.success,
                tooltip: _residualTooltip(point),
              ),
          ],
          selectedSessionId: _selectedSessionId,
          onPointSelected: _selectSession,
          xAxisLabel: _xAxisLabel,
          emptyMessage:
              'Residuals require intensity percent and interpreted slope.',
        ),
      ],
    );
  }

  Widget _selectedSession(LongitudinalSeries series) {
    final point = _selectedPoint(series);
    if (point == null) return const SizedBox.shrink();
    final quadrantPoint = _rpeSlopeQuadrantPoint(series, point.sessionId);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected session',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _sessionDetails(point, quadrantPoint: quadrantPoint),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _openReport(point.sessionId),
                child: const Text('Open report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flags(LongitudinalSeries series) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fatigue Flags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (series.fatigueFlags.isEmpty)
              const Text(
                'No current flags. Continue monitoring training context.',
                style: TextStyle(color: AppColors.textHint),
              )
            else
              for (final flag in series.fatigueFlags)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.warning_amber,
                    color: AppColors.warning,
                  ),
                  title: Text(flag.message),
                  subtitle: Text('${flag.startDate} to ${flag.endDate}'),
                ),
          ],
        ),
      ),
    );
  }

  Widget _sessionList(LongitudinalSeries series) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sessions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final point in series.points)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: point.sessionId == _selectedSessionId
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : null,
                child: ListTile(
                  onTap: () => _selectSession(point.sessionId),
                  title: Text(point.taskName ?? point.date),
                  subtitle: _sessionDetails(point),
                  trailing: TextButton(
                    onPressed: () => _openReport(point.sessionId),
                    child: const Text('Open report'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  RpeSlopeQuadrantPoint? _rpeSlopeQuadrantPoint(
    LongitudinalSeries series,
    int sessionId,
  ) {
    for (final point in series.rpeSlopeQuadrantData.points) {
      if (point.sessionId == sessionId) return point;
    }
    return null;
  }

  Widget _sessionDetails(
    LongitudinalPoint point, {
    RpeSlopeQuadrantPoint? quadrantPoint,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        Text('Date ${point.date}'),
        if (point.sport != null) Text('Sport ${point.sport}'),
        if (point.sessionType != null) Text('Type ${point.sessionType}'),
        if (point.protocolName != null) Text('Protocol ${point.protocolName}'),
        if (point.contextEnvironment != null)
          Text('Context ${point.contextEnvironment}'),
        Text('Slope ${_fixed(point.interpretedSlope, 3)}'),
        Text('ITL ${_fixed(point.itlIndex, 3)}'),
        Text(
          'Observed slope ${_fixed(point.nomogramReference.observedSlope, 3)}',
        ),
        Text(
          'Reference slope ${_fixed(point.nomogramReference.referenceSlope, 3)}',
        ),
        Text(
          'Low threshold ${_fixed(point.nomogramReference.lowerSlopeThreshold, 3)}',
        ),
        Text(
          'Favorable threshold ${_fixed(point.nomogramReference.upperSlopeThreshold, 3)}',
        ),
        Text(
          'Reference ITL ${_fixed(point.nomogramReference.referenceItl, 3)}',
        ),
        if (quadrantPoint?.slopeResponseIndex != null)
          Text(
            'Response index ${_fixed(quadrantPoint!.slopeResponseIndex, 3)}',
          ),
        Text('Recovery zone ${point.nomogramReference.zone.label}'),
        if (quadrantPoint != null)
          Text('RPE slope quadrant ${quadrantPoint.quadrant.label}'),
        Text(
          point.nomogramReference.isAvailable
              ? 'Reference ${point.nomogramReference.source}'
              : 'Reference unavailable: ${point.nomogramReference.unavailableReason ?? 'nomogram unavailable'}',
        ),
        Text('Primary intensity ${_fixed(point.primaryIntensityValue, 1)}%'),
        Text(
          'Source ${longitudinalIntensitySourceLabel(point.intensitySourceForSlope)}',
        ),
        Text(intensitySourceForSlopeMessage(point.intensitySourceForSlope)),
        Text(
          'Metric ${point.primaryIntensityMetric == null ? '-' : longitudinalIntensityMetricLabel(point.primaryIntensityMetric!)}',
        ),
        Text('RPE ${_fixed(point.rpe, 1)}'),
        Text('Fatigue ${_fixed(point.fatigue, 1)}'),
        if (point.notes != null) Text('Notes ${_shortText(point.notes!, 90)}'),
        if (point.classification != null)
          Text(_classLabel(point.classification)),
      ],
    );
  }

  LongitudinalChartPoint _chartPoint(
    LongitudinalPoint point, {
    required double? value,
    required Color color,
    required String tooltip,
  }) {
    return LongitudinalChartPoint(
      sessionId: point.sessionId,
      label: point.date,
      value: value,
      color: color,
      tooltip: tooltip,
    );
  }

  String _slopeTooltip(LongitudinalPoint point) {
    return [
      point.date,
      point.taskName ?? 'Session',
      'Slope: ${_fixed(point.interpretedSlope, 3)}',
      'Zone: ${point.nomogramReference.zone.label}',
      _intensityTooltipLine(point),
      if (point.rpe != null) 'RPE: ${_fixed(point.rpe, 1)}',
    ].join('\n');
  }

  String _itlTooltip(LongitudinalPoint point) {
    return [
      point.date,
      point.taskName ?? 'Session',
      'ITL: ${_fixed(point.itlIndex, 3)}',
      'Zone: ${point.nomogramReference.zone.label}',
      _intensityTooltipLine(point),
      'Slope: ${_fixed(point.interpretedSlope, 3)}',
    ].join('\n');
  }

  String _overlayTooltip(LongitudinalPoint point) {
    return [
      point.date,
      point.taskName ?? 'Session',
      '${_overlayLabel()}: ${_fixed(_overlayValue(point), 1)}',
      'Metric: ${_metricLabel(point)}',
      'Source: ${longitudinalIntensitySourceLabel(point.intensitySourceForSlope)}',
      if (point.rpe != null) 'RPE: ${_fixed(point.rpe, 1)}',
    ].join('\n');
  }

  String _residualTooltip(LongitudinalPoint point) {
    return [
      point.date,
      point.taskName ?? 'Session',
      'Residual: ${_fixed(point.residual, 3)}',
      'Zone: ${point.nomogramReference.zone.label}',
    ].join('\n');
  }

  String _intensityTooltipLine(LongitudinalPoint point) {
    return 'Intensity: ${_fixed(point.primaryIntensityValue, 1)}% · ${_metricLabel(point)} · ${longitudinalIntensitySourceLabel(point.intensitySourceForSlope)}';
  }

  String _metricLabel(LongitudinalPoint point) {
    final metric = point.primaryIntensityMetric;
    return metric == null ? '-' : longitudinalIntensityMetricLabel(metric);
  }

  Color _slopePointColor(LongitudinalPoint point) {
    if (_colorByOrellanaZone) {
      return longitudinalRecoveryZoneColor(point.nomogramReference.zone);
    }
    return AppColors.primary;
  }

  Color _itlPointColor(LongitudinalPoint point) {
    if (_colorByOrellanaZone) {
      return longitudinalRecoveryZoneColor(point.nomogramReference.zone);
    }
    return AppColors.primary;
  }

  LongitudinalPoint? _selectedPoint(LongitudinalSeries series) {
    final id = _selectedSessionId;
    if (id == null) return null;
    for (final point in series.points) {
      if (point.sessionId == id) return point;
    }
    return null;
  }

  String _overlayTitle() {
    return switch (_overlay) {
      _OverlayMetric.intensity => 'Intensity Overlay',
      _OverlayMetric.rpe => 'RPE Overlay',
      _OverlayMetric.fatigue => 'Fatigue Overlay',
      _OverlayMetric.srpe => 'sRPE Overlay',
      _OverlayMetric.trimp => 'TRIMP Overlay',
    };
  }

  String _overlayLabel() {
    return switch (_overlay) {
      _OverlayMetric.intensity => 'Primary intensity (%)',
      _OverlayMetric.rpe => 'RPE',
      _OverlayMetric.fatigue => 'Fatigue',
      _OverlayMetric.srpe => 'sRPE',
      _OverlayMetric.trimp => 'TRIMP',
    };
  }

  double? _overlayValue(LongitudinalPoint point) {
    return switch (_overlay) {
      _OverlayMetric.intensity => point.primaryIntensityValue,
      _OverlayMetric.rpe => point.rpe,
      _OverlayMetric.fatigue => point.fatigue,
      _OverlayMetric.srpe => point.srpe,
      _OverlayMetric.trimp => point.trimp,
    };
  }

  String get _xAxisLabel {
    return switch (_xAxisMode) {
      LongitudinalXAxisMode.sessionOrder => 'Session order',
      LongitudinalXAxisMode.date => 'Date',
    };
  }

  void _openReport(int sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IndividualReportScreen(
          database: widget.database,
          sessionId: sessionId,
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final series = _series;
    if (series == null) return;
    final writer = ExportFileWriter();
    final rows = await writer.writeCsv(exportLongitudinalCsv(series));
    final flags = await writer.writeCsv(
      exportLongitudinalFatigueFlagsCsv(series),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported to ${rows.path} and ${flags.path}')),
    );
  }
}

Widget _metric(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
  );
}

Widget _row(String label, String value, {Color? valueColor, String? help}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: _labelWithTooltip(label, help)),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, color: valueColor)),
        ),
      ],
    ),
  );
}

Widget _labelWithTooltip(String label, String? help) {
  final text = Text(
    label,
    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
  );
  if (help == null) return text;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: text),
      const SizedBox(width: 4),
      Tooltip(
        message: help,
        triggerMode: TooltipTriggerMode.tap,
        child: InkResponse(
          radius: 14,
          child: const Icon(
            Icons.help_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ],
  );
}

class _ZoneLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ZoneLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

double? _parseNullableDouble(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

String? _trimmedOrNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String _fieldNumber(double? value) {
  if (value == null) return '';
  if ((value - value.round()).abs() < 1e-9) return value.round().toString();
  return value.toString();
}

String _fixed(double? value, int digits) =>
    value == null ? '-' : value.toStringAsFixed(digits);

String _modeLabel(NomogramMode mode) {
  switch (mode) {
    case NomogramMode.population:
      return 'Study model';
    case NomogramMode.hybrid:
      return 'Hybrid model';
    case NomogramMode.individual:
      return 'Individual model';
  }
}

String _shortText(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength)}...';
}

String _trendLabel(LongitudinalTrendDirection direction) {
  switch (direction) {
    case LongitudinalTrendDirection.improving:
      return 'Improving';
    case LongitudinalTrendDirection.worsening:
      return 'Worsening';
    case LongitudinalTrendDirection.stable:
      return 'Stable';
    case LongitudinalTrendDirection.insufficientData:
      return 'Insufficient data';
  }
}

String _classLabel(String? value) {
  return recoveryResponseLabelForClassificationKey(value);
}

Color longitudinalRecoveryZoneColor(LongitudinalRecoveryZone zone) {
  switch (zone) {
    case LongitudinalRecoveryZone.low:
      return AppColors.warning;
    case LongitudinalRecoveryZone.normal:
      return AppColors.primary;
    case LongitudinalRecoveryZone.favorable:
      return AppColors.success;
    case LongitudinalRecoveryZone.unavailable:
      return AppColors.textHint;
  }
}
