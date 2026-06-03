library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/data/services/session_edit_service.dart';
import 'package:hrv_slope_app/shared/engine/intensity_resolver.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/ui/screens/reports/individual_report_screen.dart';
import 'package:hrv_slope_app/ui/screens/session/session_edit_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class SessionDetailScreen extends StatefulWidget {
  final AppDatabase database;
  final int sessionId;

  const SessionDetailScreen({
    super.key,
    required this.database,
    required this.sessionId,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  SessionDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final detail = await widget.database.sessionsDao.getSessionDetail(
      widget.sessionId,
    );
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
    }
  }

  Future<void> _edit() async {
    final detail = _detail;
    if (detail == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionEditScreen(
          database: widget.database,
          sessionId: detail.session.id,
        ),
      ),
    );
    if (changed == true) {
      await _load();
    }
  }

  void _openReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IndividualReportScreen(
          database: widget.database,
          sessionId: widget.sessionId,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final detail = _detail;
    if (detail == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text(
          'Delete ${detail.session.taskName ?? 'this session'} for '
          '${detail.athlete.name} on ${detail.session.date}? This cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete session'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await SessionEditService(
      widget.database,
    ).deleteSessionCascade(detail.session.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session deleted')));
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final detail = _detail;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: const Center(child: Text('Session not found')),
      );
    }

    final session = detail.session;
    final external = detail.variablesByCategory('external');
    final internal = detail.variablesByCategory('internal');
    final derived = detail.variablesByCategory('derived');
    final qualityNotes = _qualityNotes(session.rrQualityNotesJson);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.taskName ?? 'Session'),
        actions: [
          IconButton(
            tooltip: 'Open Report',
            onPressed: () => _openReport(),
            icon: const Icon(Icons.assessment),
          ),
          IconButton(
            tooltip: 'Edit session',
            onPressed: _edit,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Delete session',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Session', [
            _row('Athlete', detail.athlete.name),
            _row('Date/time', session.date),
            _row('Task/session', session.taskName),
            _row('Sport', session.sport),
            _row('Session type', session.sessionType),
            _row('Protocol', session.protocolName),
            _row('Context/environment', session.contextEnvironment),
            _row('Notes', session.notes),
            _row('Status', session.isDraft ? 'Draft' : 'Complete'),
          ]),
          _variablesSection('External variables', external),
          _variablesSection('Internal variables', internal),
          _section('HRV data', [
            _row('Input mode', session.hrvInputMode ?? 'direct_rmssd'),
            _row('RMSSD recovery', _ms(session.rmssdRecovery)),
            _row('RMSSD exercise', _ms(session.rmssdExercise)),
            _row(
              'Exercise fallback',
              session.rmssdExerciseIsDefault ? 'yes' : 'no',
            ),
            _row('Recovery window start', _min(session.recoveryWindowStartMin)),
            _row('Recovery window end', _min(session.recoveryWindowEndMin)),
            _row('t used for slope', _min(session.recoveryTimeMin)),
            _row(
              'Raw slope',
              session.isDraft ? null : _fixed(session.slopeRaw, 3),
            ),
            _row(
              'Interpreted slope',
              session.isDraft ? null : _fixed(session.slopeInterpreted, 3),
            ),
            _row(
              'ITL index',
              session.isDraft ? null : _fixed(session.itlIndex, 3),
            ),
            _row('Intensity %', _fixed(session.intensityPercent, 1)),
            _row(
              'Intensity source',
              intensitySourceForSlopeLabel(session.intensitySource),
            ),
            _row(
              'Primary intensity metric',
              primaryIntensityMetricFromMethod(session.intensitySource),
            ),
            _row(
              'Response',
              session.isDraft
                  ? 'Draft: not calculated'
                  : recoveryResponseLabelForClassificationKey(
                      session.classification,
                    ),
            ),
          ]),
          if (session.hrvInputMode == 'rr_intervals')
            _section('RR preprocessing summary', [
              _row('Raw RMSSD', _ms(session.rrRawRmssd)),
              _row('Corrected RMSSD', _ms(session.rrCorrectedRmssd)),
              _row('RMSSD used', _ms(session.rrRmssdUsed)),
              _row(
                'Correction enabled',
                session.rrCorrectionEnabled ? 'yes' : 'no',
              ),
              _row('Correction method', session.rrCorrectionMethod),
              _row('Artifact count', session.rrArtifactCount?.toString()),
              _row(
                'Artifact %',
                session.rrArtifactPercent == null
                    ? null
                    : '${session.rrArtifactPercent!.toStringAsFixed(2)}%',
              ),
              _row('Quality decision', session.rrQualityDecision),
              _row(
                'Quality notes',
                qualityNotes.isEmpty ? null : qualityNotes.join('; '),
              ),
            ]),
          if (derived.isNotEmpty) _variablesSection('Derived values', derived),
        ],
      ),
    );
  }
}

Widget _section(String title, List<Widget> children) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );
}

Widget _variablesSection(String title, List<IntensityVariable> variables) {
  return _section(title, [
    if (variables.isEmpty)
      const Text('None', style: TextStyle(color: AppColors.textHint))
    else
      for (final v in variables)
        _row(v.name, '${v.value.toStringAsFixed(2)} ${v.unit ?? ''}'.trim()),
  ]);
}

Widget _row(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value == null || value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

String? _fixed(double? value, int digits) => value?.toStringAsFixed(digits);
String? _ms(double? value) =>
    value == null ? null : '${value.toStringAsFixed(2)} ms';
String? _min(double? value) =>
    value == null ? null : '${value.toStringAsFixed(1)} min';

List<String> _qualityNotes(String? jsonText) {
  if (jsonText == null || jsonText.isEmpty) return const [];
  try {
    final decoded = jsonDecode(jsonText);
    if (decoded is List) return decoded.map((e) => e.toString()).toList();
  } catch (_) {
    return [jsonText];
  }
  return const [];
}
