import 'ootd_json_helpers.dart';

const _unset = Object();

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
        readLegacyPreference,
      ),
      seasons: readValues('seasons', 'season', readLegacySeason),
      scenes: readValues('scenes', 'scene', readLegacyScene),
      tones: readValues('tones', 'tone', readLegacyTone),
      ratings: readValues('ratings', 'rating', readLegacyRating),
      extraSelections: readExtraFilterSelections(json['extraSelections']),
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
