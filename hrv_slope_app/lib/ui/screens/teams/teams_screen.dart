import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_detail_screen.dart';
import 'package:hrv_slope_app/ui/screens/teams/team_form_dialog.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class TeamsScreen extends StatefulWidget {
  final AppDatabase? database;

  const TeamsScreen({super.key, this.database});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late final AppDatabase _db;
  late final bool _ownsDatabase;
  List<Team> _teams = [];
  final Map<int, int> _playerCounts = {};
  bool _showArchived = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _db = widget.database ?? AppDatabase();
    _ownsDatabase = widget.database == null;
    _load();
  }

  @override
  void dispose() {
    if (_ownsDatabase) _db.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final teams = await _db.teamsDao.getAllTeams(
      includeArchived: _showArchived,
    );
    final counts = <int, int>{};
    for (final team in teams) {
      counts[team.id] = (await _db.teamsDao.getAthletesForTeam(team.id)).length;
    }
    if (!mounted) return;
    setState(() {
      _teams = teams;
      _playerCounts
        ..clear()
        ..addAll(counts);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        actions: [
          IconButton(
            key: const Key('teams_toggle_archived'),
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            icon: Icon(
              _showArchived ? Icons.visibility_off : Icons.archive_outlined,
            ),
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
          ? _EmptyTeamsState(showArchived: _showArchived)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final team = _teams[index];
                return _TeamCard(
                  team: team,
                  playerCount: _playerCounts[team.id] ?? 0,
                  onTap: () => _openTeam(team),
                  onEdit: () => _showTeamForm(team),
                  onArchiveToggle: () => _toggleArchive(team),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('teams_new_team'),
        onPressed: () => _showTeamForm(null),
        icon: const Icon(Icons.group_add),
        label: const Text('New Team'),
      ),
    );
  }

  Future<void> _showTeamForm(Team? team) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => TeamFormDialog(database: _db, team: team),
    );
    if (changed == true) await _load();
  }

  Future<void> _toggleArchive(Team team) async {
    if (team.isArchived) {
      await _db.teamsDao.restoreTeam(team.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${team.name} restored')));
      }
    } else {
      await _db.teamsDao.archiveTeam(team.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${team.name} archived')));
      }
    }
    await _load();
  }

  Future<void> _openTeam(Team team) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamDetailScreen(database: _db, teamId: team.id),
      ),
    );
    await _load();
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final int playerCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onArchiveToggle;

  const _TeamCard({
    required this.team,
    required this.playerCount,
    required this.onTap,
    required this.onEdit,
    required this.onArchiveToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: team.isArchived ? 0.58 : 1,
        child: Card(
          child: InkWell(
            key: Key('team_card_${team.id}'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Icon(
                      team.isArchived ? Icons.archive : Icons.groups,
                      color: team.isArchived
                          ? AppColors.warning
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                team.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (team.isArchived) ...[
                              const SizedBox(width: 8),
                              const _MiniChip(
                                label: 'Archived',
                                color: AppColors.warning,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (team.sport != null) team.sport!,
                            '$playerCount players',
                          ].join(' · '),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    key: Key('team_menu_${team.id}'),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                        case 'archive':
                          onArchiveToggle();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              team.isArchived ? Icons.unarchive : Icons.archive,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(team.isArchived ? 'Restore' : 'Archive'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyTeamsState extends StatelessWidget {
  final bool showArchived;

  const _EmptyTeamsState({required this.showArchived});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showArchived ? Icons.archive_outlined : Icons.groups_outlined,
            size: 80,
            color: AppColors.textHint.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            showArchived ? 'No archived teams' : 'No teams yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            showArchived
                ? 'Archived teams will appear here'
                : 'Create a team to manage a roster',
            style: const TextStyle(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
