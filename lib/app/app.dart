import 'package:flutter/material.dart';

import '../shared/design/app_theme.dart';
import 'router.dart';

class DailyOotdApp extends StatelessWidget {
  const DailyOotdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily OOTD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
