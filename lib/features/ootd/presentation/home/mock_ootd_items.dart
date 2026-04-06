import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_ootd_store.dart';

enum OotdImageSourceType { asset, file, solidColor }

enum OotdOptionCategory {
  preference('偏好', 'preferences'),
  season('季节', 'seasons'),
  scene('场景', 'scenes'),
  tone('色调', 'tones'),
  rating('评星', 'ratings');

  const OotdOptionCategory(this.label, this.storageKey);

  final String label;
  final String storageKey;
}

enum OotdOptionEditResult {
  success,
  emptyValue,
  duplicateValue,
  minimumReached,
}

class OotdExtraOptionGroup {
  const OotdExtraOptionGroup({required this.key, required this.values});

  final String key;
  final List<String> values;

  OotdExtraOptionGroup copyWith({String? key, List<String>? values}) {
    return OotdExtraOptionGroup(
      key: key ?? this.key,
      values: values ?? this.values,
    );
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'values': values};
  }

  factory OotdExtraOptionGroup.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];
    return OotdExtraOptionGroup(
      key: json['key'] as String,
      values: rawValues is List
          ? rawValues
                .whereType<String>()
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}

class OotdOptionGroup {
  const OotdOptionGroup({
    required this.key,
    required this.values,
    this.builtInCategory,
  });

  final String key;
  final List<String> values;
  final OotdOptionCategory? builtInCategory;

  bool get isBuiltIn => builtInCategory != null;
}

class MockOotdImage {
  const MockOotdImage({
    required this.id,
    required this.sourceType,
    this.path,
    this.colorValue,
  });

  final String id;
  final OotdImageSourceType sourceType;
  final String? path;
  final int? colorValue;

  factory MockOotdImage.asset({required String id, required String assetPath}) {
    return MockOotdImage(
      id: id,
      sourceType: OotdImageSourceType.asset,
      path: assetPath,
    );
  }

  factory MockOotdImage.file({required String id, required String filePath}) {
    return MockOotdImage(
      id: id,
      sourceType: OotdImageSourceType.file,
      path: filePath,
    );
  }

  factory MockOotdImage.solid({required String id, required int colorValue}) {
    return MockOotdImage(
      id: id,
      sourceType: OotdImageSourceType.solidColor,
      colorValue: colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceType': sourceType.name,
      'path': path,
      'colorValue': colorValue,
    };
  }

  factory MockOotdImage.fromJson(Map<String, dynamic> json) {
    return MockOotdImage(
      id: json['id'] as String,
      sourceType: OotdImageSourceType.values.byName(
        json['sourceType'] as String,
      ),
      path: json['path'] as String?,
      colorValue: json['colorValue'] as int?,
    );
  }

  bool sameValueAs(MockOotdImage other) {
    return id == other.id &&
        sourceType == other.sourceType &&
        path == other.path &&
        colorValue == other.colorValue;
  }
}

class MockOotdItem {
  const MockOotdItem({
    required this.id,
    required this.images,
    required this.dateLabel,
    required this.preference,
    required this.season,
    required this.scene,
    required this.tone,
    required this.rating,
    this.extraSelections = const {},
  }) : assert(images.length >= 1 && images.length <= 4);

  final String id;
  final List<MockOotdImage> images;
  final String dateLabel;
  final String preference;
  final String season;
  final String scene;
  final String tone;
  final String rating;
  final Map<String, String> extraSelections;

  MockOotdImage get primaryImage => images.first;

  List<MockOotdImage> get secondaryImages =>
      images.skip(1).toList(growable: false);

  MockOotdItem copyWith({
    List<MockOotdImage>? images,
    String? dateLabel,
    String? preference,
    String? season,
    String? scene,
    String? tone,
    String? rating,
    Map<String, String>? extraSelections,
  }) {
    return MockOotdItem(
      id: id,
      images: images ?? this.images,
      dateLabel: dateLabel ?? this.dateLabel,
      preference: preference ?? this.preference,
      season: season ?? this.season,
      scene: scene ?? this.scene,
      tone: tone ?? this.tone,
      rating: rating ?? this.rating,
      extraSelections: extraSelections ?? this.extraSelections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'images': images.map((image) => image.toJson()).toList(growable: false),
      'dateLabel': dateLabel,
      'preference': preference,
      'season': season,
      'scene': scene,
      'tone': tone,
      'rating': rating,
      'extraSelections': extraSelections,
    };
  }

  factory MockOotdItem.fromJson(Map<String, dynamic> json) {
    return MockOotdItem(
      id: json['id'] as String,
      images: (json['images'] as List)
          .map(
            (image) => MockOotdImage.fromJson(Map<String, dynamic>.from(image)),
          )
          .toList(growable: false),
      dateLabel: _readDateLabel(json['dateLabel']),
      preference: _readLegacyPreference(json['preference']),
      season: _readLegacySeason(json['season']),
      scene: _readLegacyScene(json['scene']),
      tone: _readLegacyTone(json['tone']),
      rating: _readLegacyRating(json['rating']),
      extraSelections: _readExtraSelections(json['extraSelections']),
    );
  }

  bool sameContentAs(MockOotdItem other) {
    if (dateLabel != other.dateLabel ||
        preference != other.preference ||
        season != other.season ||
        scene != other.scene ||
        tone != other.tone ||
        rating != other.rating ||
        extraSelections.length != other.extraSelections.length ||
        images.length != other.images.length) {
      return false;
    }

    for (final entry in extraSelections.entries) {
      if (other.extraSelections[entry.key] != entry.value) {
        return false;
      }
    }

    for (var index = 0; index < images.length; index++) {
      if (!images[index].sameValueAs(other.images[index])) {
        return false;
      }
    }

    return true;
  }

  String valueOf(String key, {String? fallback}) {
    return switch (key) {
      'preferences' => preference,
      'seasons' => season,
      'scenes' => scene,
      'tones' => tone,
      'ratings' => rating,
      _ => extraSelections[key] ?? fallback ?? '',
    };
  }

  MockOotdItem copyWithValue(String key, String value) {
    return switch (key) {
      'preferences' => copyWith(preference: value),
      'seasons' => copyWith(season: value),
      'scenes' => copyWith(scene: value),
      'tones' => copyWith(tone: value),
      'ratings' => copyWith(rating: value),
      _ => copyWith(extraSelections: {...extraSelections, key: value}),
    };
  }

  MockOotdItem normalizedForConfig(OotdOptionConfig config) {
    if (config.extraGroups.isEmpty) {
      return copyWith(extraSelections: const {});
    }

    final nextExtraSelections = <String, String>{};
    for (final group in config.extraGroups) {
      final current = extraSelections[group.key];
      nextExtraSelections[group.key] = current ?? group.values.first;
    }

    return copyWith(extraSelections: nextExtraSelections);
  }
}

class OotdFilterState {
  const OotdFilterState({
    this.preferences = const [],
    this.seasons = const [],
    this.scenes = const [],
    this.tones = const [],
    this.ratings = const [],
    this.extraSelections = const {},
  });

  final List<String> preferences;
  final List<String> seasons;
  final List<String> scenes;
  final List<String> tones;
  final List<String> ratings;
  final Map<String, List<String>> extraSelections;

  OotdFilterState copyWith({
    Object? preferences = _unset,
    Object? seasons = _unset,
    Object? scenes = _unset,
    Object? tones = _unset,
    Object? ratings = _unset,
    Object? extraSelections = _unset,
  }) {
    return OotdFilterState(
      preferences: preferences == _unset
          ? this.preferences
          : List.unmodifiable(preferences as List<String>),
      seasons: seasons == _unset
          ? this.seasons
          : List.unmodifiable(seasons as List<String>),
      scenes: scenes == _unset
          ? this.scenes
          : List.unmodifiable(scenes as List<String>),
      tones: tones == _unset
          ? this.tones
          : List.unmodifiable(tones as List<String>),
      ratings: ratings == _unset
          ? this.ratings
          : List.unmodifiable(ratings as List<String>),
      extraSelections: extraSelections == _unset
          ? this.extraSelections
          : Map<String, List<String>>.unmodifiable(
              (extraSelections as Map<String, List<String>>).map(
                (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
              ),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferences': preferences,
      'seasons': seasons,
      'scenes': scenes,
      'tones': tones,
      'ratings': ratings,
      'extraSelections': extraSelections,
    };
  }

  factory OotdFilterState.fromJson(Map<String, dynamic> json) {
    List<String> readValues(
      String key,
      String legacyKey,
      String Function(dynamic value) parser,
    ) {
      final current = json[key];
      if (current is List) {
        return current.map(parser).where((value) => value.isNotEmpty).toList();
      }

      final legacy = json[legacyKey];
      if (legacy == null) {
        return const [];
      }

      final parsed = parser(legacy);
      return parsed.isEmpty ? const [] : [parsed];
    }

    return OotdFilterState(
      preferences: readValues(
        'preferences',
        'preference',
        _readLegacyPreference,
      ),
      seasons: readValues('seasons', 'season', _readLegacySeason),
      scenes: readValues('scenes', 'scene', _readLegacyScene),
      tones: readValues('tones', 'tone', _readLegacyTone),
      ratings: readValues('ratings', 'rating', _readLegacyRating),
      extraSelections: _readExtraFilterSelections(json['extraSelections']),
    );
  }

  List<String> valuesOf(String key) {
    return switch (key) {
      'preferences' => preferences,
      'seasons' => seasons,
      'scenes' => scenes,
      'tones' => tones,
      'ratings' => ratings,
      _ => extraSelections[key] ?? const [],
    };
  }

  bool get hasAnySelection {
    if (preferences.isNotEmpty ||
        seasons.isNotEmpty ||
        scenes.isNotEmpty ||
        tones.isNotEmpty ||
        ratings.isNotEmpty) {
      return true;
    }

    return extraSelections.values.any((values) => values.isNotEmpty);
  }
}

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
      extraGroups: _readExtraOptionGroups(json['extraGroups']),
      hiddenBuiltInKeys: readValues('hiddenBuiltInKeys', const []),
    );
  }
}

const _unset = Object();

const defaultOotdFilterState = OotdFilterState();
const defaultOotdOptionConfig = OotdOptionConfig();

final defaultMockOotdItems = <MockOotdItem>[
  MockOotdItem(
    id: 'look-01',
    images: [
      MockOotdImage.asset(
        id: 'look-01-main',
        assetPath: 'assets/mock/ootd/look_01.jpg',
      ),
      MockOotdImage.solid(id: 'look-01-sub-01', colorValue: 0xFFE8EEF8),
    ],
    dateLabel: '2026-04-05',
    preference: '喜欢',
    season: '春',
    scene: '工作',
    tone: '冷色',
    rating: '5星',
  ),
  MockOotdItem(
    id: 'look-02',
    images: [
      MockOotdImage.asset(
        id: 'look-02-main',
        assetPath: 'assets/mock/ootd/look_02.jpg',
      ),
      MockOotdImage.solid(id: 'look-02-sub-01', colorValue: 0xFFF5E4D6),
      MockOotdImage.solid(id: 'look-02-sub-02', colorValue: 0xFFE8D5CA),
    ],
    dateLabel: '2026-04-03',
    preference: '不喜欢',
    season: '夏',
    scene: '休息',
    tone: '暖色',
    rating: '3星',
  ),
  MockOotdItem(
    id: 'look-03',
    images: [
      MockOotdImage.asset(
        id: 'look-03-main',
        assetPath: 'assets/mock/ootd/look_03.jpg',
      ),
    ],
    dateLabel: '2026-04-01',
    preference: '喜欢',
    season: '秋',
    scene: '工作',
    tone: '黑白',
    rating: '4星',
  ),
  MockOotdItem(
    id: 'look-04',
    images: [
      MockOotdImage.asset(
        id: 'look-04-main',
        assetPath: 'assets/mock/ootd/look_04.jpg',
      ),
      MockOotdImage.solid(id: 'look-04-sub-01', colorValue: 0xFFD5E6FA),
    ],
    dateLabel: '2026-03-30',
    preference: '不喜欢',
    season: '冬',
    scene: '休息',
    tone: '冷色',
    rating: '2星',
  ),
  MockOotdItem(
    id: 'look-05',
    images: [
      MockOotdImage.asset(
        id: 'look-05-main',
        assetPath: 'assets/mock/ootd/look_05.jpg',
      ),
      MockOotdImage.solid(id: 'look-05-sub-01', colorValue: 0xFFF4E0C8),
      MockOotdImage.solid(id: 'look-05-sub-02', colorValue: 0xFFEAD0B5),
    ],
    dateLabel: '2026-03-28',
    preference: '喜欢',
    season: '春',
    scene: '工作',
    tone: '暖色',
    rating: '4星',
  ),
  MockOotdItem(
    id: 'look-06',
    images: [
      MockOotdImage.asset(
        id: 'look-06-main',
        assetPath: 'assets/mock/ootd/look_06.jpg',
      ),
    ],
    dateLabel: '2026-03-26',
    preference: '喜欢',
    season: '夏',
    scene: '休息',
    tone: '黑白',
    rating: '5星',
  ),
  MockOotdItem(
    id: 'look-07',
    images: [
      MockOotdImage.asset(
        id: 'look-07-main',
        assetPath: 'assets/mock/ootd/look_07.jpg',
      ),
      MockOotdImage.solid(id: 'look-07-sub-01', colorValue: 0xFFDDE8F5),
    ],
    dateLabel: '2026-03-24',
    preference: '不喜欢',
    season: '秋',
    scene: '工作',
    tone: '冷色',
    rating: '1星',
  ),
  MockOotdItem(
    id: 'look-08',
    images: [
      MockOotdImage.asset(
        id: 'look-08-main',
        assetPath: 'assets/mock/ootd/look_08.jpg',
      ),
      MockOotdImage.solid(id: 'look-08-sub-01', colorValue: 0xFFF7DFC9),
      MockOotdImage.solid(id: 'look-08-sub-02', colorValue: 0xFFEED0AA),
    ],
    dateLabel: '2026-03-22',
    preference: '喜欢',
    season: '冬',
    scene: '休息',
    tone: '暖色',
    rating: '3星',
  ),
  MockOotdItem(
    id: 'look-09',
    images: [
      MockOotdImage.asset(
        id: 'look-09-main',
        assetPath: 'assets/mock/ootd/look_09.jpg',
      ),
      MockOotdImage.solid(id: 'look-09-sub-01', colorValue: 0xFFE4E6EB),
    ],
    dateLabel: '2026-03-20',
    preference: '喜欢',
    season: '春',
    scene: '休息',
    tone: '黑白',
    rating: '4星',
  ),
];

final ootdLocalStoreProvider = Provider<OotdLocalStore>(
  (ref) => const OotdLocalStore(),
);

final ootdStorageRootProvider = Provider<String>((ref) => '');

final initialOotdItemsProvider = Provider<List<MockOotdItem>>(
  (ref) => defaultMockOotdItems,
);

final initialOotdFiltersProvider = Provider<OotdFilterState>(
  (ref) => defaultOotdFilterState,
);

final initialOotdOptionConfigProvider = Provider<OotdOptionConfig>(
  (ref) => defaultOotdOptionConfig,
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
      ref
          .read(ootdLocalStoreProvider)
          .saveItemsJson(
            state.map((item) => item.toJson()).toList(growable: false),
          ),
    );
  }

  String _nextItemId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final randomPart = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'look-$now-$randomPart';
  }
}

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
    unawaited(ref.read(ootdLocalStoreProvider).saveFiltersJson(state.toJson()));
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
    unawaited(ref.read(ootdLocalStoreProvider).saveOptionsJson(state.toJson()));
  }
}

final ootdItemsProvider =
    NotifierProvider<OotdItemsNotifier, List<MockOotdItem>>(
      OotdItemsNotifier.new,
    );

final ootdFiltersProvider =
    NotifierProvider<OotdFiltersNotifier, OotdFilterState>(
      OotdFiltersNotifier.new,
    );

final ootdOptionConfigProvider =
    NotifierProvider<OotdOptionConfigNotifier, OotdOptionConfig>(
      OotdOptionConfigNotifier.new,
    );

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

final ootdByIdProvider = Provider.family<MockOotdItem?, String>((ref, id) {
  final items = ref.watch(ootdItemsProvider);

  for (final item in items) {
    if (item.id == id) {
      return item;
    }
  }

  return null;
});

List<MockOotdItem> normalizeItemsForOptions(
  List<MockOotdItem> items,
  OotdOptionConfig config,
) {
  return items
      .map((item) => item.normalizedForConfig(config))
      .toList(growable: false);
}

List<MockOotdItem> normalizeItemsForStorageRoot(
  List<MockOotdItem> items,
  String dataDirectoryPath,
) {
  return items
      .map((item) => normalizeItemForStorageRoot(item, dataDirectoryPath))
      .toList(growable: false);
}

MockOotdItem normalizeItemForStorageRoot(
  MockOotdItem item,
  String dataDirectoryPath,
) {
  return item.copyWith(
    images: [
      for (final image in item.images)
        normalizeImageForStorageRoot(image, dataDirectoryPath),
    ],
  );
}

MockOotdImage normalizeImageForStorageRoot(
  MockOotdImage image,
  String dataDirectoryPath,
) {
  if (image.sourceType != OotdImageSourceType.file || image.path == null) {
    return image;
  }

  final normalizedPath = normalizeManagedImagePath(
    image.path!,
    dataDirectoryPath: dataDirectoryPath,
  );
  if (normalizedPath == image.path) {
    return image;
  }

  return MockOotdImage.file(id: image.id, filePath: normalizedPath);
}

String formatDateLabel(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _readDateLabel(dynamic value) {
  if (value is String && value.contains('-')) {
    return value;
  }

  if (value is String && value.contains('/')) {
    final parts = value.split('/');
    if (parts.length == 2) {
      final year = DateTime.now().year;
      final month = parts[0].padLeft(2, '0');
      final day = parts[1].padLeft(2, '0');
      return '$year-$month-$day';
    }
  }

  return formatDateLabel(DateTime.now());
}

Map<String, String> _readExtraSelections(dynamic value) {
  if (value is! Map) {
    return const {};
  }

  return Map<String, String>.fromEntries(
    value.entries
        .where((entry) => entry.key is String && entry.value is String)
        .map(
          (entry) => MapEntry(
            (entry.key as String).trim(),
            (entry.value as String).trim(),
          ),
        )
        .where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty),
  );
}

Map<String, List<String>> _readExtraFilterSelections(dynamic value) {
  if (value is! Map) {
    return const {};
  }

  return Map<String, List<String>>.fromEntries(
    value.entries.where((entry) => entry.key is String && entry.value is List).map(
      (entry) {
        final values = (entry.value as List)
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        return MapEntry((entry.key as String).trim(), values);
      },
    ).where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty),
  );
}

List<OotdExtraOptionGroup> _readExtraOptionGroups(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((group) => OotdExtraOptionGroup.fromJson(Map<String, dynamic>.from(group)))
      .where((group) => group.key.trim().isNotEmpty && group.values.isNotEmpty)
      .toList(growable: false);
}

String _readLegacyPreference(dynamic value) {
  return switch (value) {
    'liked' => '喜欢',
    'disliked' => '不喜欢',
    String text when text.trim().isNotEmpty => text.trim(),
    _ => '喜欢',
  };
}

String _readLegacySeason(dynamic value) {
  return switch (value) {
    'spring' => '春',
    'summer' => '夏',
    'autumn' => '秋',
    'winter' => '冬',
    String text when text.trim().isNotEmpty => text.trim(),
    _ => '春',
  };
}

String _readLegacyScene(dynamic value) {
  return switch (value) {
    'weekday' => '工作日',
    'weekend' => '休息日',
    '工作日' => '工作',
    '休息日' => '休息',
    String text when text.trim().isNotEmpty => text.trim(),
    _ => '工作',
  };
}

String _readLegacyTone(dynamic value) {
  return switch (value) {
    'monochrome' => '黑白色调',
    'cool' => '冷色调',
    'warm' => '暖色调',
    '黑白色调' => '黑白',
    '冷色调' => '冷色',
    '暖色调' => '暖色',
    String text when text.trim().isNotEmpty => text.trim(),
    _ => '冷色',
  };
}

String _readLegacyRating(dynamic value) {
  return switch (value) {
    int number => '$number星',
    String text when text.trim().isNotEmpty => text.trim(),
    _ => '3星',
  };
}
