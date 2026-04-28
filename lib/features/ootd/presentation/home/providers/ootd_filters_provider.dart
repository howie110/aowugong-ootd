import 'dart:async';

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

  void replaceAll(OotdFilterState nextState) {
    state = nextState;
    _persist();
  }

  void toggleSeason(String season) {
    toggleOption(OotdOptionCategory.season.storageKey, season);
  }

  void togglePreference(String preference) {
    toggleOption(OotdOptionCategory.preference.storageKey, preference);
  }

  void toggleScene(String scene) {
    toggleOption(OotdOptionCategory.scene.storageKey, scene);
  }

  void toggleTone(String tone) {
    toggleOption(OotdOptionCategory.tone.storageKey, tone);
  }

  void toggleRating(String rating) {
    toggleOption(OotdOptionCategory.rating.storageKey, rating);
  }

  void toggleOption(String key, String value) {
    state = _copyWithValuesForKey(key, _toggleValues(state.valuesOf(key), value));
    _persist();
  }

  void renameOptionValueByKey(String key, String oldValue, String newValue) {
    state = _copyWithValuesForKey(
      key,
      _renameValues(state.valuesOf(key), oldValue, newValue),
    );
    _persist();
  }

  void removeDeletedOptionValueByKey(String key, String value) {
    state = _copyWithValuesForKey(
      key,
      state.valuesOf(key).where((item) => item != value).toList(),
    );
    _persist();
  }

  void removeGroupByKey(String key) {
    if (OotdOptionCategory.values.any((category) => category.storageKey == key)) {
      state = _copyWithValuesForKey(key, const []);
    } else {
      state = state.copyWith(
        extraSelections: {
          for (final entry in state.extraSelections.entries)
            if (entry.key != key) entry.key: entry.value,
        },
      );
    }
    _persist();
  }

  void _persist() {
    unawaited(
      Future(() async {
        try {
          await ref.read(ootdLocalStoreProvider).saveFiltersJson(state.toJson());
        } catch (e) {
          assert(() {
            // ignore: avoid_print
            print('OotdFiltersNotifier._persist failed: $e');
            return true;
          }());
        }
      }),
    );
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
