import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local_ootd_store.dart';
import '../../../data/ootd_defaults.dart';
import '../../../domain/ootd_json_helpers.dart';
import '../../../domain/ootd_models.dart';
import '../../../domain/ootd_option_config.dart';

final ootdLocalStoreProvider = Provider<OotdLocalStore>(
  (ref) => const OotdLocalStore(),
);

final ootdStorageRootProvider = Provider<String>((ref) => '');

final initialOotdItemsProvider = Provider<List<MockOotdItem>>(
  (ref) => defaultMockOotdItems,
);

MockOotdItem createDraftOotdItem(OotdOptionConfig config) {
  return MockOotdItem(
    id: 'draft',
    images: [MockOotdImage.solid(id: 'draft-main', colorValue: 0xFFE3ECF8)],
    dateLabel: formatDateLabel(DateTime.now()),
    preference: config.preferences.first,
    season: config.seasons.first,
    scene: config.scenes.first,
    tone: config.tones.first,
    rating: config.ratings.first,
    extraSelections: {
      for (final group in config.extraGroups) group.key: group.values.first,
    },
  );
}

final _random = Random();

class OotdItemsNotifier extends Notifier<List<MockOotdItem>> {
  @override
  List<MockOotdItem> build() => ref.watch(initialOotdItemsProvider);

  void replaceAll(List<MockOotdItem> items) {
    state = List<MockOotdItem>.unmodifiable(items);
    _persist();
  }

  void updateItem({
    required String id,
    required List<MockOotdImage> images,
    required String dateLabel,
    required String preference,
    required String season,
    required String scene,
    required String tone,
    required String rating,
    required Map<String, String> extraSelections,
  }) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            images: List.unmodifiable(images),
            dateLabel: dateLabel,
            preference: preference,
            season: season,
            scene: scene,
            tone: tone,
            rating: rating,
            extraSelections: Map<String, String>.unmodifiable(extraSelections),
          )
        else
          item,
    ];
    _persist();
  }

  void addItem({
    required List<MockOotdImage> images,
    required String dateLabel,
    required String preference,
    required String season,
    required String scene,
    required String tone,
    required String rating,
    required Map<String, String> extraSelections,
  }) {
    final item = MockOotdItem(
      id: _nextItemId(),
      images: List.unmodifiable(images),
      dateLabel: dateLabel,
      preference: preference,
      season: season,
      scene: scene,
      tone: tone,
      rating: rating,
      extraSelections: Map<String, String>.unmodifiable(extraSelections),
    );

    state = [item, ...state];
    _persist();
  }

  bool hasItemOnDate(String dateLabel, {String? excludingId}) {
    for (final item in state) {
      if (item.dateLabel == dateLabel && item.id != excludingId) {
        return true;
      }
    }
    return false;
  }

  void deleteItem(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    _persist();
  }

  void renameOptionValueByKey(String key, String oldValue, String newValue) {
    state = [
      for (final item in state)
        item.valueOf(key) == oldValue ? item.copyWithValue(key, newValue) : item,
    ];
    _persist();
  }

  void replaceDeletedOptionValueByKey(
    String key,
    String removedValue,
    String fallbackValue,
  ) {
    state = [
      for (final item in state)
        item.valueOf(key) == removedValue
            ? item.copyWithValue(key, fallbackValue)
            : item,
    ];
    _persist();
  }

  void assignExtraGroupValue(String key, String defaultValue) {
    state = [
      for (final item in state)
        item.copyWith(
          extraSelections: {
            ...item.extraSelections,
            key: item.extraSelections[key] ?? defaultValue,
          },
        ),
    ];
    _persist();
  }

  void removeExtraGroupValue(String key) {
    state = [
      for (final item in state)
        item.copyWith(
          extraSelections: {
            for (final entry in item.extraSelections.entries)
              if (entry.key != key) entry.key: entry.value,
          },
        ),
    ];
    _persist();
  }

  void _persist() {
    unawaited(
      Future(() async {
        try {
          await ref
              .read(ootdLocalStoreProvider)
              .saveItemsJson(
                state.map((item) => item.toJson()).toList(growable: false),
              );
        } catch (e) {
          assert(() {
            // ignore: avoid_print
            print('OotdItemsNotifier._persist failed: $e');
            return true;
          }());
        }
      }),
    );
  }

  String _nextItemId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(9999).toString().padLeft(4, '0');
    return 'look-$now-$randomPart';
  }
}

final ootdItemsProvider =
    NotifierProvider<OotdItemsNotifier, List<MockOotdItem>>(
      OotdItemsNotifier.new,
    );
