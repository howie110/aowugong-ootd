import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:aowugong_ootd/app/app.dart';

void main() {
  testWidgets('application uses shadcn shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DailyOotdApp()));
    expect(find.byType(ShadcnApp), findsOneWidget);
    expect(tester.widget<ShadcnApp>(find.byType(ShadcnApp)).title, '每日穿搭');
  });
}
