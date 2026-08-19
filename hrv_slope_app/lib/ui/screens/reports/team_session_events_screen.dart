library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/data/database/daos/session_events_dao.dart';
import 'package:hrv_slope_app/ui/screens/teams/session_event_detail_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class TeamSessionEventsScreen extends StatefulWidget {
  final AppDatabase database;
  final int teamId;

  const TeamSessionEventsScreen({
    super.key,
    required this.database,
    required this.teamId,
  });

  @override
  State<TeamSessionEventsScreen> createState() =>
      _TeamSessionEventsScreenState();
}

class _TeamSessionEventsScreenState extends State<TeamSessionEventsScreen> {
  Team? _team;
  List<SessionEventListItem> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final team = await widget.database.teamsDao.getTeamById(widget.teamId);
    final events = await widget.database.sessionEventsDao
        .getEventsForTeamWithCounts(widget.teamId);
    if (!mounted) return;
    setState(() {
      _team = team;
      _events = events;
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
        appBar: AppBar(title: const Text('Team Sessions')),
        body: const Center(child: Text('Team not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Team Sessions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          _Header(team: team, eventCount: _events.length),
          const SizedBox(height: 12),
          if (_events.isEmpty)
            const _EmptyState()
          else
            for (final item in _events)
              _EventTile(item: item, onOpen: () => _openEvent(item.event.id)),
        ],
      ),
    );
  }

  void _openEvent(int eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionEventDetailScreen(
          database: widget.database,
          eventId: eventId,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Team team;
  final int eventCount;

  const _Header({required this.team, required this.eventCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('team_sessions_header'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.event_note, color: AppColors.primary),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (team.isArchived) ...[
                        const SizedBox(width: 8),
                        const _SmallChip(
                          label: 'Archived',
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sessionEventCountLabel(eventCount),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final SessionEventListItem item;
  final VoidCallback onOpen;

  const _EventTile({required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final event = item.event;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        key: Key('team_session_event_${event.id}'),
        leading: const Icon(Icons.event_available, color: AppColors.primary),
        title: Text(event.taskName ?? 'Session Event'),
        subtitle: Text(
          [
            _formatEventDate(event.date),
            if (_hasText(event.protocolName)) event.protocolName!,
            if (_hasText(event.contextEnvironment)) event.contextEnvironment!,
            _loadDefinition(event),
          ].join(' · '),
        ),
        trailing: SizedBox(
          width: 132,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _participantCountLabel(item.participantCount),
                  key: Key('team_session_participants_${event.id}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                key: Key('team_session_open_${event.id}'),
                tooltip: 'Open SessionEvent',
                icon: const Icon(Icons.open_in_new),
                onPressed: onOpen,
              ),
            ],
          ),
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      key: Key('team_sessions_empty_state'),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No team sessions recorded yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
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

String _loadDefinition(SessionEvent event) {
  return [
    event.loadType,
    event.loadMetricName,
    if (_hasText(event.loadUnit)) event.loadUnit,
  ].join(' ');
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _participantCountLabel(int count) {
  return '$count ${count == 1 ? 'participant' : 'participants'}';
}

String _sessionEventCountLabel(int count) {
  return '$count ${count == 1 ? 'session event' : 'session events'}';
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
