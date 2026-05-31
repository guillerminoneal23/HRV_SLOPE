library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/core/constants/hrv_sources.dart';
import 'package:hrv_slope_app/core/constants/session_constants.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/sessions_dao.dart';
import 'package:hrv_slope_app/data/services/reusable_tag_service.dart';
import 'package:hrv_slope_app/data/services/session_edit_service.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/widgets/reusable_tag_text_field.dart';

class SessionEditScreen extends StatefulWidget {
  final AppDatabase database;
  final int sessionId;

  const SessionEditScreen({
    super.key,
    required this.database,
    required this.sessionId,
  });

  @override
  State<SessionEditScreen> createState() => _SessionEditScreenState();
}

class _SessionEditScreenState extends State<SessionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateCtrl = TextEditingController();
  final _taskCtrl = TextEditingController();
  final _sportCtrl = TextEditingController();
  final _protocolCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _rmssdRecoveryCtrl = TextEditingController();
  final _rmssdExerciseCtrl = TextEditingController();
  final _windowStartCtrl = TextEditingController();
  final _windowEndCtrl = TextEditingController();
  final Map<String, TextEditingController> _externalCtrls = {};
  final Map<String, TextEditingController> _internalCtrls = {};
  late final ReusableTagService _tagService;
  Map<ReusableTagCategory, List<ReusableTag>> _tags = {};

  SessionDetail? _detail;
  SessionType _sessionType = SessionType.training;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tagService = ReusableTagService(widget.database.settingsDao);
    for (final v in StandardVariables.externalVariables) {
      _externalCtrls[v.name] = TextEditingController();
    }
    for (final v in StandardVariables.internalVariables) {
      _internalCtrls[v.name] = TextEditingController();
    }
    _loadTags();
    _load();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _taskCtrl.dispose();
    _sportCtrl.dispose();
    _protocolCtrl.dispose();
    _contextCtrl.dispose();
    _notesCtrl.dispose();
    _rmssdRecoveryCtrl.dispose();
    _rmssdExerciseCtrl.dispose();
    _windowStartCtrl.dispose();
    _windowEndCtrl.dispose();
    for (final c in [..._externalCtrls.values, ..._internalCtrls.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final detail = await widget.database.sessionsDao.getSessionDetail(
      widget.sessionId,
    );
    if (detail == null) {
      if (mounted) {
        setState(() {
          _error = 'Session not found.';
          _loading = false;
        });
      }
      return;
    }
    final session = detail.session;
    _dateCtrl.text = session.date;
    _taskCtrl.text = session.taskName ?? '';
    _sportCtrl.text = session.sport ?? '';
    _protocolCtrl.text = session.protocolName ?? '';
    _contextCtrl.text = session.contextEnvironment ?? '';
    _notesCtrl.text = session.notes ?? '';
    _rmssdRecoveryCtrl.text = session.rmssdRecovery?.toString() ?? '';
    _rmssdExerciseCtrl.text = session.rmssdExerciseIsDefault
        ? ''
        : session.rmssdExercise?.toString() ?? '';
    _windowStartCtrl.text = session.recoveryWindowStartMin?.toString() ?? '5';
    _windowEndCtrl.text = session.recoveryWindowEndMin?.toString() ?? '10';
    _sessionType =
        SessionType.fromString(session.sessionType) ?? SessionType.training;
    for (final v in detail.variables) {
      if (v.category == 'external') {
        _externalCtrls[v.name]?.text = v.value.toString();
      }
      if (v.category == 'internal') {
        _internalCtrls[v.name]?.text = v.value.toString();
      }
    }
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
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

  List<SessionType> get _sessionTypeOptions {
    final options = [...SessionTypeOptions.newSessionOptions];
    if (!options.contains(_sessionType)) {
      options.add(_sessionType);
    }
    return options;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SessionEditService(widget.database).updateDirectRmssdSession(
        SessionEditInput(
          sessionId: widget.sessionId,
          date: _dateCtrl.text.trim(),
          taskName: _taskCtrl.text,
          sport: _sportCtrl.text,
          sessionType: _sessionType.name,
          protocolName: _protocolCtrl.text,
          contextEnvironment: _contextCtrl.text,
          notes: _notesCtrl.text,
          externalVariables: _collect(_externalCtrls),
          internalVariables: _collect(_internalCtrls),
          rmssdRecovery: double.parse(_rmssdRecoveryCtrl.text),
          rmssdExercise: double.tryParse(_rmssdExerciseCtrl.text),
          rmssdRecoverySource: RmssdRecoverySourceType.manual,
          recoveryWindowStartMin: double.parse(_windowStartCtrl.text),
          recoveryWindowEndMin: double.parse(_windowEndCtrl.text),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Session updated')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
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
        appBar: AppBar(title: const Text('Edit session')),
        body: Center(child: Text(_error ?? 'Session not found.')),
      );
    }

    final isRrMode =
        detail.session.hrvInputMode == HrvInputMode.rrIntervals.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit session')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) _errorCard(_error!),
            _section('Session', [
              _text(_dateCtrl, 'Date/time *'),
              ReusableTagTextField(
                controller: _taskCtrl,
                labelText: 'Session / task name *',
                options: _tagOptions(
                  ReusableTagCategory.sessionTask,
                  _taskCtrl.text,
                ),
                onSaveTag: (value) =>
                    _saveTag(ReusableTagCategory.sessionTask, value),
              ),
              ReusableTagTextField(
                controller: _sportCtrl,
                labelText: 'Sport *',
                options: _tagOptions(
                  ReusableTagCategory.sport,
                  _sportCtrl.text,
                ),
                onSaveTag: (value) =>
                    _saveTag(ReusableTagCategory.sport, value),
              ),
              DropdownButtonFormField<SessionType>(
                initialValue: _sessionType,
                decoration: const InputDecoration(labelText: 'Session type'),
                items: _sessionTypeOptions
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _sessionType = v);
                },
              ),
              ReusableTagTextField(
                controller: _protocolCtrl,
                labelText: 'Protocol name',
                required: false,
                options: _tagOptions(
                  ReusableTagCategory.protocol,
                  _protocolCtrl.text,
                ),
                onSaveTag: (value) =>
                    _saveTag(ReusableTagCategory.protocol, value),
              ),
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
              _text(_notesCtrl, 'Notes', required: false, maxLines: 2),
            ]),
            _variablesSection('External variables', _externalCtrls),
            _variablesSection('Internal variables', _internalCtrls),
            _section('HRV / RMSSD', [
              if (isRrMode) _rrEditNotice(detail.session),
              const Text(
                'Direct RMSSD is the recommended edit workflow. RR intervals '
                'remain auditable in session detail; re-paste RR in a new '
                'session when full preprocessing changes are needed.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              _number(_rmssdRecoveryCtrl, 'RMSSD recovery (ms) *'),
              _number(
                _rmssdExerciseCtrl,
                'RMSSD exercise (ms)',
                required: false,
              ),
              Row(
                children: [
                  Expanded(child: _number(_windowStartCtrl, 'Window start *')),
                  const SizedBox(width: 12),
                  Expanded(child: _number(_windowEndCtrl, 'Window end *')),
                ],
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save changes'),
          ),
        ),
      ),
    );
  }

  Map<String, double> _collect(Map<String, TextEditingController> ctrls) {
    final values = <String, double>{};
    for (final entry in ctrls.entries) {
      final value = double.tryParse(entry.value.text);
      if (value != null) values[entry.key] = value;
    }
    return values;
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
          const SizedBox(height: 12),
          ...children.expand((w) sync* {
            yield w;
            yield const SizedBox(height: 12);
          }),
        ],
      ),
    ),
  );
}

Widget _variablesSection(
  String title,
  Map<String, TextEditingController> ctrls,
) {
  return _section(title, [
    for (final def in [
      ...StandardVariables.externalVariables,
      ...StandardVariables.internalVariables,
    ].where((d) => ctrls.containsKey(d.name)))
      _number(
        ctrls[def.name]!,
        '${def.label}${def.unit == null || def.unit!.isEmpty ? '' : ' (${def.unit})'}',
        required: false,
      ),
  ]);
}

Widget _text(
  TextEditingController controller,
  String label, {
  bool required = true,
  int maxLines = 1,
}) {
  return TextFormField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (v) => v == null || v.trim().isEmpty ? '$label is required' : null
        : null,
  );
}

Widget _number(
  TextEditingController controller,
  String label, {
  bool required = true,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.number,
    validator: (v) {
      if (!required && (v == null || v.trim().isEmpty)) return null;
      final parsed = double.tryParse(v ?? '');
      if (parsed == null) return '$label must be numeric';
      if (parsed <= 0) return '$label must be > 0';
      return null;
    },
  );
}

Widget _rrEditNotice(Session session) {
  return Card(
    color: AppColors.surfaceContainerHigh,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        'Existing RR preprocessing: correction '
        '${session.rrCorrectionEnabled ? 'on' : 'off'}, '
        'raw RMSSD ${session.rrRawRmssd?.toStringAsFixed(2) ?? '-'} ms, '
        'artifacts ${session.rrArtifactCount ?? 0}.',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ),
  );
}

Widget _errorCard(String error) {
  return Card(
    color: AppColors.error.withValues(alpha: 0.12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(error, style: const TextStyle(color: AppColors.error)),
    ),
  );
}
