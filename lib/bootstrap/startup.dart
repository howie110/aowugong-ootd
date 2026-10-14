import 'dart:convert';
import '../features/settings/data/ootd_backup_service.dart';

import '../shared/design/app_ui.dart';
import '../shared/design/app_theme.dart';
import '../features/settings/presentation/settings/backup_import_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app.dart';
import '../features/ootd/data/local_ootd_store.dart';
import '../features/ootd/presentation/home/mock_ootd_items.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  const store = OotdLocalStore();
  String dataDirectoryPath = '';
  try {
    dataDirectoryPath = await store.dataDirectoryPath();
    await const OotdBackupService(store: store).recoverInterruptedImport();
    final itemsJson = await store.loadItemsJson();
    final filtersJson = await store.loadFiltersJson();
    final optionsJson = await store.loadOptionsJson();

    final initialItems = itemsJson == null
        ? const <MockOotdItem>[]
        : itemsJson.map(MockOotdItem.fromJson).toList(growable: false);
    final normalizedStoredItems = normalizeItemsForStorageRoot(
      initialItems,
      dataDirectoryPath,
    );
    final initialFilters = filtersJson == null
        ? defaultOotdFilterState
        : OotdFilterState.fromJson(filtersJson);
    final initialOptions = optionsJson == null
        ? defaultOotdOptionConfig
        : OotdOptionConfig.fromJson(optionsJson);
    final normalizedItems = normalizeItemsForOptions(
      normalizedStoredItems,
      initialOptions,
    );

    if (itemsJson != null) {
      final previousItemsJson = initialItems
          .map((item) => item.toJson())
          .toList(growable: false);
      final nextItemsJson = normalizedStoredItems
          .map((item) => item.toJson())
          .toList(growable: false);
      if (jsonEncode(previousItemsJson) != jsonEncode(nextItemsJson)) {
        await store.saveItemsJson(nextItemsJson);
      }
    }

    runApp(
      ProviderScope(
        overrides: [
          ootdStorageRootProvider.overrideWithValue(dataDirectoryPath),
          initialOotdItemsProvider.overrideWithValue(normalizedItems),
          initialOotdFiltersProvider.overrideWithValue(initialFilters),
          initialOotdOptionConfigProvider.overrideWithValue(initialOptions),
        ],
        child: const DailyOotdApp(),
      ),
    );
  } catch (_) {
    runApp(
      ProviderScope(
        overrides: [
          ootdStorageRootProvider.overrideWithValue(dataDirectoryPath),
          initialOotdItemsProvider.overrideWithValue(const []),
        ],
        child: ShadcnApp(
          theme: AppTheme.light(),
          home: AppScaffold(
            appBar: const AppPageBar(title: Text('本地数据暂时无法读取')),
            body: Builder(
              builder: (context) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text('未清空或覆盖你的数据。请检查手机存储空间后重试；如果文件已损坏，可选择已有 ZIP 备份恢复。'),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    onPressed: bootstrap,
                    child: const Text('重新读取'),
                  ),
                  const SizedBox(height: 12),
                  OutlineButton(
                    onPressed: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => const BackupImportPage(),
                      ),
                    ),
                    child: const Text('从备份恢复'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
