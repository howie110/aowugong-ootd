import 'package:aowugong_ootd/app/app.dart';
import 'package:aowugong_ootd/features/ootd/presentation/detail/ootd_detail_page.dart';
import 'package:aowugong_ootd/features/ootd/presentation/home/home_page.dart';
import 'package:aowugong_ootd/features/ootd/presentation/home/mock_ootd_items.dart';
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

  test('option management can add custom option group', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = container
        .read(ootdOptionConfigProvider.notifier)
        .addExtraGroup('自定义');
    final config = container.read(ootdOptionConfigProvider);

    expect(result, OotdOptionEditResult.success);
    expect(config.extraGroups.length, 1);
    expect(config.extraGroups.single.key, 'extra_6');
    expect(config.extraGroups.single.values, ['自定义']);
  });

  test('ootd item notifier can delete an item', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(ootdItemsProvider).length, 9);

    container.read(ootdItemsProvider.notifier).deleteItem('look-01');

    expect(container.read(ootdItemsProvider).length, 8);
    expect(
      container.read(ootdItemsProvider).any((item) => item.id == 'look-01'),
      isFalse,
    );
  });

  test('create draft starts as an unsaved placeholder item', () {
    final draft = createDraftOotdItem(defaultOotdOptionConfig);

    expect(draft.id, 'draft');
    expect(draft.images.length, 1);
    expect(draft.primaryImage.sourceType, OotdImageSourceType.solidColor);
    expect(draft.preference, defaultOotdOptionConfig.preferences.first);
    expect(draft.season, defaultOotdOptionConfig.seasons.first);
    expect(
      draft.dateLabel,
      matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
    );
  });
}
