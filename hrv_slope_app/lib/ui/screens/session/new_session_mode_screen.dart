import 'package:flutter/material.dart';
import 'package:hrv_slope_app/data/database/app_database.dart';
import 'package:hrv_slope_app/ui/screens/session/multi_session_entry_screen.dart';
import 'package:hrv_slope_app/ui/screens/session/session_wizard_screen.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';

class NewSessionModeScreen extends StatefulWidget {
  final AppDatabase? database;

  const NewSessionModeScreen({super.key, this.database});

  @override
  State<NewSessionModeScreen> createState() => _NewSessionModeScreenState();
}

class _NewSessionModeScreenState extends State<NewSessionModeScreen> {
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
      appBar: AppBar(title: const Text('New Session')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final children = [
            _ModeCard(
              key: const Key('new_session_individual'),
              icon: Icons.person_add_alt_1,
              title: 'Individual Entry',
              subtitle: 'Create one normal athlete session',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SessionWizardScreen(database: _db),
                ),
              ),
            ),
            _ModeCard(
              key: const Key('new_session_multiple'),
              icon: Icons.table_rows,
              title: 'Multiple / Team Entry',
              subtitle: 'Enter the same event for several athletes',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MultiSessionEntryScreen(database: _db),
                ),
              ),
            ),
          ];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: children[0]),
                          const SizedBox(width: 16),
                          Expanded(child: children[1]),
                        ],
                      )
                    : ListView.separated(
                        itemCount: children.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => children[index],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Icon(icon, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.primary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
