library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/ui/screens/reports/group_report_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/population_nomogram_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/team_reports_hub_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  final AppDatabase? database;

  const ReportsScreen({super.key, this.database});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final AppDatabase _db;
  late final bool _ownsDatabase;

  @override
  void initState() {
    super.initState();
    _db = widget.database ?? AppDatabase();
    _ownsDatabase = widget.database == null;
  }

  @override
  void dispose() {
    if (_ownsDatabase) _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _reportTile(
            context,
            key: const Key('reports_team_reports'),
            icon: Icons.groups_2,
            title: 'Team Reports',
            subtitle:
                'Review recorded team SessionEvents and longitudinal RMSSD-Slope data.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TeamReportsHubScreen(database: _db),
              ),
            ),
          ),
          _reportTile(
            context,
            key: const Key('reports_group_report'),
            icon: Icons.groups,
            title: 'Group Report',
            subtitle:
                'Build a report from individually selected or filtered sessions.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupReportScreen(database: _db),
              ),
            ),
          ),
          _reportTile(
            context,
            key: const Key('reports_study_nomogram'),
            icon: Icons.auto_graph,
            title: 'Study Nomogram',
            subtitle: 'View study reference bands and eligible session points.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PopulationNomogramScreen(database: _db),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportTile(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
