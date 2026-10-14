import 'ootd_mutation_queue.dart';
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

  Future<void> replaceAll(List<MockOotdItem> items) =>
      ref.read(ootdMutationQueueProvider).run(() async {
        final next = List<MockOotdItem>.unmodifiable(items);
        await _commit(next);
      });

  Future<void> updateItem({
    required String id,
    required List<MockOotdImage> images,
    required String dateLabel,
    required String preference,
    required String season,
    required String scene,
    required String tone,
    required String rating,
    required Map<String, String> extraSelections,
  }) => ref.read(ootdMutationQueueProvider).run(() async {
    if (hasItemOnDate(dateLabel, excludingId: id)) throw StateError('这一天已经有穿搭');

    final next = [
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
    await _commit(next);
  });

  Future<void> addItem({
    required List<MockOotdImage> images,
    required String dateLabel,
    required String preference,
    required String season,
    required String scene,
    required String tone,
    required String rating,
    required Map<String, String> extraSelections,
  }) => ref.read(ootdMutationQueueProvider).run(() async {
    if (hasItemOnDate(dateLabel)) throw StateError('这一天已经有穿搭');

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

    final next = [item, ...state];
    await _commit(next);
  });

  bool hasItemOnDate(String dateLabel, {String? excludingId}) {
    for (final item in state) {
      if (item.dateLabel == dateLabel && item.id != excludingId) {
        return true;
      }
    }
    return false;
  }

  Future<void> deleteItem(String id) => ref.read(ootdMutationQueueProvider).run(
    () async {
      final next = state.where((item) => item.id != id).toList(growable: false);
      await _commit(next);
    },
  );

  Future<void> renameOptionValueByKey(
    String key,
    String oldValue,
    String newValue,
  ) => ref.read(ootdMutationQueueProvider).run(() async {
    final next = [
      for (final item in state)
        item.valueOf(key) == oldValue
            ? item.copyWithValue(key, newValue)
            : item,
    ];
    await _commit(next);
  });

  Future<void> replaceDeletedOptionValueByKey(
    String key,
    String removedValue,
    String fallbackValue,
  ) => ref.read(ootdMutationQueueProvider).run(() async {
    final next = [
      for (final item in state)
        item.valueOf(key) == removedValue
            ? item.copyWithValue(key, fallbackValue)
            : item,
    ];
    await _commit(next);
  });

  Future<void> assignExtraGroupValue(String key, String defaultValue) =>
      ref.read(ootdMutationQueueProvider).run(() async {
        final next = [
          for (final item in state)
            item.copyWith(
              extraSelections: {
                ...item.extraSelections,
                key: item.extraSelections[key] ?? defaultValue,
              },
            ),
        ];
        await _commit(next);
      });

  Future<void> removeExtraGroupValue(String key) =>
      ref.read(ootdMutationQueueProvider).run(() async {
        final next = [
          for (final item in state)
            item.copyWith(
              extraSelections: {
                for (final entry in item.extraSelections.entries)
                  if (entry.key != key) entry.key: entry.value,
              },
            ),
        ];
        await _commit(next);
      });

  void acceptPersisted(List<MockOotdItem> items) {
    state = List.unmodifiable(items);
  }

  Future<void> _commit(List<MockOotdItem> next) async {
    await ref
        .read(ootdLocalStoreProvider)
        .saveItemsJson(
          next.map((item) => item.toJson()).toList(growable: false),
        );
    if (ref.mounted) state = List.unmodifiable(next);
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
