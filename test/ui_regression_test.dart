import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aowugong_ootd/shared/design/app_ui.dart';
import 'package:aowugong_ootd/shared/design/app_theme.dart';
import 'package:aowugong_ootd/features/ootd/data/local_ootd_store.dart';
import 'package:aowugong_ootd/features/ootd/presentation/home/mock_ootd_items.dart';
import 'package:aowugong_ootd/features/ootd/presentation/home/home_page.dart';
import 'package:aowugong_ootd/features/ootd/presentation/detail/ootd_detail_page.dart';
import 'package:aowugong_ootd/features/ootd/presentation/detail/photo_selection_page.dart';
import 'package:aowugong_ootd/features/settings/presentation/settings/settings_page.dart';
import 'package:aowugong_ootd/features/settings/presentation/settings/option_management_page.dart';
import 'package:aowugong_ootd/features/settings/presentation/settings/backup_export_page.dart';
import 'package:aowugong_ootd/features/settings/presentation/settings/backup_import_page.dart';

class _FailingStore extends OotdLocalStore {
  @override
  Future<void> saveSnapshot({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> filters,
    required Map<String, dynamic> options,
  }) async => throw const FileSystemException('disk full');
  @override
  Future<void> saveItemsJson(List<Map<String, dynamic>> items) async =>
      throw const FileSystemException('disk full');
  @override
  Future<String?> loadLastExportZipPath() async => null;
}

void main() {
  Widget wrap(Widget child, {double scale = 1}) => ProviderScope(
    overrides: [ootdLocalStoreProvider.overrideWithValue(_FailingStore())],
    child: ShadcnApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    ),
  );

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('pages fit width $width text $scale', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final page in <Widget>[
          const AppScaffold(body: HomePage()),
          const OotdDetailPage(itemId: 'look-01'),
          const AppScaffold(body: SettingsPage()),
          const OptionManagementPage(),
          const BackupExportPage(),
          const BackupImportPage(),
        ]) {
          await tester.pumpWidget(wrap(page, scale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$page');
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  }

  testWidgets('failed save keeps edit page and changed draft', (tester) async {
    await tester.pumpWidget(wrap(const OotdDetailPage(itemId: 'look-01')));
    await tester.tap(find.text('冬'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ootd-save-button')));
    await tester.pumpAndSettle();
    expect(find.text('保存失败，修改仍保留，请重试'), findsOneWidget);
    expect(find.byType(OotdDetailPage), findsOneWidget);
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('ootd-save-button')))
          .onPressed,
      isNotNull,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(OotdDetailPage)),
    );
    expect(container.read(ootdItemsProvider).first.season, '春');
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('option validation and write failure retain entered text', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const OptionManagementPage()));
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is AppIconButton && w.tooltip == '新增内容')
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('内容不能为空'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '新的选项');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('保存失败，内容已保留，请重试'), findsOneWidget);
    expect(find.text('新的选项'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'back dialog fits small screen with large text and preserves draft',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => AppScaffold(
              body: PrimaryButton(
                onPressed: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, _, _) =>
                        const OotdDetailPage(itemId: 'look-01'),
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
          scale: 1.5,
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('冬'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((w) => w is AppIconButton && w.tooltip == '返回'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('继续编辑'), findsOneWidget);
      await tester.tap(find.text('继续编辑'));
      await tester.pumpAndSettle();
      expect(find.byType(OotdDetailPage), findsOneWidget);
    },
  );

  testWidgets('album error leaves a retry instead of a permanent spinner', (
    tester,
  ) async {
    const channel = MethodChannel('com.fluttercandies/photo_manager');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'test-error'),
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(wrap(const PhotoSelectionPage()));
    await tester.pumpAndSettle();
    expect(find.text('重新加载'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('重新加载'));
    await tester.pumpAndSettle();
    expect(find.text('重新加载'), findsOneWidget);
  });

  testWidgets('failed thumbnail can retry instead of spinning forever', (
    tester,
  ) async {
    const channel = MethodChannel('com.fluttercandies/photo_manager');
    var attempts = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      switch (call.method) {
        case 'requestPermissionExtend':
          return 3;
        case 'getAssetPathList':
          return {
            'data': [
              {'id': 'all', 'name': 'All', 'isAll': true, 'assetCount': 1},
            ],
          };
        case 'getAssetCountFromPath':
          return 1;
        case 'getAssetListPaged':
          return {
            'data': [
              {'id': 'photo', 'type': 1, 'width': 100, 'height': 100},
            ],
          };
        case 'getThumb':
          attempts++;
          throw PlatformException(code: 'thumbnail-unavailable');
        default:
          throw PlatformException(code: 'unexpected-${call.method}');
      }
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(wrap(const PhotoSelectionPage()));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.byWidgetPredicate((w) => w is AppIconButton && w.tooltip == '重试缩略图'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(
      find.byWidgetPredicate((w) => w is AppIconButton && w.tooltip == '重试缩略图'),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(attempts, 2);
  });
}
