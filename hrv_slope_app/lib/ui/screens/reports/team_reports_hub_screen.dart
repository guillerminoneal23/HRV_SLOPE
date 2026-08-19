library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/ui/screens/reports/team_session_events_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_longitudinal_heatmap_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class TeamReportsHubScreen extends StatefulWidget {
  final AppDatabase database;

  const TeamReportsHubScreen({super.key, required this.database});

  @override
  State<TeamReportsHubScreen> createState() => _TeamReportsHubScreenState();
}

class _TeamReportsHubScreenState extends State<TeamReportsHubScreen> {
  List<Team> _teams = [];
  int? _selectedTeamId;
  bool _loading = true;

  Team? get _selectedTeam {
    final selectedId = _selectedTeamId;
    if (selectedId == null) return null;
    for (final team in _teams) {
      if (team.id == selectedId) return team;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final teams = await widget.database.teamsDao.getAllTeams(
      includeArchived: true,
    );
    if (!mounted) return;
    setState(() {
      _teams = teams;
      if (teams.isEmpty) {
        _selectedTeamId = null;
      } else if (_selectedTeamId == null ||
          !teams.any((team) => team.id == _selectedTeamId)) {
        _selectedTeamId = teams.first.id;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Team Reports')),
      body: _teams.isEmpty ? const _EmptyState() : _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final selectedTeam = _selectedTeam;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Card(
          key: const Key('team_reports_selector_card'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select team',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: const Key('team_reports_team_selector'),
                  initialValue: _selectedTeamId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Team',
                    prefixIcon: Icon(Icons.groups),
                  ),
                  items: [
                    for (final team in _teams)
                      DropdownMenuItem<int>(
                        key: Key('team_reports_team_option_${team.id}'),
                        value: team.id,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                team.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (team.isArchived)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: _SmallChip(
                                  label: 'Archived',
                                  color: AppColors.warning,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _selectedTeamId = value),
                ),
                if (selectedTeam?.isArchived == true) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Archived teams remain available for historical reports.',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ReportActionCard(
          key: const Key('team_reports_sessions_action'),
          icon: Icons.event_note,
          title: 'Team Sessions',
          subtitle: 'Review recorded team SessionEvents.',
          onTap: selectedTeam == null
              ? null
              : () => _openTeamSessions(selectedTeam.id),
        ),
        _ReportActionCard(
          key: const Key('team_reports_longitudinal_action'),
          icon: Icons.grid_view,
          title: 'Team Longitudinal',
          subtitle: 'RMSSD-Slope evolution across SessionEvents.',
          onTap: selectedTeam == null
              ? null
              : () => _openTeamLongitudinal(selectedTeam.id),
        ),
      ],
    );
  }

  void _openTeamSessions(int teamId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TeamSessionEventsScreen(database: widget.database, teamId: teamId),
      ),
    );
  }

  void _openTeamLongitudinal(int teamId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamLongitudinalHeatmapScreen(
          database: widget.database,
          teamId: teamId,
        ),
      ),
    );
  }
}

class _ReportActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ReportActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        enabled: onTap != null,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('team_reports_empty_state'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 80,
            color: AppColors.textHint.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            'No teams available.',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a team first to use Team Reports.',
            style: TextStyle(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
