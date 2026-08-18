import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class TeamFormDialog extends StatefulWidget {
  final AppDatabase database;
  final Team? team;

  const TeamFormDialog({super.key, required this.database, this.team});

  @override
  State<TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends State<TeamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sportCtrl;
  late final TextEditingController _notesCtrl;
  bool _saving = false;

  bool get _isEditing => widget.team != null;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _nameCtrl = TextEditingController(text: team?.name ?? '');
    _sportCtrl = TextEditingController(text: team?.sport ?? '');
    _notesCtrl = TextEditingController(text: team?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sportCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Team' : 'New Team',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('team_form_name'),
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Team name *',
                    prefixIcon: Icon(Icons.groups),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Team name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('team_form_sport'),
                  controller: _sportCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sport',
                    prefixIcon: Icon(Icons.sports),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('team_form_notes'),
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
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
                    ElevatedButton.icon(
                      key: const Key('team_form_save'),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isEditing ? 'Update' : 'Create'),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await widget.database.teamsDao.updateTeam(
          id: widget.team!.id,
          name: _nameCtrl.text,
          sport: _sportCtrl.text,
          notes: _notesCtrl.text,
        );
      } else {
        await widget.database.teamsDao.createTeam(
          name: _nameCtrl.text,
          sport: _sportCtrl.text,
          notes: _notesCtrl.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Team could not be saved: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
