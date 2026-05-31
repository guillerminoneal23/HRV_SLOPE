/// Athlete Detail Screen — Shows athlete info, sessions, and summary.
library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/ui/screens/longitudinal/athlete_longitudinal_screen.dart';
import 'package:hrv_slope_app/ui/screens/nomogram/individual_nomogram_screen.dart';
import 'package:hrv_slope_app/ui/screens/session/session_detail_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class AthleteDetailScreen extends StatefulWidget {
  final AppDatabase database;
  final int athleteId;

  const AthleteDetailScreen({
    super.key,
    required this.database,
    required this.athleteId,
  });

  @override
  State<AthleteDetailScreen> createState() => _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends State<AthleteDetailScreen> {
  Athlete? _athlete;
  List<Session> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final athlete = await widget.database.athletesDao.getAthleteById(
      widget.athleteId,
    );
    final sessions = await widget.database.sessionsDao.getSessionsForAthlete(
      widget.athleteId,
    );
    if (mounted) {
      setState(() {
        _athlete = athlete;
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  Future<void> _openSession(Session session) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(
          database: widget.database,
          sessionId: session.id,
        ),
      ),
    );
    if (changed == true) {
      await _load();
    }
  }

  void _openLongitudinal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AthleteLongitudinalScreen(
          database: widget.database,
          athleteId: widget.athleteId,
        ),
      ),
    );
  }

  void _openIndividualNomogram() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IndividualNomogramScreen(
          database: widget.database,
          athleteId: widget.athleteId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_athlete == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Athlete')),
        body: const Center(child: Text('Athlete not found')),
      );
    }

    final a = _athlete!;
    return Scaffold(
      appBar: AppBar(title: Text(a.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          a.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (a.sport != null)
                              Text(
                                a.sport!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow('Sessions', '${_sessions.length}'),
                  if (a.gender != null) _InfoRow('Sex', a.gender!),
                  if (a.birthDate != null) _InfoRow('Birth date', a.birthDate!),
                  if (a.positionOrEvent != null)
                    _InfoRow('Position / Event', a.positionOrEvent!),
                  if (a.masKmh != null) _InfoRow('MAS', '${a.masKmh} km/h'),
                  if (a.vvo2maxKmh != null)
                    _InfoRow('vVO₂max', '${a.vvo2maxKmh} km/h'),
                  if (a.mapW != null) _InfoRow('MAP', '${a.mapW} W'),
                  if (a.notes != null && a.notes!.isNotEmpty)
                    _InfoRow('Notes', a.notes!),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _openIndividualNomogram,
                          icon: const Icon(Icons.scatter_plot),
                          label: const Text('Individual Nomogram'),
                        ),
                        FilledButton.icon(
                          onPressed: _openLongitudinal,
                          icon: const Icon(Icons.timeline),
                          label: const Text('Longitudinal'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sessions (${_sessions.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_sessions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No sessions yet. Use New Session to add this athlete’s first HRV slope record.',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ),
              ),
            )
          else
            ..._sessions.map(
              (s) => _SessionTile(session: s, onTap: () => _openSession(s)),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const _SessionTile({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          session.isDraft ? Icons.drafts : Icons.check_circle,
          color: session.isDraft ? AppColors.warning : AppColors.success,
        ),
        title: Text(session.taskName ?? session.date),
        subtitle: Text(
          [
            session.date,
            if (session.sport != null) session.sport!,
            if (session.isDraft)
              'Draft'
            else if (session.slopeInterpreted != null)
              'Slope: ${session.slopeInterpreted!.toStringAsFixed(2)}',
            if (!session.isDraft && session.classification != null)
              session.classification!,
          ].join(' · '),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
