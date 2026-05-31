/// App Shell — Main navigation scaffold with bottom navigation bar.
library;

import 'package:flutter/material.dart';
import 'package:hrv_slope_app/ui/screens/athletes/athletes_screen.dart';
import 'package:hrv_slope_app/ui/screens/import/import_screen.dart';
import 'package:hrv_slope_app/ui/screens/instructions/instructions_screen.dart';
import 'package:hrv_slope_app/ui/screens/reports/reports_screen.dart';
import 'package:hrv_slope_app/ui/screens/session/session_wizard_screen.dart';
import 'package:hrv_slope_app/ui/screens/settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  const AppShell({super.key, this.onSettingsChanged});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildBody(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Athletes',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'New Session',
          ),
          NavigationDestination(
            icon: Icon(Icons.file_upload_outlined),
            selectedIcon: Icon(Icons.file_upload),
            label: 'Import',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Instructions',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const AthletesScreen(key: ValueKey('athletes'));
      case 1:
        return const SessionWizardScreen(key: ValueKey('session'));
      case 2:
        return const ImportScreen(key: ValueKey('import'));
      case 3:
        return const ReportsScreen(key: ValueKey('reports'));
      case 4:
        return const InstructionsScreen(key: ValueKey('instructions'));
      case 5:
        return const SettingsScreen(key: ValueKey('settings'));
      default:
        return const AthletesScreen(key: ValueKey('athletes'));
    }
  }
}
