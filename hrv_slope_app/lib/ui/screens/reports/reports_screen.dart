library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/ui/screens/reports/group_report_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/population_nomogram_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final AppDatabase _db;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
  }

  @override
  void dispose() {
    _db.close();
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
            icon: Icons.groups,
            title: 'Group Report',
            subtitle:
                'Rank matching sessions by RMSSD-Slope and compare load response.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupReportScreen(database: _db),
              ),
            ),
          ),
          _reportTile(
            context,
            icon: Icons.auto_graph,
            title: 'Population Nomogram',
            subtitle: 'View population bands and eligible session points.',
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
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
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
