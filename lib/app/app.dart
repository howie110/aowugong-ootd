import 'package:aowugong_ootd/shared/design/app_ui.dart';

import '../shared/design/app_theme.dart';
import 'router.dart';

class DailyOotdApp extends StatelessWidget {
  const DailyOotdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: '每日穿搭',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scrollBehavior: const AppScrollBehavior(),
      home: const AppShell(),
    );
  }
}

class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
