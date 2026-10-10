import 'package:flutter/material.dart';

import '../features/launch/launch_gate.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

class SparkKeeperApp extends StatelessWidget {
  const SparkKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '火花管家',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const LaunchGate(child: AppShell()),
    );
  }
}
