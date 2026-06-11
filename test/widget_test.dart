import 'package:aowugong_ootd/app/app.dart';
import 'package:aowugong_ootd/features/ootd/presentation/detail/ootd_detail_page.dart';
import 'package:aowugong_ootd/features/ootd/presentation/home/home_page.dart';
import 'package:aowugong_ootd/features/ootd/presentation/home/mock_ootd_items.dart';
import 'package:aowugong_ootd/features/settings/presentation/settings/option_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home supports multi-select filters and grid date captions', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DailyOotdApp()));

    expect(find.text('穿搭'), findsWidgets);
    expect(find.text('喜欢'), findsOneWidget);
    expect(find.text('不喜欢'), findsOneWidget);
    expect(find.text('春'), findsOneWidget);
    expect(find.text('工作'), findsOneWidget);
    expect(find.text('黑白'), findsOneWidget);
    expect(find.text('1星'), findsOneWidget);
    expect(find.text('2026-04-05'), findsOneWidget);
    expect(find.text('当前筛选条件下没有匹配的穿搭'), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePage)),
    );

    await tester.tap(find.text('喜欢'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('春'));
    await tester.pumpAndSettle();

    expect(container.read(ootdFiltersProvider).preferences, ['喜欢']);
    expect(container.read(ootdFiltersProvider).seasons, ['春']);
    expect(find.text('2026-04-05'), findsOneWidget);
  });

  testWidgets('restores initial filters from provider overrides', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialOotdFiltersProvider.overrideWithValue(
            const OotdFilterState(scenes: ['休息']),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HomePage())),
      ),
    );

    expect(find.text('5 条'), findsOneWidget);
  });

  testWidgets('detail page uses date title and compact single-select editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OotdDetailPage(itemId: 'look-01')),
      ),
    );

    expect(find.text('2026-04-05'), findsOneWidget);
    expect(find.text('图片'), findsNothing);
    expect(find.text('日期'), findsNothing);
    expect(find.text('主'), findsOneWidget);
    expect(find.text('喜欢'), findsOneWidget);
    expect(find.text('副图1'), findsNothing);
    expect(find.text('1星'), findsOneWidget);

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('ootd-save-button')),
    );
    expect(saveButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('ootd-image-slot-0')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.tap(find.byKey(const Key('ootd-preview-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('冬'));
    await tester.pumpAndSettle();

    final updatedSaveButton = tester.widget<FilledButton>(
      find.byKey(const Key('ootd-save-button')),
    );
    expect(updatedSaveButton.onPressed, isNotNull);
  });

  testWidgets('settings page opens option management', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DailyOotdApp()));

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    expect(find.text('选项管理'), findsOneWidget);

    await tester.tap(find.text('选项管理').first);
    await tester.pumpAndSettle();

    expect(find.text('选项管理'), findsOneWidget);
    expect(find.text('选项1'), findsNothing);
    expect(find.text('喜欢'), findsOneWidget);
    expect(find.byTooltip('删除整个选项'), findsWidgets);
  });

  testWidgets('option management can add option group 6', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OptionManagementPage()),
      ),
    );

    await tester.tap(find.byTooltip('新增选项'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '自定义');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(OptionManagementPage)),
    );

    expect(container.read(ootdOptionConfigProvider).extraGroups.length, 1);
    await tester.ensureVisible(find.text('自定义'));
    await tester.pumpAndSettle();

    expect(find.text('选项6'), findsNothing);
    expect(find.text('自定义', skipOffstage: false), findsOneWidget);
  });

  testWidgets('detail page can delete ootd item with confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialOotdFiltersProvider.overrideWithValue(
            const OotdFilterState(preferences: ['喜欢']),
          ),
        ],
        child: const MaterialApp(home: OotdDetailPage(itemId: 'look-01')),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(OotdDetailPage)),
    );

    expect(container.read(ootdItemsProvider).length, 9);

    await tester.tap(find.byTooltip('删除穿搭'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    expect(container.read(ootdItemsProvider).length, 8);
    await tester.pump();
  });

  testWidgets('create page reuses detail layout', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OotdDetailPage())),
    );

    expect(find.text('新增穿搭'), findsOneWidget);
    expect(find.byKey(const Key('ootd-image-slot-0')), findsOneWidget);
    expect(find.byKey(const Key('ootd-image-slot-3')), findsOneWidget);

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('ootd-save-button')),
    );
    expect(saveButton.onPressed, isNull);
  });
}
