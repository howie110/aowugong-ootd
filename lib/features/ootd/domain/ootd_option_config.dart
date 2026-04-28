import 'ootd_json_helpers.dart';
import 'ootd_models.dart';

class OotdOptionConfig {
  const OotdOptionConfig({
    this.preferences = const ['喜欢', '不喜欢'],
    this.seasons = const ['春', '夏', '秋', '冬'],
    this.scenes = const ['工作', '休息'],
    this.tones = const ['黑白', '冷色', '暖色'],
    this.ratings = const ['1星', '2星', '3星', '4星', '5星'],
    this.extraGroups = const [],
    this.hiddenBuiltInKeys = const [],
  });

  final List<String> preferences;
  final List<String> seasons;
  final List<String> scenes;
  final List<String> tones;
  final List<String> ratings;
  final List<OotdExtraOptionGroup> extraGroups;
  final List<String> hiddenBuiltInKeys;

  OotdOptionConfig copyWith({
    List<String>? preferences,
    List<String>? seasons,
    List<String>? scenes,
    List<String>? tones,
    List<String>? ratings,
    List<OotdExtraOptionGroup>? extraGroups,
    List<String>? hiddenBuiltInKeys,
  }) {
    return OotdOptionConfig(
      preferences: preferences ?? this.preferences,
      seasons: seasons ?? this.seasons,
      scenes: scenes ?? this.scenes,
      tones: tones ?? this.tones,
      ratings: ratings ?? this.ratings,
      extraGroups: extraGroups ?? this.extraGroups,
      hiddenBuiltInKeys: hiddenBuiltInKeys ?? this.hiddenBuiltInKeys,
    );
  }

  List<String> valuesOf(OotdOptionCategory category) {
    return switch (category) {
      OotdOptionCategory.preference => preferences,
      OotdOptionCategory.season => seasons,
      OotdOptionCategory.scene => scenes,
      OotdOptionCategory.tone => tones,
      OotdOptionCategory.rating => ratings,
    };
  }

  List<String> valuesOfKey(String key) {
    for (final category in OotdOptionCategory.values) {
      if (category.storageKey == key) {
        return valuesOf(category);
      }
    }

    for (final group in extraGroups) {
      if (group.key == key) {
        return group.values;
      }
    }

    return const [];
  }

  OotdOptionConfig copyWithCategory(
    OotdOptionCategory category,
    List<String> values,
  ) {
    final normalized = List<String>.unmodifiable(values);
    return switch (category) {
      OotdOptionCategory.preference => copyWith(preferences: normalized),
      OotdOptionCategory.season => copyWith(seasons: normalized),
      OotdOptionCategory.scene => copyWith(scenes: normalized),
      OotdOptionCategory.tone => copyWith(tones: normalized),
      OotdOptionCategory.rating => copyWith(ratings: normalized),
    };
  }

  OotdOptionConfig copyWithKey(String key, List<String> values) {
    for (final category in OotdOptionCategory.values) {
      if (category.storageKey == key) {
        return copyWithCategory(category, values);
      }
    }

    final normalized = List<String>.unmodifiable(values);
    return copyWith(
      extraGroups: [
        for (final group in extraGroups)
          if (group.key == key) group.copyWith(values: normalized) else group,
      ],
    );
  }

  bool isBuiltInKey(String key) {
    return OotdOptionCategory.values.any((category) => category.storageKey == key);
  }

  List<OotdOptionGroup> get allGroups {
    return [
      for (final category in OotdOptionCategory.values)
        if (!hiddenBuiltInKeys.contains(category.storageKey))
        OotdOptionGroup(
          key: category.storageKey,
          values: valuesOf(category),
          builtInCategory: category,
        ),
      for (final group in extraGroups)
        OotdOptionGroup(key: group.key, values: group.values),
    ];
  }

  String nextExtraGroupKey() {
    var index = 6;
    while (extraGroups.any((group) => group.key == 'extra_$index')) {
      index++;
    }
    return 'extra_$index';
  }

  Map<String, dynamic> toJson() {
    return {
      'preferences': preferences,
      'seasons': seasons,
      'scenes': scenes,
      'tones': tones,
      'ratings': ratings,
      'extraGroups': extraGroups
          .map((group) => group.toJson())
          .toList(growable: false),
      'hiddenBuiltInKeys': hiddenBuiltInKeys,
    };
  }

  factory OotdOptionConfig.fromJson(Map<String, dynamic> json) {
    List<String> readValues(String key, List<String> defaults) {
      final value = json[key];
      if (value is! List) {
        return defaults;
      }

      final normalized = value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);

      return normalized.isEmpty ? defaults : normalized;
    }

    return OotdOptionConfig(
      preferences: readValues('preferences', const ['喜欢', '不喜欢']),
      seasons: readValues('seasons', const ['春', '夏', '秋', '冬']),
      scenes: readValues('scenes', const ['工作', '休息']),
      tones: readValues('tones', const ['黑白', '冷色', '暖色']),
      ratings: readValues('ratings', const ['1星', '2星', '3星', '4星', '5星']),
      extraGroups: readExtraOptionGroups(json['extraGroups']),
      hiddenBuiltInKeys: readValues('hiddenBuiltInKeys', const []),
    );
  }
}
