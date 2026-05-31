/// RR Input Widget - Paste/load RR intervals, preprocess, and compute RMSSD.
// ignore_for_file: deprecated_member_use

library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/shared/engine/rr_parser.dart';
import 'package:hrv_slope_app/shared/engine/rr_preprocessing.dart';
import 'package:hrv_slope_app/shared/engine/rr_quality.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

/// Result from the RR input widget.
class RrInputResult {
  final double rmssd;
  final double rawRmssd;
  final double? correctedRmssd;
  final RrQualityReport quality;
  final RrPreprocessingResult preprocessing;
  final int rrCount;
  final double durationSec;

  const RrInputResult({
    required this.rmssd,
    required this.rawRmssd,
    required this.correctedRmssd,
    required this.quality,
    required this.preprocessing,
    required this.rrCount,
    required this.durationSec,
  });
}

enum _RrMethodChoice {
  rangeOnly('Range only'),
  malik('Malik + linear interpolation'),
  karlsson('Karlsson + linear interpolation'),
  localMedian('Local median threshold');

  final String label;
  const _RrMethodChoice(this.label);
}

class RrInputWidget extends StatefulWidget {
  final String label;
  final ValueChanged<RrInputResult?> onResult;

  const RrInputWidget({super.key, required this.label, required this.onResult});

  @override
  State<RrInputWidget> createState() => _RrInputWidgetState();
}

class _RrInputWidgetState extends State<RrInputWidget> {
  final _ctrl = TextEditingController();
  final _lowCtrl = TextEditingController(text: '300');
  final _highCtrl = TextEditingController(text: '2200');
  final _warningCtrl = TextEditingController(text: '5');
  final _invalidCtrl = TextEditingController(text: '10');

  RrParseResult? _parsed;
  RrQualityReport? _quality;
  RrPreprocessingResult? _preprocessing;
  String? _error;
  bool _correctionEnabled = false;
  _RrMethodChoice _method = _RrMethodChoice.karlsson;
  LocalMedianThresholdPreset _thresholdPreset =
      LocalMedianThresholdPreset.medium;

  @override
  void dispose() {
    _ctrl.dispose();
    _lowCtrl.dispose();
    _highCtrl.dispose();
    _warningCtrl.dispose();
    _invalidCtrl.dispose();
    super.dispose();
  }

  void _parse() {
    final result = parseRrIntervals(_ctrl.text);
    setState(() {
      _parsed = result;
      _error = null;
      _quality = null;
      _preprocessing = null;
    });

    if (!result.hasData) {
      setState(() => _error = 'No valid RR intervals found.');
      widget.onResult(null);
      return;
    }

    _recomputeFromParsed();
  }

  void _recomputeFromParsed() {
    final parsed = _parsed;
    if (parsed == null || !parsed.hasData) return;

    final preprocessing = preprocessRrIntervals(
      parsed.rrIntervalsMs,
      _buildOptions(),
    );
    final quality = _qualityFromPreprocessing(preprocessing);

    setState(() {
      _preprocessing = preprocessing;
      _quality = quality;
      _error = preprocessing.qualityDecision == RrQualityDecision.invalid
          ? 'Quality invalid: ${preprocessing.qualityNotes.join("; ")}'
          : null;
    });

    if (preprocessing.qualityDecision == RrQualityDecision.invalid) {
      widget.onResult(null);
      return;
    }

    widget.onResult(
      RrInputResult(
        rmssd: preprocessing.rmssdUsed,
        rawRmssd: preprocessing.rawRmssd,
        correctedRmssd: preprocessing.correctedRmssd,
        quality: quality,
        preprocessing: preprocessing,
        rrCount: parsed.rrIntervalsMs.length,
        durationSec: preprocessing.durationRawSec,
      ),
    );
  }

  RrPreprocessingOptions _buildOptions() {
    return RrPreprocessingOptions(
      lowRriMs: double.tryParse(_lowCtrl.text) ?? 300,
      highRriMs: double.tryParse(_highCtrl.text) ?? 2200,
      mode: switch (_method) {
        _RrMethodChoice.rangeOnly => RrPreprocessingMode.rangeOnly,
        _RrMethodChoice.malik => RrPreprocessingMode.rangeAndEctopic,
        _RrMethodChoice.karlsson => RrPreprocessingMode.rangeAndEctopic,
        _RrMethodChoice.localMedian => RrPreprocessingMode.localMedianThreshold,
      },
      ectopicMethod: switch (_method) {
        _RrMethodChoice.malik => RrCorrectionMethod.malikLinearInterpolation,
        _ => RrCorrectionMethod.karlssonLinearInterpolation,
      },
      localMedianThresholdMs: _thresholdPreset.thresholdMs,
      artifactWarningPercent: double.tryParse(_warningCtrl.text) ?? 5,
      artifactInvalidPercent: double.tryParse(_invalidCtrl.text) ?? 10,
      correctionEnabled: _correctionEnabled,
    );
  }

  RrQualityReport _qualityFromPreprocessing(RrPreprocessingResult result) {
    final raw = result.rawRrIntervals;
    final valid = raw.where((v) => v > 300 && v < 2200).toList();
    final flag = switch (result.qualityDecision) {
      RrQualityDecision.valid => RrQualityFlag.valid,
      RrQualityDecision.warning => RrQualityFlag.warning,
      RrQualityDecision.invalid => RrQualityFlag.invalid,
    };

    return RrQualityReport(
      rrCount: raw.length,
      recordingDurationSec: result.durationRawSec,
      meanRrMs: valid.isEmpty
          ? null
          : valid.reduce((a, b) => a + b) / valid.length,
      minRrMs: valid.isEmpty ? null : valid.reduce((a, b) => a < b ? a : b),
      maxRrMs: valid.isEmpty ? null : valid.reduce((a, b) => a > b ? a : b),
      artifactCountEstimate: result.artifactCount,
      artifactPercentEstimate: result.artifactPercent,
      qualityFlag: flag,
      qualityNotes: result.qualityNotes,
    );
  }

  void _onOptionsChanged() {
    if (_parsed?.hasData ?? false) {
      _recomputeFromParsed();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final preprocessing = _preprocessing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText:
                'Paste RR intervals (ms)\none per line, comma, semicolon, or tab separated',
          ),
        ),
        const SizedBox(height: 12),
        _preprocessingControls(),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _parse,
          icon: const Icon(Icons.analytics, size: 18),
          label: const Text('Parse & Compute RMSSD'),
        ),
        if (_parsed != null) ...[
          const SizedBox(height: 12),
          _infoTile(
            'Parsed',
            '${_parsed!.rrIntervalsMs.length} valid, '
                '${_parsed!.invalidTokens.length} invalid',
          ),
          if (_parsed!.hasData) ...[
            _infoTile(
              'Duration',
              '${(_parsed!.rrIntervalsMs.fold(0.0, (s, v) => s + v) / 1000).toStringAsFixed(1)} sec',
            ),
            _infoTile(
              'Min RR',
              '${_parsed!.rrIntervalsMs.reduce((a, b) => a < b ? a : b).toStringAsFixed(0)} ms',
            ),
            _infoTile(
              'Max RR',
              '${_parsed!.rrIntervalsMs.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)} ms',
            ),
            _infoTile(
              'Mean RR',
              '${(_parsed!.rrIntervalsMs.fold(0.0, (s, v) => s + v) / _parsed!.rrIntervalsMs.length).toStringAsFixed(1)} ms',
            ),
          ],
        ],
        if (_quality != null && preprocessing != null) ...[
          const SizedBox(height: 8),
          _infoTile(
            'Artifacts',
            '${preprocessing.artifactCount} '
                '(${preprocessing.artifactPercent.toStringAsFixed(2)}%)',
          ),
          _infoTile('Correction', preprocessing.correctionMethod.name),
          _infoTile(
            'Quality',
            preprocessing.qualityDecision.name,
            color: preprocessing.qualityDecision == RrQualityDecision.valid
                ? AppColors.success
                : preprocessing.qualityDecision == RrQualityDecision.warning
                ? AppColors.warning
                : AppColors.error,
          ),
          if (preprocessing.qualityNotes.isNotEmpty)
            ...preprocessing.qualityNotes.map(
              (n) => _infoTile('Note', n, color: AppColors.textSecondary),
            ),
          if (preprocessing.warnings.isNotEmpty)
            ...preprocessing.warnings.map(
              (n) => _infoTile('Warning', n, color: AppColors.warning),
            ),
        ],
        if (preprocessing != null) ...[
          const SizedBox(height: 8),
          _rmssdPanel(preprocessing),
          if (preprocessing.artifactEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            _artifactTable(preprocessing.artifactEvents),
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _preprocessingControls() {
    return Card(
      color: AppColors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RR preprocessing',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Correction'),
              subtitle: Text(
                _correctionEnabled
                    ? 'On: compute corrected NN-derived RMSSD'
                    : 'Off: use raw RR-derived RMSSD, report artifacts only',
              ),
              value: _correctionEnabled,
              onChanged: (value) {
                setState(() => _correctionEnabled = value);
                _onOptionsChanged();
              },
            ),
            DropdownButtonFormField<_RrMethodChoice>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Method'),
              items: _RrMethodChoice.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _method = value);
                _onOptionsChanged();
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<LocalMedianThresholdPreset>(
              value: _thresholdPreset,
              decoration: const InputDecoration(
                labelText: 'Local median threshold',
              ),
              items: LocalMedianThresholdPreset.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} ${p.thresholdMs.toInt()} ms'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _thresholdPreset = value);
                _onOptionsChanged();
              },
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Advanced settings'),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lowCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Low RR threshold',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onOptionsChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _highCtrl,
                        decoration: const InputDecoration(
                          labelText: 'High RR threshold',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onOptionsChanged(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _warningCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Warning artifact %',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onOptionsChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _invalidCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Invalid artifact %',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onOptionsChanged(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rmssdPanel(RrPreprocessingResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'RMSSD used: ${result.rmssdUsed.toStringAsFixed(2)} ms',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _infoTile('Raw RMSSD', '${result.rawRmssd.toStringAsFixed(2)} ms'),
          if (result.correctedRmssd != null)
            _infoTile(
              'Corrected RMSSD',
              '${result.correctedRmssd!.toStringAsFixed(2)} ms',
            ),
          if (result.rmssdDelta != null)
            _infoTile(
              'RMSSD delta',
              '${result.rmssdDelta!.toStringAsFixed(2)} ms',
            ),
          if (result.rmssdDeltaPercent != null)
            _infoTile(
              'RMSSD delta %',
              '${result.rmssdDeltaPercent!.toStringAsFixed(1)}%',
            ),
        ],
      ),
    );
  }

  Widget _artifactTable(List<RrArtifactEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Artifact table', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Index')),
              DataColumn(label: Text('Value')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Replacement')),
              DataColumn(label: Text('Reason')),
            ],
            rows: [
              for (final event in events)
                DataRow(
                  cells: [
                    DataCell(Text(event.index.toString())),
                    DataCell(Text(event.originalValueMs.toStringAsFixed(0))),
                    DataCell(Text(event.artifactType.name)),
                    DataCell(
                      Text(
                        event.proposedReplacementMs?.toStringAsFixed(0) ?? '-',
                      ),
                    ),
                    DataCell(Text(event.reason)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}
