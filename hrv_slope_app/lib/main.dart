import 'package:flutter/material.dart';
import 'package:hrv_slope_app/ui/theme/app_theme.dart';
import 'package:hrv_slope_app/ui/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HrvSlopeApp());
}

class HrvSlopeApp extends StatelessWidget {
  const HrvSlopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HRV Slope App',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
