/// Individual Report Screen — Read-only scientific session report.
///
/// Phase 3.0: Displays header, warnings, variables, HRV data,
/// slope result, and population nomogram chart.
library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/export/csv_export_service.dart';
import 'package:hrv_slope_app/data/export/export_file_writer.dart';
import 'package:hrv_slope_app/shared/engine/individual_report_builder.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_engine.dart';
import 'package:hrv_slope_app/shared/engine/nomogram_mode.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/nomogram_chart.dart';

class IndividualReportScreen extends StatefulWidget {
  final AppDatabase database;
  final int sessionId;

  const IndividualReportScreen({
    super.key,
    required this.database,
    required this.sessionId,
  });

  @override
  State<IndividualReportScreen> createState() => _IndividualReportScreenState();
}

class _IndividualReportScreenState extends State<IndividualReportScreen> {
  final ScrollController _scrollController = ScrollController();
  IndividualReportData? _report;
  int? _athleteId;
  NomogramMode _selectedNomogramMode = NomogramMode.population;
  bool _loading = true;
  bool _refreshingNomogram = false;
  String? _error;
  String? _nomogramRefreshError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refreshNomogram = false}) async {
    final keepCurrentReport = refreshNomogram && _report != null;
    final requestedMode = _selectedNomogramMode;

    if (mounted && (keepCurrentReport || !_loading)) {
      setState(() {
        if (keepCurrentReport) {
          _refreshingNomogram = true;
        } else {
          _loading = true;
        }
        _error = null;
        _nomogramRefreshError = null;
      });
    }

    try {
      final detail = await widget.database.sessionsDao.getSessionDetail(
        widget.sessionId,
      );
      if (detail == null) {
        if (mounted) {
          setState(() {
            _error = 'Session not found';
            _report = null;
            _loading = false;
          });
        }
        return;
      }

      // Get active nomogram preset from settings
      final presetName = await widget.database.settingsDao.getSetting(
        'nomogram_preset',
      );
      final preset = parsePopulationNomogramSource(presetName);
      final athleteHistory = await widget.database.sessionsDao
          .getSessionDetailsForAthlete(detail.athlete.id);

      final report = buildIndividualReport(
        detail: detail,
        nomogramPreset: preset,
        requestedNomogramMode: requestedMode,
        athleteHistory: athleteHistory,
      );

      if (mounted) {
        if (requestedMode != _selectedNomogramMode) return;
        setState(() {
          _report = report;
          _athleteId = detail.athlete.id;
          _loading = false;
          _refreshingNomogram = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (keepCurrentReport) {
            _nomogramRefreshError = e.toString();
          } else {
            _error = e.toString();
            _report = null;
          }
          _loading = false;
          _refreshingNomogram = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _report == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report')),
        body: Center(child: Text(_error!)),
      );
    }
    final r = _report!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Report'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _report == null ? null : _exportCsv,
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'Report info',
            onPressed: () => _showInfo(context),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(r),
          if (r.warnings.isNotEmpty) _buildWarnings(r.warnings),
          _buildExternalLoad(r),
          _buildInternalLoad(r),
          _buildHrvSection(r),
          _buildSlopeResult(r),
          _buildNomogramSection(r),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNomogramModelSelection() {
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
                : (selection) {
                    final mode = selection.first;
                    if (mode == _selectedNomogramMode) return;
                    setState(() {
                      _selectedNomogramMode = mode;
                    });
                    _load(refreshNomogram: true);
                  },
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
        if (_nomogramRefreshError != null)
          _infoChip('Could not update model: $_nomogramRefreshError'),
      ],
    );
  }

  // ── Section 1: Header ──

  Widget _buildHeader(IndividualReportData r) {
    return _card(
      'Session',
      icon: Icons.person,
      children: [
        _row('Athlete', r.athleteName),
        _row('Sport', r.sport),
        _row('Date', r.sessionDate),
        _row('Task / Session', r.taskName),
        _row('Session type', r.sessionType),
        if (r.protocolName != null) _row('Protocol', r.protocolName),
        if (r.contextEnvironment != null) _row('Context', r.contextEnvironment),
        if (r.isDraft)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Chip(
              label: const Text('DRAFT'),
              backgroundColor: AppColors.warning.withValues(alpha: 0.2),
              side: const BorderSide(color: AppColors.warning),
            ),
          ),
      ],
    );
  }

  // ── Section 2: Warnings ──

  Widget _buildWarnings(List<String> warnings) {
    return _card(
      'Data Completeness / Warnings',
      icon: Icons.warning_amber,
      headerColor: AppColors.warning,
      children: [
        for (final w in warnings)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    w,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Section 3: External Load ──

  Widget _buildExternalLoad(IndividualReportData r) {
    return _card(
      'External Load',
      icon: Icons.fitness_center,
      children: [
        if (r.externalVariables.isEmpty)
          const Text(
            'None recorded',
            style: TextStyle(color: AppColors.textHint),
          )
        else
          for (final v in r.externalVariables) _variableRow(v),
      ],
    );
  }

  // ── Section 4: Internal Load ──

  Widget _buildInternalLoad(IndividualReportData r) {
    return _card(
      'Internal Load',
      icon: Icons.favorite_border,
      children: [
        if (r.internalVariables.isEmpty)
          const Text(
            'None recorded',
            style: TextStyle(color: AppColors.textHint),
          )
        else
          for (final v in r.internalVariables) _variableRow(v),
      ],
    );
  }

  // ── Section 5: HRV / RMSSD ──

  Widget _buildHrvSection(IndividualReportData r) {
    final h = r.hrvSummary;
    return _card(
      'HRV / RMSSD',
      icon: Icons.monitor_heart,
      children: [
        _row('Input mode', _formatInputMode(h.inputMode)),
        _row('RMSSD recovery', _ms(h.rmssdRecovery)),
        _row('Recovery source', _formatSource(h.rmssdRecoverySource)),
        _row('RMSSD exercise', _ms(h.rmssdExercise)),
        _row('Exercise source', _formatSource(h.rmssdExerciseSource)),
        if (h.usedFallbackExercise)
          _infoChip('Fallback 4 ms used for exercise RMSSD'),
        const Divider(height: 20),
        _row(
          'Recovery window',
          h.recoveryWindowStartMin != null && h.recoveryWindowEndMin != null
              ? '${h.recoveryWindowStartMin!.toStringAsFixed(0)}–${h.recoveryWindowEndMin!.toStringAsFixed(0)} min'
              : null,
        ),
        _row(
          'Window duration',
          h.recoveryWindowStartMin != null && h.recoveryWindowEndMin != null
              ? '${(h.recoveryWindowEndMin! - h.recoveryWindowStartMin!).toStringAsFixed(0)} min'
              : null,
        ),
        _row(
          't used for slope',
          h.tUsedForSlope != null
              ? '${h.tUsedForSlope!.toStringAsFixed(1)} min'
              : null,
        ),
        // RR preprocessing (only for rr_intervals mode)
        if (h.inputMode == 'rr_intervals') ...[
          const Divider(height: 20),
          Text(
            'RR Preprocessing',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          _row('Raw RMSSD', _ms(h.rrRawRmssd)),
          _row('Corrected RMSSD', _ms(h.rrCorrectedRmssd)),
          _row('RMSSD used', _ms(h.rrRmssdUsed)),
          _row('Correction enabled', h.rrCorrectionEnabled ? 'Yes' : 'No'),
          _row('Correction method', h.rrCorrectionMethod),
          _row('Artifact count', h.rrArtifactCount?.toString()),
          _row(
            'Artifact %',
            h.rrArtifactPercent != null
                ? '${h.rrArtifactPercent!.toStringAsFixed(2)}%'
                : null,
          ),
          _row('Quality decision', h.rrQualityDecision),
          if (h.rrQualityNotes.isNotEmpty)
            _row('Quality notes', h.rrQualityNotes.join('; ')),
          if (h.rrRmssdDeltaPercent != null)
            _row('Δ RMSSD', '${h.rrRmssdDeltaPercent!.toStringAsFixed(2)}%'),
        ],
      ],
    );
  }

  // ── Section 6: Slope Result ──

  Widget _buildSlopeResult(IndividualReportData r) {
    final s = r.slopeSummary;
    final n = r.nomogramSummary;

    return _card(
      'RMSSD-Slope Result',
      icon: Icons.trending_up,
      children: [
        if (r.isDraft)
          const Text(
            'Draft session — slope not calculated.',
            style: TextStyle(color: AppColors.warning),
          )
        else ...[
          _slopeValueRow(
            'Raw slope',
            s.rawSlope,
            4,
            help:
                'Original RMSSD-Slope value calculated or entered for the session.',
          ),
          _slopeValueRow(
            'Interpreted slope',
            s.interpretedSlope,
            4,
            help:
                'Slope value used for interpretation after applying the app rules.',
          ),
          _slopeValueRow(
            'ITL index',
            s.itlIndex,
            4,
            help:
                'Internal training load index used to contextualize the session response.',
          ),
          _row(
            'Intensity %',
            s.intensityPercent != null
                ? '${s.intensityPercent!.toStringAsFixed(1)}%'
                : 'Not available',
            help: 'Session intensity used to query the nomogram reference.',
          ),
          _row(
            'Intensity source',
            s.intensitySourceForSlope,
            help:
                'Whether intensity came from external intensity, internal fallback, or another available source.',
          ),
          _row('Primary intensity metric', s.primaryIntensityMetric),
          if (n != null) ...[
            const Divider(height: 20),
            _row(
              'Residual',
              n.residual.toStringAsFixed(4),
              help: 'Difference between observed slope and expected mean.',
            ),
            _row(
              'Residual %',
              '${n.residualPercent.toStringAsFixed(1)}%',
              help: 'Residual expressed relative to the expected mean.',
            ),
            _classificationChip(
              n.classification,
              n.classificationLabel,
              help: 'Classification based on the selected model bands.',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _classColor(n.classification).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _classColor(n.classification).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                n.interpretationText,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
          ],
          if (n == null && !r.isDraft)
            _infoChip('Intensity percent is required for nomogram placement.'),
        ],
      ],
    );
  }

  // ── Section 7: Nomogram Chart ──

  Widget _buildNomogramSection(IndividualReportData r) {
    final n = r.nomogramSummary;

    if (!r.canShowNomogram || n == null) {
      return _card(
        'Nomogram Reference',
        icon: Icons.auto_graph,
        children: [
          _buildNomogramModelSelection(),
          const SizedBox(height: 12),
          const Text(
            'Intensity percent is required for nomogram placement.',
            style: TextStyle(color: AppColors.textHint),
          ),
        ],
      );
    }

    return _card(
      'Nomogram Reference',
      icon: Icons.auto_graph,
      children: [
        _buildNomogramModelSelection(),
        const SizedBox(height: 12),
        _buildNomogramModelMetadata(n),
        const Divider(height: 20),
        _row('Preset', n.presetName),
        _row(
          'Expected lower',
          n.expectedLower.toStringAsFixed(3),
          help: 'Lower reference band limit for the selected model.',
        ),
        _row(
          'Expected mean',
          n.expectedMean.toStringAsFixed(3),
          help: 'Expected RMSSD-Slope for this intensity and selected model.',
        ),
        _row(
          'Expected upper',
          n.expectedUpper.toStringAsFixed(3),
          help: 'Upper reference band limit for the selected model.',
        ),
        _row('Observed slope', n.observedSlope.toStringAsFixed(3)),
        _row(
          'Response',
          n.classificationLabel,
          help: 'Classification based on the selected model bands.',
        ),
        if (n.activeMode != NomogramMode.population)
          _infoChip(
            'Chart background shows the study reference; values above use the active model.',
          ),
        const SizedBox(height: 16),
        // The chart
        NomogramChart(
          preset: parsePopulationNomogramSource(n.presetName),
          observedPoints: [
            NomogramObservedPoint(
              xIntensityPercent: n.intensityPercent,
              ySlope: n.observedSlope,
              label: r.taskName ?? r.sessionDate,
              classification: n.classificationLabel,
              isExtrapolated: n.isExtrapolated,
            ),
          ],
          showViewportControls: true,
        ),
      ],
    );
  }

  Widget _buildNomogramModelMetadata(NomogramReportSummary n) {
    final notes = _modelNotes(n);
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
            _modeLabel(n.requestedMode),
            help: 'Model selected for this report calculation.',
          ),
          _row(
            'Active model',
            _modeLabel(n.activeMode),
            help: 'Model actually used after readiness and fallback rules.',
          ),
          _row(
            'Blend',
            '${n.athleteWeightPercent.toStringAsFixed(0)}% athlete / '
                '${n.populationWeightPercent.toStringAsFixed(0)}% study',
          ),
          if (n.requestedMode != n.activeMode)
            _infoChip(_fallbackMessage(n.requestedMode, n.activeMode)),
          if (n.isExtrapolated)
            _infoChip(
              'Estimated zone: intensity is outside the validated reference range.',
            ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final note in notes) _infoChip(note),
          ],
          if (n.readinessGaps.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Individual model not available yet:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            for (final gap in n.readinessGaps)
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

  // ── Shared widgets ──

  Widget _card(
    String title, {
    required IconData icon,
    required List<Widget> children,
    Color? headerColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: headerColor ?? AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: headerColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value, {String? help}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: _labelWithTooltip(label, help)),
          Expanded(
            child: Text(
              value == null || value.isEmpty ? '–' : value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelWithTooltip(String label, String? help) {
    final text = Text(
      label,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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

  Widget _variableRow(IntensityVariable v) {
    final isPrimary = v.isPrimaryForNomogram;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                if (isPrimary)
                  const Icon(Icons.star, size: 12, color: AppColors.tertiary),
                if (isPrimary) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    v.name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${v.value.toStringAsFixed(2)} ${v.unit ?? ''}'.trim(),
            style: const TextStyle(fontSize: 13),
          ),
          if (v.source != null) ...[
            const SizedBox(width: 8),
            Text(
              '(${v.source})',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ],
      ),
    );
  }

  Widget _slopeValueRow(
    String label,
    double? value,
    int digits, {
    String? help,
  }) {
    return _row(
      label,
      value != null ? value.toStringAsFixed(digits) : '–',
      help: help,
    );
  }

  Widget _classificationChip(
    InternalLoadClassification c,
    String label, {
    String? help,
  }) {
    final color = _classColor(c);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: help == null
          ? chip
          : Tooltip(
              message: help,
              triggerMode: TooltipTriggerMode.tap,
              child: chip,
            ),
    );
  }

  Widget _infoChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
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

  Color _classColor(InternalLoadClassification c) {
    switch (c) {
      case InternalLoadClassification.veryHighInternalLoad:
        return AppColors.classVeryHigh;
      case InternalLoadClassification.highOrModerateInternalLoad:
        return AppColors.classHighMod;
      case InternalLoadClassification.expectedResponse:
        return AppColors.classExpected;
      case InternalLoadClassification.lowInternalLoadOrFastRecovery:
        return AppColors.classLowFast;
    }
  }

  String _formatInputMode(String mode) {
    switch (mode) {
      case 'direct_rmssd':
        return 'Direct RMSSD';
      case 'rr_intervals':
        return 'RR Intervals';
      default:
        return mode;
    }
  }

  String? _formatSource(String? source) {
    if (source == null) return null;
    return source.replaceAll('_', ' ');
  }

  String? _ms(double? value) =>
      value == null ? null : '${value.toStringAsFixed(2)} ms';

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

  String _fallbackMessage(NomogramMode requested, NomogramMode active) {
    return 'Requested ${_modeLabel(requested).toLowerCase()} is not available yet. '
        'Using ${_modeLabel(active).toLowerCase()}.';
  }

  List<String> _modelNotes(NomogramReportSummary n) {
    final seen = <String>{};
    final notes = <String>[];
    for (final warning in n.warnings) {
      if (n.isExtrapolated && warning.contains('extrapolated')) continue;
      if (seen.add(warning)) notes.add(warning);
    }
    return notes;
  }

  Future<void> _exportCsv() async {
    final report = _report;
    if (report == null) return;
    final export = exportIndividualReportCsv(
      report,
      athleteId: _athleteId,
      sessionId: widget.sessionId,
    );
    final result = await ExportFileWriter().writeCsv(export);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CSV exported to ${result.path}')));
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About this report'),
        content: const Text(
          'This report uses the RMSSD-Slope method (Naranjo Orellana et al., '
          '2019) to evaluate autonomic recovery from exercise.\n\n'
          'Recovery response is based on comparison to the selected nomogram model. '
          'Results should be interpreted in context of the athlete\'s training '
          'history and external factors.\n\n'
          'This tool provides training insights and is not a medical '
          'diagnostic instrument.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
