import 'ootd_mutation_queue.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/ootd_defaults.dart';
import '../../../domain/ootd_filter_state.dart';
import '../../../domain/ootd_models.dart';
import 'ootd_items_provider.dart';

final initialOotdFiltersProvider = Provider<OotdFilterState>(
  (ref) => defaultOotdFilterState,
);

class OotdFiltersNotifier extends Notifier<OotdFilterState> {
  @override
  OotdFilterState build() => ref.watch(initialOotdFiltersProvider);

  Future<void> replaceAll(OotdFilterState nextState) =>
      ref.read(ootdMutationQueueProvider).run(() async {
        late OotdFilterState next;
        next = nextState;
        await _commit(next);
      });

  Future<void> toggleSeason(String season) =>
      toggleOption(OotdOptionCategory.season.storageKey, season);

  Future<void> togglePreference(String preference) =>
      toggleOption(OotdOptionCategory.preference.storageKey, preference);

  Future<void> toggleScene(String scene) =>
      toggleOption(OotdOptionCategory.scene.storageKey, scene);

  Future<void> toggleTone(String tone) =>
      toggleOption(OotdOptionCategory.tone.storageKey, tone);

  Future<void> toggleRating(String rating) =>
      toggleOption(OotdOptionCategory.rating.storageKey, rating);

  Future<void> toggleOption(String key, String value) =>
      ref.read(ootdMutationQueueProvider).run(() async {
        late OotdFilterState next;
        next = _copyWithValuesForKey(
          key,
          _toggleValues(state.valuesOf(key), value),
        );
        await _commit(next);
      });

  Future<void> renameOptionValueByKey(
    String key,
    String oldValue,
    String newValue,
  ) => ref.read(ootdMutationQueueProvider).run(() async {
    late OotdFilterState next;
    next = _copyWithValuesForKey(
      key,
      _renameValues(state.valuesOf(key), oldValue, newValue),
    );
    await _commit(next);
  });

  Future<void> removeDeletedOptionValueByKey(String key, String value) =>
      ref.read(ootdMutationQueueProvider).run(() async {
        late OotdFilterState next;
        next = _copyWithValuesForKey(
          key,
          state.valuesOf(key).where((item) => item != value).toList(),
        );
        await _commit(next);
      });

  Future<void> removeGroupByKey(String key) =>
      ref.read(ootdMutationQueueProvider).run(() async {
        late OotdFilterState next;
        if (OotdOptionCategory.values.any(
          (category) => category.storageKey == key,
        )) {
          next = _copyWithValuesForKey(key, const []);
        } else {
          next = state.copyWith(
            extraSelections: {
              for (final entry in state.extraSelections.entries)
                if (entry.key != key) entry.key: entry.value,
            },
          );
        }
        await _commit(next);
      });

  void acceptPersisted(OotdFilterState value) => state = value;

  Future<void> _commit(OotdFilterState value) async {
    await ref.read(ootdLocalStoreProvider).saveFiltersJson(value.toJson());
    if (ref.mounted) state = value;
  }

  List<String> _toggleValues(List<String> current, String value) {
    if (current.contains(value)) {
      return current.where((item) => item != value).toList(growable: false);
    }

    return [...current, value];
  }

  List<String> _renameValues(
    List<String> current,
    String oldValue,
    String newValue,
  ) {
    return [
      for (final item in current)
        if (item == oldValue) newValue else item,
    ];
  }

  OotdFilterState _copyWithValuesForKey(String key, List<String> values) {
    return switch (key) {
      'preferences' => state.copyWith(preferences: values),
      'seasons' => state.copyWith(seasons: values),
      'scenes' => state.copyWith(scenes: values),
      'tones' => state.copyWith(tones: values),
      'ratings' => state.copyWith(ratings: values),
      _ => state.copyWith(
        extraSelections: {
          ...state.extraSelections,
          key: List<String>.unmodifiable(values),
        },
      ),
    };
  }
}

final ootdFiltersProvider =
    NotifierProvider<OotdFiltersNotifier, OotdFilterState>(
      OotdFiltersNotifier.new,
    );
