import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/ootd_models.dart';
import 'ootd_filters_provider.dart';
import 'ootd_items_provider.dart';
import 'ootd_options_provider.dart';

final filteredOotdItemsProvider = Provider<List<MockOotdItem>>((ref) {
  final filters = ref.watch(ootdFiltersProvider);
  final items = ref.watch(ootdItemsProvider);
  final optionConfig = ref.watch(ootdOptionConfigProvider);

  return items
      .where((item) {
        final preferenceMatch =
            filters.preferences.isEmpty ||
            filters.preferences.contains(item.preference);
        final seasonMatch =
            filters.seasons.isEmpty || filters.seasons.contains(item.season);
        final sceneMatch =
            filters.scenes.isEmpty || filters.scenes.contains(item.scene);
        final toneMatch =
            filters.tones.isEmpty || filters.tones.contains(item.tone);
        final ratingMatch =
            filters.ratings.isEmpty || filters.ratings.contains(item.rating);
        final extraMatches = [
          for (final group in optionConfig.extraGroups)
            filters.valuesOf(group.key).isEmpty ||
                filters.valuesOf(group.key).contains(
                  item.valueOf(group.key, fallback: group.values.first),
                ),
        ].every((matched) => matched);

        return preferenceMatch &&
            seasonMatch &&
            sceneMatch &&
            toneMatch &&
            ratingMatch &&
            extraMatches;
      })
      .toList(growable: false);
});

final _ootdItemsMapProvider = Provider<Map<String, MockOotdItem>>((ref) {
  final items = ref.watch(ootdItemsProvider);
  return {for (final item in items) item.id: item};
});

final ootdByIdProvider = Provider.family<MockOotdItem?, String>((ref, id) {
  return ref.watch(_ootdItemsMapProvider)[id];
});
