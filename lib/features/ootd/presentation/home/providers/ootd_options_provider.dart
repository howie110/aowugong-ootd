import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/ootd_defaults.dart';
import '../../../domain/ootd_json_helpers.dart';
import '../../../domain/ootd_models.dart';
import '../../../domain/ootd_option_config.dart';
import 'ootd_filters_provider.dart';
import 'ootd_items_provider.dart';

final initialOotdOptionConfigProvider = Provider<OotdOptionConfig>(
  (ref) => defaultOotdOptionConfig,
);

class OotdOptionConfigNotifier extends Notifier<OotdOptionConfig> {
  @override
  OotdOptionConfig build() => ref.watch(initialOotdOptionConfigProvider);

  void replaceAll(OotdOptionConfig nextState) {
    state = nextState;
    _persist();
  }

  OotdOptionEditResult addOption(OotdOptionCategory category, String rawValue) {
    return addOptionByKey(category.storageKey, rawValue);
  }

  OotdOptionEditResult addOptionByKey(String key, String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return OotdOptionEditResult.emptyValue;
    }

    final current = state.valuesOfKey(key);
    if (current.contains(value)) {
      return OotdOptionEditResult.duplicateValue;
    }

    state = state.copyWithKey(key, [...current, value]);
    _persist();
    return OotdOptionEditResult.success;
  }

  OotdOptionEditResult addExtraGroup(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return OotdOptionEditResult.emptyValue;
    }

    final key = state.nextExtraGroupKey();
    state = state.copyWith(
      extraGroups: [
        ...state.extraGroups,
        OotdExtraOptionGroup(key: key, values: [value]),
      ],
    );
    ref.read(ootdItemsProvider.notifier).assignExtraGroupValue(key, value);
    _persist();
    return OotdOptionEditResult.success;
  }

  OotdOptionEditResult deleteGroupByKey(String key) {
    if (state.isBuiltInKey(key)) {
      state = state.copyWith(
        hiddenBuiltInKeys: [...state.hiddenBuiltInKeys, key],
      );
      ref.read(ootdFiltersProvider.notifier).removeGroupByKey(key);
      _persist();
      return OotdOptionEditResult.success;
    }

    state = state.copyWith(
      extraGroups: state.extraGroups
          .where((group) => group.key != key)
          .toList(growable: false),
    );
    ref.read(ootdItemsProvider.notifier).removeExtraGroupValue(key);
    ref.read(ootdFiltersProvider.notifier).removeGroupByKey(key);
    _persist();
    return OotdOptionEditResult.success;
  }

  OotdOptionEditResult renameOption(
    OotdOptionCategory category,
    String oldValue,
    String rawValue,
  ) {
    return renameOptionByKey(category.storageKey, oldValue, rawValue);
  }

  OotdOptionEditResult renameOptionByKey(
    String key,
    String oldValue,
    String rawValue,
  ) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return OotdOptionEditResult.emptyValue;
    }

    final current = state.valuesOfKey(key);
    if (oldValue == value) {
      return OotdOptionEditResult.success;
    }
    if (current.contains(value)) {
      return OotdOptionEditResult.duplicateValue;
    }

    state = state.copyWithKey(key, [
      for (final item in current)
        if (item == oldValue) value else item,
    ]);
    ref
        .read(ootdItemsProvider.notifier)
        .renameOptionValueByKey(key, oldValue, value);
    ref
        .read(ootdFiltersProvider.notifier)
        .renameOptionValueByKey(key, oldValue, value);
    _persist();
    return OotdOptionEditResult.success;
  }

  OotdOptionEditResult deleteOption(OotdOptionCategory category, String value) {
    return deleteOptionByKey(category.storageKey, value);
  }

  OotdOptionEditResult deleteOptionByKey(String key, String value) {
    final current = state.valuesOfKey(key);
    if (current.length <= 1) {
      return OotdOptionEditResult.minimumReached;
    }

    final remaining = current
        .where((item) => item != value)
        .toList(growable: false);
    final fallback = remaining.first;

    state = state.copyWithKey(key, remaining);
    ref
        .read(ootdItemsProvider.notifier)
        .replaceDeletedOptionValueByKey(key, value, fallback);
    ref
        .read(ootdFiltersProvider.notifier)
        .removeDeletedOptionValueByKey(key, value);
    _persist();
    return OotdOptionEditResult.success;
  }

  void _persist() {
    unawaited(
      Future(() async {
        try {
          await ref.read(ootdLocalStoreProvider).saveOptionsJson(state.toJson());
        } catch (e) {
          assert(() {
            // ignore: avoid_print
            print('OotdOptionConfigNotifier._persist failed: $e');
            return true;
          }());
        }
      }),
    );
  }
}

final ootdOptionConfigProvider =
    NotifierProvider<OotdOptionConfigNotifier, OotdOptionConfig>(
      OotdOptionConfigNotifier.new,
    );
