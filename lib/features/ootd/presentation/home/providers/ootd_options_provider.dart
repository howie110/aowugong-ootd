import 'ootd_mutation_queue.dart';
import '../../../domain/ootd_filter_state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/ootd_defaults.dart';
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

  void acceptPersisted(OotdOptionConfig value) => state = value;

  Future<void> replaceAll(OotdOptionConfig value) =>
      ref.read(ootdMutationQueueProvider).run(() async {
        await ref.read(ootdLocalStoreProvider).saveOptionsJson(value.toJson());
        if (ref.mounted) state = value;
      });

  Future<OotdOptionEditResult> _edit(
    OotdOptionEditResult Function(_OptionDraft) edit,
  ) => ref.read(ootdMutationQueueProvider).run(() async {
    final draft = _OptionDraft(
      state,
      ref.read(ootdItemsProvider),
      ref.read(ootdFiltersProvider),
    );
    final result = edit(draft);
    if (result != OotdOptionEditResult.success) return result;
    await ref
        .read(ootdLocalStoreProvider)
        .saveSnapshot(
          items: draft.items.map((item) => item.toJson()).toList(),
          filters: draft.filters.toJson(),
          options: draft.state.toJson(),
        );
    if (ref.mounted) {
      ref.read(ootdItemsProvider.notifier).acceptPersisted(draft.items);
      ref.read(ootdFiltersProvider.notifier).acceptPersisted(draft.filters);
      state = draft.state;
    }
    return result;
  });

  Future<OotdOptionEditResult> addOption(
    OotdOptionCategory category,
    String value,
  ) => addOptionByKey(category.storageKey, value);
  Future<OotdOptionEditResult> addOptionByKey(String key, String value) =>
      _edit((d) => d.addOptionByKey(key, value));
  Future<OotdOptionEditResult> addExtraGroup(String value) =>
      _edit((d) => d.addExtraGroup(value));
  Future<OotdOptionEditResult> deleteGroupByKey(String key) =>
      _edit((d) => d.deleteGroupByKey(key));
  Future<OotdOptionEditResult> renameOption(
    OotdOptionCategory category,
    String oldValue,
    String value,
  ) => renameOptionByKey(category.storageKey, oldValue, value);
  Future<OotdOptionEditResult> renameOptionByKey(
    String key,
    String oldValue,
    String value,
  ) => _edit((d) => d.renameOptionByKey(key, oldValue, value));
  Future<OotdOptionEditResult> deleteOption(
    OotdOptionCategory category,
    String value,
  ) => deleteOptionByKey(category.storageKey, value);
  Future<OotdOptionEditResult> deleteOptionByKey(String key, String value) =>
      _edit((d) => d.deleteOptionByKey(key, value));
}

class _OptionDraft {
  _OptionDraft(this.state, this.items, this.filters);
  OotdOptionConfig state;
  List<MockOotdItem> items;
  OotdFilterState filters;

  void _items(String key, String oldValue, String value) {
    items = [
      for (final item in items)
        item.valueOf(key) == oldValue ? item.copyWithValue(key, value) : item,
    ];
  }

  void _filter(String key, List<String> Function(List<String>) change) {
    final json = filters.toJson();
    final values = change(filters.valuesOf(key));
    if (state.isBuiltInKey(key)) {
      json[key] = values;
    } else {
      json['extraSelections'] = {...filters.extraSelections, key: values};
    }
    filters = OotdFilterState.fromJson(json);
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
    items = [for (final item in items) item.copyWithValue(key, value)];
    return OotdOptionEditResult.success;
  }

  OotdOptionEditResult deleteGroupByKey(String key) {
    if (state.isBuiltInKey(key)) {
      state = state.copyWith(
        hiddenBuiltInKeys: [...state.hiddenBuiltInKeys, key],
      );
      _filter(key, (_) => const []);
      return OotdOptionEditResult.success;
    }

    state = state.copyWith(
      extraGroups: state.extraGroups
          .where((group) => group.key != key)
          .toList(growable: false),
    );
    items = [
      for (final item in items)
        item.copyWith(extraSelections: {...item.extraSelections}..remove(key)),
    ];
    _filter(key, (_) => const []);
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
    _items(key, oldValue, value);
    _filter(
      key,
      (values) => [for (final v in values) v == oldValue ? value : v],
    );
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
    _items(key, value, fallback);
    _filter(key, (values) => values.where((v) => v != value).toList());
    return OotdOptionEditResult.success;
  }
}

final ootdOptionConfigProvider =
    NotifierProvider<OotdOptionConfigNotifier, OotdOptionConfig>(
      OotdOptionConfigNotifier.new,
    );
