import 'package:aowugong_ootd/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders app shell and switches tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DailyOotdApp()));

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);

    final initialAppBar = tester.widget<AppBar>(find.byType(AppBar));
    expect((initialAppBar.title as Text).data, 'Daily OOTD');

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    final updatedAppBar = tester.widget<AppBar>(find.byType(AppBar));
    expect((updatedAppBar.title as Text).data, '设置');
  });
}
