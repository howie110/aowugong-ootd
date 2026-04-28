import 'ootd_json_helpers.dart';
import 'ootd_option_config.dart';

export 'ootd_json_helpers.dart' show OotdExtraOptionGroup;

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
      dateLabel: readDateLabel(json['dateLabel']),
      preference: readLegacyPreference(json['preference']),
      season: readLegacySeason(json['season']),
      scene: readLegacyScene(json['scene']),
      tone: readLegacyTone(json['tone']),
      rating: readLegacyRating(json['rating']),
      extraSelections: readExtraSelections(json['extraSelections']),
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
