library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/export/csv_export_service.dart';
import 'package:hrv_slope_app/data/export/export_file_writer.dart';
import 'package:hrv_slope_app/data/services/nomogram_mode_preference_service.dart';
import 'package:hrv_slope_app/shared/engine/individual_nomogram_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/date_filter_field.dart';
import 'package:hrv_slope_app/ui/widgets/nomogram_chart.dart';

class IndividualNomogramScreen extends StatefulWidget {
  final AppDatabase database;
  final int athleteId;

  const IndividualNomogramScreen({
    super.key,
    required this.database,
    required this.athleteId,
  });

  @override
  State<IndividualNomogramScreen> createState() =>
      _IndividualNomogramScreenState();
}

class _IndividualNomogramScreenState extends State<IndividualNomogramScreen> {
  final _scrollController = ScrollController();
  IndividualNomogramData? _data;
  Athlete? _athlete;
  PopulationNomogramSource _preset = PopulationNomogramSource.excelOperational;
  NomogramMode? _selectedNomogramMode;
  bool _loading = true;
  bool _refreshingNomogram = false;
  bool _filtersExpanded = false;
  final _filterDateFromController = TextEditingController();
  final _filterDateToController = TextEditingController();
  String? _filterDateFrom;
  String? _filterDateTo;
  RangeValues? _pendingIntensityRange;
  RangeValues? _filterIntensityRange;
  Set<String>? _pendingResponseCategories;
  Set<String>? _filterResponseCategories;

  NomogramModePreferenceService get _nomogramModePreferences =>
      NomogramModePreferenceService(widget.database.settingsDao);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterDateFromController.dispose();
    _filterDateToController.dispose();
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
    final presetName = await widget.database.settingsDao.getSetting(
      'population_nomogram_preset',
    );
    final preset = parsePopulationNomogramSource(presetName);
    final details = await widget.database.sessionsDao
        .getSessionDetailsForAthlete(widget.athleteId);
    final requestedMode = await _nomogramModePreferences.load(widget.athleteId);
    final data = buildIndividualNomogramData(
      athlete: athlete,
      details: details,
      populationPreset: preset,
      requestedNomogramMode: requestedMode,
    );
    if (mounted) {
      setState(() {
        _athlete = athlete;
        _preset = preset;
        _data = data;
        _selectedNomogramMode = requestedMode;
        _loading = false;
      });
    }
  }

  void _changePreset(PopulationNomogramSource preset) async {
    final athlete = _athlete;
    if (athlete == null) return;
    final requestedMode = _selectedNomogramMode ?? _data?.requestedMode;
    setState(() {
      _preset = preset;
      _refreshingNomogram = true;
    });
    final details = await widget.database.sessionsDao
        .getSessionDetailsForAthlete(widget.athleteId);
    if (mounted) {
      setState(() {
        _data = buildIndividualNomogramData(
          athlete: athlete,
          details: details,
          populationPreset: preset,
          requestedNomogramMode: requestedMode,
        );
        _refreshingNomogram = false;
      });
    }
  }

  Future<void> _applyNomogramMode(NomogramMode mode) async {
    if (mode == (_selectedNomogramMode ?? _data?.requestedMode)) return;
    final athlete = _athlete;
    if (athlete == null) return;

    setState(() {
      _selectedNomogramMode = mode;
      _refreshingNomogram = true;
    });

    await _nomogramModePreferences.save(widget.athleteId, mode);
    final details = await widget.database.sessionsDao
        .getSessionDetailsForAthlete(widget.athleteId);
    if (!mounted || mode != _selectedNomogramMode) return;

    setState(() {
      _data = buildIndividualNomogramData(
        athlete: athlete,
        details: details,
        populationPreset: _preset,
        requestedNomogramMode: mode,
      );
      _refreshingNomogram = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final data = _data;
    final athlete = _athlete;
    if (data == null || athlete == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Individual Nomogram')),
        body: const Center(child: Text('Athlete not found')),
      );
    }
    final visiblePoints = _filteredValidPoints(data);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Nomogram'),
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
          _header(athlete, data),
          _confidenceCard(data),
          if (data.warnings.isNotEmpty) _warningsCard(data),
          _chartCard(data, visiblePoints),
          _pointsList(data, visiblePoints),
          _excludedList(data),
        ],
      ),
    );
  }

  Widget _header(Athlete athlete, IndividualNomogramData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        athlete.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (athlete.sport != null)
                        Text(
                          athlete.sport!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Chip(label: Text(_recommendedModeLabel(data))),
              ],
            ),
            const Divider(height: 20),
            _row('Valid points', '${data.summary.validPointCount}'),
            _row('Confidence', data.summary.confidenceLabel),
            _row('Recommended mode', _recommendedModeLabel(data)),
            _row('Study preset', data.populationPreset.presetName),
          ],
        ),
      ),
    );
  }

  Widget _confidenceCard(IndividualNomogramData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confidence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Low intensity', data.summary.lowZoneCount),
                _chip('Medium intensity', data.summary.mediumZoneCount),
                _chip('High intensity', data.summary.highZoneCount),
                _chip('Athlete weight', data.hybridWeightIndividual, digits: 1),
                _chip('Study weight', data.hybridWeightPopulation, digits: 1),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _confidenceGuidance(data),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _warningsCard(IndividualNomogramData data) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Needs',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final warning in data.warnings)
              Text(
                warning,
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(
    IndividualNomogramData data,
    List<IndividualNomogramPoint> visiblePoints,
  ) {
    final points = [
      for (final point in visiblePoints)
        NomogramObservedPoint(
          xIntensityPercent: point.intensityPercent,
          ySlope: point.interpretedSlope,
          label: point.taskName ?? point.date,
          classification: point.classification,
          sessionId: point.sessionId,
          athleteName: data.athleteName,
          isExtrapolated: data.hasExtrapolatedPoints,
        ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nomogram Overlay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                DropdownButton<PopulationNomogramSource>(
                  value: _preset,
                  items: const [
                    DropdownMenuItem(
                      value: PopulationNomogramSource.excelOperational,
                      child: Text('Excel'),
                    ),
                    DropdownMenuItem(
                      value: PopulationNomogramSource.slopeOrellana19,
                      child: Text('slope_Orellana_19'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) _changePreset(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _nomogramModelSelection(data),
            const SizedBox(height: 12),
            _nomogramModelMetadata(data),
            const SizedBox(height: 12),
            Text(
              _modeGuidance(data),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _filtersPanel(data, visiblePoints),
            const SizedBox(height: 12),
            NomogramChart(
              preset: data.populationPreset,
              observedPoints: points,
              bandPoints: data.resolvedBandPoints,
              showViewportControls: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _nomogramModelSelection(IndividualNomogramData data) {
    final selected = _selectedNomogramMode ?? data.requestedMode;
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
                label: Tooltip(
                  message: 'Uses the study reference only.',
                  child: Text('Study model'),
                ),
              ),
              ButtonSegment(
                value: NomogramMode.hybrid,
                label: Tooltip(
                  message: 'Blends athlete history with the study reference.',
                  child: Text('Hybrid model'),
                ),
              ),
              ButtonSegment(
                value: NomogramMode.individual,
                label: Tooltip(
                  message:
                      'Uses athlete-specific bands when readiness requirements are met.',
                  child: Text('Individual model'),
                ),
              ),
            ],
            selected: {selected},
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

  Widget _nomogramModelMetadata(IndividualNomogramData data) {
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
            _modeLabel(data.requestedMode),
            help: 'Model selected by the user.',
          ),
          _row(
            'Active model',
            _modeLabel(data.activeMode),
            help: 'Model actually used after readiness and fallback rules.',
          ),
          _row(
            'Blend',
            '${data.athleteWeightPercent.toStringAsFixed(0)}% athlete / '
                '${data.populationWeightPercent.toStringAsFixed(0)}% study',
            help: 'Contribution from athlete history and the study reference.',
          ),
          _row('Study preset', data.populationPreset.presetName),
          if (data.requestedMode != data.activeMode)
            _referenceInfo(
              '${_modeLabel(data.requestedMode)} is not available yet. '
              'Using ${_modeLabel(data.activeMode)}.',
            ),
          if (data.activeMode == NomogramMode.hybrid)
            _referenceInfo(
              'Hybrid model blends athlete history with the study reference.',
            ),
          if (data.hasExtrapolatedPoints)
            _referenceInfo(
              'Estimated zone: some intensities are outside the validated range; interpret cautiously.',
              help:
                  'Values outside the validated reference range should be interpreted cautiously.',
            ),
          for (final warning in data.modelWarnings)
            if (!data.hasExtrapolatedPoints ||
                !warning.contains('extrapolated'))
              _referenceInfo(warning),
          if (data.readinessGaps.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Individual model not available yet:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            for (final gap in data.readinessGaps)
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

  Widget _referenceInfo(String text, {String? help}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (help == null)
            const Icon(Icons.info_outline, size: 14, color: AppColors.warning)
          else
            Tooltip(
              message: help,
              triggerMode: TooltipTriggerMode.tap,
              child: const Icon(
                Icons.help_outline,
                size: 14,
                color: AppColors.warning,
              ),
            ),
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

  List<IndividualNomogramPoint> _filteredValidPoints(
    IndividualNomogramData data,
  ) {
    return data.validPoints.where((point) {
      if (_filterDateFrom != null &&
          point.date.compareTo(_filterDateFrom!) < 0) {
        return false;
      }
      if (_filterDateTo != null && point.date.compareTo(_filterDateTo!) > 0) {
        return false;
      }
      final intensityRange = _filterIntensityRange;
      if (intensityRange != null &&
          (point.intensityPercent < intensityRange.start ||
              point.intensityPercent > intensityRange.end)) {
        return false;
      }
      final responses = _filterResponseCategories;
      if (responses != null && !responses.contains(_responseLabel(point))) {
        return false;
      }
      return true;
    }).toList();
  }

  ({double min, double max})? _intensityBounds(IndividualNomogramData data) {
    if (data.validPoints.isEmpty) return null;
    final intensities =
        data.validPoints.map((point) => point.intensityPercent).toList()
          ..sort();
    return (min: intensities.first, max: intensities.last);
  }

  Set<String> _responseOptions(IndividualNomogramData data) {
    return {for (final point in data.validPoints) _responseLabel(point)};
  }

  String _responseLabel(IndividualNomogramPoint point) {
    final label = _classificationLabel(point.classification);
    return label == '-' ? 'Unknown / unavailable' : label;
  }

  int get _activeFilterCount {
    var count = 0;
    if (_filterDateFrom != null) count++;
    if (_filterDateTo != null) count++;
    if (_filterIntensityRange != null) count++;
    if (_filterResponseCategories != null) count++;
    return count;
  }

  void _applyFilters(IndividualNomogramData data) {
    final bounds = _intensityBounds(data);
    final pendingRange = _pendingIntensityRange;
    final responseOptions = _responseOptions(data);
    final pendingResponses = _pendingResponseCategories;
    setState(() {
      _filterDateFrom = _trimmedOrNull(_filterDateFromController.text);
      _filterDateTo = _trimmedOrNull(_filterDateToController.text);
      _filterIntensityRange =
          bounds == null ||
              pendingRange == null ||
              ((pendingRange.start - bounds.min).abs() < 0.001 &&
                  (pendingRange.end - bounds.max).abs() < 0.001)
          ? null
          : pendingRange;
      _filterResponseCategories =
          pendingResponses == null ||
              pendingResponses.length == responseOptions.length
          ? null
          : Set.unmodifiable(pendingResponses);
    });
  }

  void _resetFilters() {
    setState(() {
      _filterDateFromController.clear();
      _filterDateToController.clear();
      _filterDateFrom = null;
      _filterDateTo = null;
      _pendingIntensityRange = null;
      _filterIntensityRange = null;
      _pendingResponseCategories = null;
      _filterResponseCategories = null;
    });
  }

  Widget _filtersPanel(
    IndividualNomogramData data,
    List<IndividualNomogramPoint> visiblePoints,
  ) {
    final bounds = _intensityBounds(data);
    final intensityRange =
        _pendingIntensityRange ??
        _filterIntensityRange ??
        (bounds == null ? null : RangeValues(bounds.min, bounds.max));
    final responseOptions = _responseOptions(data).toList()..sort();
    final selectedResponses =
        _pendingResponseCategories ??
        _filterResponseCategories ??
        responseOptions.toSet();

    return Material(
      key: const Key('individual_nomogram_filters'),
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            key: const Key('individual_nomogram_filters_header'),
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filters ($_activeFilterCount)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Filter nomogram points',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          if (_filtersExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final dateFrom = DateFilterField(
                        controller: _filterDateFromController,
                        label: 'Date from',
                      );
                      final dateTo = DateFilterField(
                        controller: _filterDateToController,
                        label: 'Date to',
                      );
                      if (constraints.maxWidth >= 520) {
                        return Row(
                          children: [
                            Expanded(child: dateFrom),
                            const SizedBox(width: 8),
                            Expanded(child: dateTo),
                          ],
                        );
                      }
                      return Column(
                        children: [dateFrom, const SizedBox(height: 8), dateTo],
                      );
                    },
                  ),
                  if (bounds != null && intensityRange != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Intensity: ${_filterNumber(intensityRange.start)}-${_filterNumber(intensityRange.end)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (bounds.min < bounds.max)
                      SizedBox(
                        height: 36,
                        child: RangeSlider(
                          min: bounds.min,
                          max: bounds.max,
                          values: intensityRange,
                          divisions: 20,
                          onChanged: (values) =>
                              setState(() => _pendingIntensityRange = values),
                        ),
                      ),
                  ],
                  if (responseOptions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recovery status',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final response in responseOptions)
                            FilterChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(response),
                              selected: selectedResponses.contains(response),
                              onSelected: (_) {
                                final next = Set<String>.of(selectedResponses);
                                next.contains(response)
                                    ? next.remove(response)
                                    : next.add(response);
                                setState(
                                  () => _pendingResponseCategories = next,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                  _activeFilterChips(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_activeFilterCount > 0)
                        TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Reset filters'),
                        ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _applyFilters(data),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Apply filters'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Showing ${visiblePoints.length} of ${data.validPoints.length} points',
                key: const Key('individual_nomogram_point_count'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (visiblePoints.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No valid points match the current filters.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _activeFilterChips() {
    final labels = <String>[
      if (_filterDateFrom != null || _filterDateTo != null)
        'Date: ${_filterDateFrom ?? 'start'}-${_filterDateTo ?? 'latest'}',
      if (_filterIntensityRange != null)
        'Intensity: ${_filterNumber(_filterIntensityRange!.start)}-${_filterNumber(_filterIntensityRange!.end)}%',
      if (_filterResponseCategories != null)
        'Recovery status: ${_filterResponseCategories!.join(', ')}',
    ];
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final label in labels)
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(label, style: const TextStyle(fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _filterNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  Widget _pointsList(
    IndividualNomogramData data,
    List<IndividualNomogramPoint> visiblePoints,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valid Points',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (data.validPoints.isEmpty)
              const Text(
                'No valid points yet. Sessions need intensity percent and interpreted slope.',
                style: TextStyle(color: AppColors.textHint),
              )
            else if (visiblePoints.isEmpty)
              const Text(
                'No valid points match the current filters.',
                style: TextStyle(color: AppColors.textHint),
              )
            else
              for (final point in visiblePoints)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(point.taskName ?? point.date),
                  subtitle: Text(
                    [
                      point.date,
                      '${point.intensityPercent.toStringAsFixed(1)}%',
                      'Slope ${point.interpretedSlope.toStringAsFixed(3)}',
                      'Study residual ${_fixed(point.residualPopulation, 3)}',
                      if (point.residualIndividual != null)
                        'Individual residual ${_fixed(point.residualIndividual, 3)}',
                      if (point.residualHybrid != null)
                        'Hybrid residual ${_fixed(point.residualHybrid, 3)}',
                    ].join(' · '),
                  ),
                  trailing: Text(_classificationLabel(point.classification)),
                ),
          ],
        ),
      ),
    );
  }

  Widget _excludedList(IndividualNomogramData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Excluded Sessions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (data.excludedSessions.isEmpty)
              const Text(
                'No sessions excluded from fitting.',
                style: TextStyle(color: AppColors.textHint),
              )
            else
              for (final session in data.excludedSessions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(session.taskName ?? session.date),
                  subtitle: Text(session.date),
                  trailing: Text(session.reason.label),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final data = _data;
    if (data == null) return;
    final writer = ExportFileWriter();
    final points = await writer.writeCsv(
      exportIndividualNomogramValidPointsCsv(data),
    );
    await writer.writeCsv(exportIndividualNomogramExcludedCsv(data));
    await writer.writeCsv(exportIndividualNomogramSummaryCsv(data));
    await writer.writeCsv(exportIndividualNomogramCurvePointsCsv(data));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV exported to ${points.path} and related files'),
      ),
    );
  }
}

Widget _row(String label, String value, {String? help}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 135,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              if (help != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: help,
                  triggerMode: TooltipTriggerMode.tap,
                  child: const Icon(
                    Icons.help_outline,
                    size: 15,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}

Widget _chip(String label, num value, {int digits = 0}) {
  final display = value is double ? value.toStringAsFixed(digits) : '$value';
  return Chip(label: Text('$label: $display'));
}

String _modeGuidance(IndividualNomogramData data) {
  switch (data.activeMode) {
    case NomogramMode.population:
      return 'Study model: lower, mean, and upper bands use the study reference.';
    case NomogramMode.hybrid:
      return 'Hybrid mode: lower, mean, and upper bands blend athlete history with the study reference.';
    case NomogramMode.individual:
      return 'Individual model: lower, mean, and upper bands use athlete-specific history.';
  }
}

String _recommendedModeLabel(IndividualNomogramData data) {
  switch (data.summary.recommendedMode) {
    case IndividualNomogramRecommendedMode.populationOnly:
      return 'Study model';
    case IndividualNomogramRecommendedMode.hybrid:
      return 'Hybrid model';
    case IndividualNomogramRecommendedMode.individual:
      return 'Individual model';
  }
}

String _confidenceGuidance(IndividualNomogramData data) {
  switch (data.summary.recommendedMode) {
    case IndividualNomogramRecommendedMode.populationOnly:
      return 'Use the Study model while more valid athlete history is collected.';
    case IndividualNomogramRecommendedMode.hybrid:
      return 'Use the Hybrid model while athlete-specific confidence develops.';
    case IndividualNomogramRecommendedMode.individual:
      return 'The athlete history supports the Individual model.';
  }
}

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

String _fixed(double? value, int digits) =>
    value == null ? '-' : value.toStringAsFixed(digits);

String _classificationLabel(String? value) {
  return recoveryResponseShortLabelForClassificationKey(value);
}
