import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/session_events_dao.dart';
import 'package:hrv_slope_app/ui/screens/teams/session_event_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_form_dialog.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_longitudinal_heatmap_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class TeamDetailScreen extends StatefulWidget {
  final AppDatabase database;
  final int teamId;

  const TeamDetailScreen({
    super.key,
    required this.database,
    required this.teamId,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  Team? _team;
  List<Athlete> _players = [];
  List<Athlete> _allAthletes = [];
  List<SessionEventListItem> _recentEvents = [];
  Map<int, AthleteTeamAssignment> _assignmentsByAthlete = {};
  Map<int, Team> _teamsById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final team = await widget.database.teamsDao.getTeamById(widget.teamId);
    final players = await widget.database.teamsDao.getAthletesForTeam(
      widget.teamId,
    );
    final allAthletes = await widget.database.athletesDao.getAllAthletes();
    final assignments = await widget.database.teamsDao.getAllAssignments();
    final teams = await widget.database.teamsDao.getAllTeams(
      includeArchived: true,
    );
    final recentEvents = await widget.database.sessionEventsDao
        .getRecentEventsForTeamWithCounts(widget.teamId, limit: 5);
    if (!mounted) return;
    setState(() {
      _team = team;
      _players = players;
      _allAthletes = allAthletes;
      _recentEvents = recentEvents;
      _assignmentsByAthlete = {
        for (final assignment in assignments) assignment.athleteId: assignment,
      };
      _teamsById = {
        for (final currentTeam in teams) currentTeam.id: currentTeam,
      };
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final team = _team;
    if (team == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team')),
        body: const Center(child: Text('Team not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        actions: [
          IconButton(
            key: const Key('team_detail_edit'),
            tooltip: 'Edit team',
            icon: const Icon(Icons.edit),
            onPressed: () => _showTeamForm(team),
          ),
          IconButton(
            key: const Key('team_detail_archive_restore'),
            tooltip: team.isArchived ? 'Restore team' : 'Archive team',
            icon: Icon(team.isArchived ? Icons.unarchive : Icons.archive),
            onPressed: () => _toggleArchive(team),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: const Icon(
                          Icons.groups,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              [
                                if (team.sport != null) team.sport!,
                                '${_players.length} players',
                              ].join(' · '),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (team.isArchived)
                        const _StatusChip(
                          label: 'Archived',
                          color: AppColors.warning,
                        ),
                    ],
                  ),
                  if (team.notes != null && team.notes!.trim().isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(team.notes!),
                  ],
                  if (team.isArchived) ...[
                    const Divider(height: 24),
                    const Text(
                      'Archived teams keep their players, events, and sessions, '
                      'but cannot receive players or create new multi-session entries.',
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('team_open_longitudinal_heatmap'),
              onPressed: () => _openLongitudinalHeatmap(team.id),
              icon: const Icon(Icons.grid_view),
              label: const Text('Open longitudinal'),
            ),
          ),
          const SizedBox(height: 16),
          _RecentEventsSection(events: _recentEvents, onOpen: _openEvent),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Players (${_players.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                key: const Key('team_detail_add_players'),
                onPressed: team.isArchived ? null : _showAddPlayersDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Add players'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_players.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  team.isArchived
                      ? 'No active players are assigned.'
                      : 'No players yet. Add existing athletes to build the roster.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._players.map(
              (athlete) => _PlayerTile(
                athlete: athlete,
                enabled: !team.isArchived,
                onRemove: () => _removeAthlete(athlete),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showTeamForm(Team team) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => TeamFormDialog(database: widget.database, team: team),
    );
    if (changed == true) await _load();
  }

  Future<void> _toggleArchive(Team team) async {
    if (team.isArchived) {
      await widget.database.teamsDao.restoreTeam(team.id);
    } else {
      await widget.database.teamsDao.archiveTeam(team.id);
    }
    await _load();
  }

  Future<void> _showAddPlayersDialog() async {
    final team = _team;
    if (team == null || team.isArchived) return;
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _AddPlayersDialog(
        database: widget.database,
        targetTeam: team,
        athletes: _allAthletes,
        assignmentsByAthlete: _assignmentsByAthlete,
        teamsById: _teamsById,
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _removeAthlete(Athlete athlete) async {
    await widget.database.teamsDao.removeAthleteFromTeam(athlete.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${athlete.name} removed from team')),
      );
    }
    await _load();
  }

  void _openEvent(SessionEventListItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionEventDetailScreen(
          database: widget.database,
          eventId: item.event.id,
        ),
      ),
    );
  }

  void _openLongitudinalHeatmap(int teamId) {
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

class _RecentEventsSection extends StatelessWidget {
  final List<SessionEventListItem> events;
  final ValueChanged<SessionEventListItem> onOpen;

  const _RecentEventsSection({required this.events, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('team_recent_events'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent SessionEvents',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${events.length}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (events.isEmpty)
              const Text(
                'No team session events yet.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              for (final item in events)
                ListTile(
                  key: Key('team_recent_event_${item.event.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_note),
                  title: Text(item.event.taskName ?? 'Session Event'),
                  subtitle: Text(
                    [
                      _formatEventDate(item.event.date),
                      if (item.event.protocolName != null)
                        item.event.protocolName!,
                      '${item.participantCount} participants',
                    ].join(' · '),
                  ),
                  trailing: IconButton(
                    key: Key('team_open_event_${item.event.id}'),
                    tooltip: 'Open event',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => onOpen(item),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _AddPlayersDialog extends StatefulWidget {
  final AppDatabase database;
  final Team targetTeam;
  final List<Athlete> athletes;
  final Map<int, AthleteTeamAssignment> assignmentsByAthlete;
  final Map<int, Team> teamsById;

  const _AddPlayersDialog({
    required this.database,
    required this.targetTeam,
    required this.athletes,
    required this.assignmentsByAthlete,
    required this.teamsById,
  });

  @override
  State<_AddPlayersDialog> createState() => _AddPlayersDialogState();
}

class _AddPlayersDialogState extends State<_AddPlayersDialog> {
  String _query = '';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final candidates = widget.athletes.where((athlete) {
      final assignment = widget.assignmentsByAthlete[athlete.id];
      if (assignment?.teamId == widget.targetTeam.id) return false;
      return athlete.name.toLowerCase().contains(_query.trim().toLowerCase());
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add players',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('team_add_players_search'),
                decoration: const InputDecoration(
                  labelText: 'Search athletes',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: candidates.isEmpty
                    ? const Center(child: Text('No available athletes'))
                    : ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final athlete = candidates[index];
                          final assignment =
                              widget.assignmentsByAthlete[athlete.id];
                          final currentTeam = assignment == null
                              ? null
                              : widget.teamsById[assignment.teamId];
                          return ListTile(
                            key: Key('team_add_player_${athlete.id}'),
                            leading: const Icon(Icons.person),
                            title: Text(athlete.name),
                            subtitle: Text(
                              currentTeam == null
                                  ? 'No team'
                                  : 'Current team: ${currentTeam.name}',
                            ),
                            trailing: FilledButton.icon(
                              key: Key('team_assign_player_${athlete.id}'),
                              onPressed: _saving
                                  ? null
                                  : () => _assignAthlete(athlete),
                              icon: Icon(
                                currentTeam == null
                                    ? Icons.add
                                    : Icons.compare_arrows,
                              ),
                              label: Text(
                                currentTeam == null ? 'Add' : 'Move here',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignAthlete(Athlete athlete) async {
    setState(() => _saving = true);
    try {
      await widget.database.teamsDao.assignAthleteToTeam(
        athleteId: athlete.id,
        teamId: widget.targetTeam.id,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Assignment failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PlayerTile extends StatelessWidget {
  final Athlete athlete;
  final bool enabled;
  final VoidCallback onRemove;

  const _PlayerTile({
    required this.athlete,
    required this.enabled,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: Key('team_player_${athlete.id}'),
        leading: const Icon(Icons.person),
        title: Text(athlete.name),
        subtitle: Text(athlete.positionOrEvent ?? athlete.sport ?? ''),
        trailing: IconButton(
          key: Key('team_remove_player_${athlete.id}'),
          tooltip: 'Remove from team',
          icon: const Icon(Icons.person_remove),
          onPressed: enabled ? onRemove : null,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
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

String _formatEventDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final date =
      '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
  final time =
      '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
