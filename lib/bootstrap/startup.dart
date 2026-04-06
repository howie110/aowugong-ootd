import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app.dart';
import '../features/ootd/data/local_ootd_store.dart';
import '../features/ootd/presentation/home/mock_ootd_items.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  const store = OotdLocalStore();
  final itemsJson = await store.loadItemsJson();
  final filtersJson = await store.loadFiltersJson();
  final optionsJson = await store.loadOptionsJson();

  final initialItems = itemsJson == null
      ? defaultMockOotdItems
      : itemsJson.map(MockOotdItem.fromJson).toList(growable: false);
  final initialFilters = filtersJson == null
      ? defaultOotdFilterState
      : OotdFilterState.fromJson(filtersJson);
  final initialOptions = optionsJson == null
      ? defaultOotdOptionConfig
      : OotdOptionConfig.fromJson(optionsJson);
  final normalizedItems = normalizeItemsForOptions(initialItems, initialOptions);

  runApp(
    ProviderScope(
      overrides: [
        initialOotdItemsProvider.overrideWithValue(normalizedItems),
        initialOotdFiltersProvider.overrideWithValue(initialFilters),
        initialOotdOptionConfigProvider.overrideWithValue(initialOptions),
      ],
      child: const DailyOotdApp(),
    ),
  );
}
