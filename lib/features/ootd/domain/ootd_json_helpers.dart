String formatDateLabel(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String readDateLabel(dynamic value) {
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

Map<String, String> readExtraSelections(dynamic value) {
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

Map<String, List<String>> readExtraFilterSelections(dynamic value) {
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

List<OotdExtraOptionGroup> readExtraOptionGroups(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((group) => OotdExtraOptionGroup.fromJson(Map<String, dynamic>.from(group)))
      .where((group) => group.key.trim().isNotEmpty && group.values.isNotEmpty)
      .toList(growable: false);
}

String readLegacyPreference(dynamic value) {
  return switch (value) {
    'liked' => '喜欢',
    'disliked' => '不喜欢',
    String text when text.trim().isNotEmpty => text.trim(),
    _ => '喜欢',
  };
}

String readLegacySeason(dynamic value) {
  return switch (value) {
    'spring' => '春',
    'summer' => '夏',
    'autumn' => '秋',
    'winter' => '冬',
    String text when text.trim().isNotEmpty => text.trim(),
    _ => '春',
  };
}

String readLegacyScene(dynamic value) {
  return switch (value) {
    'weekday' => '工作日',
    'weekend' => '休息日',
    '工作日' => '工作',
    '休息日' => '休息',
    String text when text.trim().isNotEmpty => text.trim(),
    _ => '工作',
  };
}

String readLegacyTone(dynamic value) {
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

String readLegacyRating(dynamic value) {
  return switch (value) {
    int number => '$number星',
    String text when text.trim().isNotEmpty => text.trim(),
    _ => '3星',
  };
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
