/// Athletes Screen — List, create, edit, archive athletes.
library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/shared/engine/recovery_response_labels.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/screens/athletes/athlete_form_dialog.dart';
import 'package:hrv_slope_app/ui/screens/athletes/athlete_detail_screen.dart';

class AthletesScreen extends StatefulWidget {
  final AppDatabase? database;

  const AthletesScreen({super.key, this.database});

  @override
  State<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends State<AthletesScreen> {
  late final AppDatabase _db;
  late final bool _ownsDatabase;
  List<Athlete> _athletes = [];
  List<Team> _teams = [];
  final Map<int, int> _sessionCounts = {};
  final Map<int, Session?> _latestSessions = {};
  final Map<int, AthleteTeamAssignment> _assignmentsByAthlete = {};
  final Map<int, Team> _teamsById = {};
  String _teamFilter = 'all';
  bool _showArchived = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _db = widget.database ?? AppDatabase();
    _ownsDatabase = widget.database == null;
    _loadAthletes();
  }

  @override
  void dispose() {
    if (_ownsDatabase) _db.close();
    super.dispose();
  }

  Future<void> _loadAthletes() async {
    setState(() => _loading = true);
    final allAthletes = await _db.athletesDao.getAllAthletes(
      includeArchived: _showArchived,
    );
    final teams = await _db.teamsDao.getAllTeams(includeArchived: true);
    final assignments = await _db.teamsDao.getAllAssignments();
    final athletes = _filterAthletes(allAthletes, assignments);
    final counts = <int, int>{};
    final latest = <int, Session?>{};
    for (final a in athletes) {
      counts[a.id] = await _db.athletesDao.getSessionCount(a.id);
      latest[a.id] = await _db.athletesDao.getLatestSession(a.id);
    }
    if (mounted) {
      setState(() {
        _teams = teams;
        _athletes = athletes;
        _sessionCounts
          ..clear()
          ..addAll(counts);
        _latestSessions
          ..clear()
          ..addAll(latest);
        _teamsById
          ..clear()
          ..addEntries(teams.map((team) => MapEntry(team.id, team)));
        _assignmentsByAthlete
          ..clear()
          ..addEntries(
            assignments.map((item) => MapEntry(item.athleteId, item)),
          );
        _loading = false;
      });
    }
  }

  List<Athlete> _filterAthletes(
    List<Athlete> athletes,
    List<AthleteTeamAssignment> assignments,
  ) {
    if (_teamFilter == 'all') return athletes;
    final byAthlete = {
      for (final assignment in assignments) assignment.athleteId: assignment,
    };
    if (_teamFilter == 'none') {
      return athletes
          .where((athlete) => byAthlete[athlete.id] == null)
          .toList(growable: false);
    }
    final teamId = int.tryParse(_teamFilter.replaceFirst('team:', ''));
    return athletes
        .where((athlete) => byAthlete[athlete.id]?.teamId == teamId)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Athletes'),
        actions: [
          IconButton(
            icon: Icon(
              _showArchived ? Icons.visibility_off : Icons.archive_outlined,
            ),
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
              _loadAthletes();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTeamFilter(),
                Expanded(
                  child: _athletes.isEmpty
                      ? _buildEmptyState()
                      : _buildAthleteList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAthleteForm(null),
        icon: const Icon(Icons.person_add),
        label: const Text('New Athlete'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.textHint.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No athletes yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first athlete',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _athletes.length,
      itemBuilder: (context, index) {
        final athlete = _athletes[index];
        final sessionCount = _sessionCounts[athlete.id] ?? 0;
        final latestSession = _latestSessions[athlete.id];

        return _AthleteCard(
          athlete: athlete,
          sessionCount: sessionCount,
          latestSession: latestSession,
          teamName: _teamNameForAthlete(athlete.id),
          onTap: () => _openAthleteDetail(athlete),
          onEdit: () => _showAthleteForm(athlete),
          onArchive: () => _archiveAthlete(athlete),
          onDelete: () => _deleteAthlete(athlete),
        );
      },
    );
  }

  Widget _buildTeamFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DropdownButtonFormField<String>(
        key: const Key('athletes_team_filter'),
        initialValue: _teamFilter,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Team filter',
          prefixIcon: Icon(Icons.filter_list),
        ),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('All athletes')),
          const DropdownMenuItem(value: 'none', child: Text('No team')),
          ..._teams.map(
            (team) => DropdownMenuItem(
              value: 'team:${team.id}',
              child: Text(
                team.isArchived ? '${team.name} (archived)' : team.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _teamFilter = value);
          _loadAthletes();
        },
      ),
    );
  }

  String? _teamNameForAthlete(int athleteId) {
    final assignment = _assignmentsByAthlete[athleteId];
    if (assignment == null) return null;
    return _teamsById[assignment.teamId]?.name;
  }

  void _showAthleteForm(Athlete? athlete) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AthleteFormDialog(database: _db, athlete: athlete),
    );
    if (result == true) {
      _loadAthletes();
    }
  }

  void _openAthleteDetail(Athlete athlete) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                AthleteDetailScreen(database: _db, athleteId: athlete.id),
          ),
        )
        .then((_) => _loadAthletes());
  }

  Future<void> _archiveAthlete(Athlete athlete) async {
    final isArchived = athlete.isArchived;
    if (isArchived) {
      await _db.athletesDao.unarchiveAthlete(athlete.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${athlete.name} unarchived')));
      }
    } else {
      await _db.athletesDao.archiveAthlete(athlete.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${athlete.name} archived')));
      }
    }
    _loadAthletes();
  }

  Future<void> _deleteAthlete(Athlete athlete) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Athlete?'),
        content: Text(
          'Permanently delete ${athlete.name} and all associated data? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.athletesDao.deleteAthlete(athlete.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${athlete.name} deleted')));
      }
      _loadAthletes();
    }
  }
}

class _AthleteCard extends StatelessWidget {
  final Athlete athlete;
  final int sessionCount;
  final Session? latestSession;
  final String? teamName;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _AthleteCard({
    required this.athlete,
    required this.sessionCount,
    required this.latestSession,
    required this.teamName,
    required this.onTap,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isArchived = athlete.isArchived;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: isArchived ? 0.55 : 1.0,
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
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
                        child: Text(
                          athlete.name.isNotEmpty
                              ? athlete.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
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
                                    athlete.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isArchived) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Archived',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (athlete.sport != null)
                              Text(
                                athlete.sport!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit();
                            case 'archive':
                              onArchive();
                            case 'delete':
                              onDelete();
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
                                  isArchived ? Icons.unarchive : Icons.archive,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(isArchived ? 'Unarchive' : 'Archive'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.fitness_center,
                        label: '$sessionCount sessions',
                      ),
                      if (latestSession?.slopeInterpreted != null) ...[
                        _InfoChip(
                          icon: Icons.show_chart,
                          label:
                              'Slope: ${latestSession!.slopeInterpreted!.toStringAsFixed(2)}',
                        ),
                      ],
                      if (latestSession?.classification != null)
                        _InfoChip(
                          icon: Icons.assessment,
                          label: recoveryResponseShortLabelForClassificationKey(
                            latestSession!.classification,
                          ),
                          color: _classificationColor(
                            latestSession!.classification!,
                          ),
                        ),
                      _InfoChip(
                        icon: Icons.groups,
                        label: teamName == null ? 'No team' : teamName!,
                        color: teamName == null
                            ? AppColors.textSecondary
                            : AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _classificationColor(String classification) {
    if (classification.contains('very_high') ||
        classification.contains('Very high') ||
        classification.contains('Lower-than-expected')) {
      return AppColors.classVeryHigh;
    }
    if (classification.contains('high') || classification.contains('poor')) {
      return AppColors.classHighMod;
    }
    if (classification.contains('expected') ||
        classification.contains('good')) {
      return AppColors.classExpected;
    }
    return AppColors.classLowFast;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.primary),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
