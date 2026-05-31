/// Athlete Form Dialog — Create or edit an athlete.
library;

// ignore_for_file: deprecated_member_use

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class AthleteFormDialog extends StatefulWidget {
  final AppDatabase database;
  final Athlete? athlete;

  const AthleteFormDialog({super.key, required this.database, this.athlete});

  @override
  State<AthleteFormDialog> createState() => _AthleteFormDialogState();
}

class _AthleteFormDialogState extends State<AthleteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sportCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _masCtrl;
  late final TextEditingController _vvo2Ctrl;
  late final TextEditingController _mapCtrl;
  late final TextEditingController _notesCtrl;
  String? _sex;
  DateTime? _birthDate;
  bool _saving = false;

  bool get _isEditing => widget.athlete != null;

  @override
  void initState() {
    super.initState();
    final a = widget.athlete;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _sportCtrl = TextEditingController(text: a?.sport ?? '');
    _positionCtrl = TextEditingController(text: a?.positionOrEvent ?? '');
    _masCtrl = TextEditingController(text: a?.masKmh?.toString() ?? '');
    _vvo2Ctrl = TextEditingController(text: a?.vvo2maxKmh?.toString() ?? '');
    _mapCtrl = TextEditingController(text: a?.mapW?.toString() ?? '');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');
    _sex = a?.gender;
    if (a?.birthDate != null) {
      _birthDate = DateTime.tryParse(a!.birthDate!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sportCtrl.dispose();
    _positionCtrl.dispose();
    _masCtrl.dispose();
    _vvo2Ctrl.dispose();
    _mapCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEditing ? 'Edit Athlete' : 'New Athlete',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sportCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sport *',
                    prefixIcon: Icon(Icons.sports),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Sport is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _positionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Position / Event',
                    prefixIcon: Icon(Icons.emoji_events),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _sex,
                  decoration: const InputDecoration(
                    labelText: 'Sex',
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _sex = v),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake),
                  title: Text(
                    _birthDate != null
                        ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
                        : 'Birth date (optional)',
                    style: TextStyle(
                      color: _birthDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  trailing: _birthDate != null
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _birthDate = null),
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _birthDate ?? DateTime(2000),
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _birthDate = date);
                    }
                  },
                ),
                const Divider(height: 28),
                Text(
                  'Reference Values',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _masCtrl,
                        decoration: const InputDecoration(
                          labelText: 'MAS (km/h)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _positiveOrEmpty,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _vvo2Ctrl,
                        decoration: const InputDecoration(
                          labelText: 'vVO₂max (km/h)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _positiveOrEmpty,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _mapCtrl,
                  decoration: const InputDecoration(labelText: 'MAP (W)'),
                  keyboardType: TextInputType.number,
                  validator: _positiveOrEmpty,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? 'Update' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _positiveOrEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return 'Must be a number';
    if (n <= 0) return 'Must be positive';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final now = DateTime.now().toIso8601String();

    try {
      if (_isEditing) {
        final old = widget.athlete!;
        final updated = Athlete(
          id: old.id,
          name: _nameCtrl.text.trim(),
          sport: _sportCtrl.text.trim().isEmpty ? null : _sportCtrl.text.trim(),
          birthDate: _birthDate?.toIso8601String(),
          gender: _sex,
          positionOrEvent: _positionCtrl.text.trim().isEmpty
              ? null
              : _positionCtrl.text.trim(),
          masKmh: double.tryParse(_masCtrl.text),
          vvo2maxKmh: double.tryParse(_vvo2Ctrl.text),
          mapW: double.tryParse(_mapCtrl.text),
          fcMax: old.fcMax,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          isArchived: old.isArchived,
          createdAt: old.createdAt,
          updatedAt: now,
        );
        await widget.database.athletesDao.updateAthlete(updated);
      } else {
        await widget.database.athletesDao.insertAthlete(
          AthletesCompanion.insert(
            name: _nameCtrl.text.trim(),
            sport: drift.Value(
              _sportCtrl.text.trim().isEmpty ? null : _sportCtrl.text.trim(),
            ),
            birthDate: drift.Value(_birthDate?.toIso8601String()),
            gender: drift.Value(_sex),
            positionOrEvent: drift.Value(
              _positionCtrl.text.trim().isEmpty
                  ? null
                  : _positionCtrl.text.trim(),
            ),
            masKmh: drift.Value(double.tryParse(_masCtrl.text)),
            vvo2maxKmh: drift.Value(double.tryParse(_vvo2Ctrl.text)),
            mapW: drift.Value(double.tryParse(_mapCtrl.text)),
            notes: drift.Value(
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
