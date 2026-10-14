import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const ootdManagedImagesDirectoryName = 'images';
const ootdDataDirectoryName = 'daily_ootd';

String normalizeManagedImagePath(
  String rawPath, {
  required String dataDirectoryPath,
}) {
  if (rawPath.trim().isEmpty) {
    return rawPath;
  }

  final normalizedPath = p.normalize(rawPath);
  final normalizedRoot = p.normalize(dataDirectoryPath);
  if (p.isAbsolute(normalizedPath) &&
      p.isWithin(normalizedRoot, normalizedPath)) {
    return p
        .relative(normalizedPath, from: normalizedRoot)
        .replaceAll('\\', '/');
  }

  return rawPath.replaceAll('\\', '/');
}

String resolveManagedImagePath(
  String storedPath, {
  required String dataDirectoryPath,
}) {
  if (storedPath.trim().isEmpty) {
    return storedPath;
  }

  final normalizedPath = storedPath.replaceAll('\\', '/');
  if (p.isAbsolute(normalizedPath)) {
    return p.normalize(normalizedPath);
  }

  return p.normalize(p.join(dataDirectoryPath, normalizedPath));
}

class OotdLocalStore {
  const OotdLocalStore({this.dataDirectoryOverride});

  final String? dataDirectoryOverride;
  static final Map<String, Future<void>> _pending = {};

  Future<T> _serialized<T>(Future<T> Function() action) async {
    final root = await dataDirectoryPath();
    final previous = _pending[root] ?? Future<void>.value();
    final result = previous.then((_) async {
      await _recoverSnapshot(root);
      return action();
    });
    final settled = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[root] = settled;
    try {
      return await result;
    } finally {
      if (identical(_pending[root], settled)) _pending.remove(root);
    }
  }

  Future<void> flushPendingWrites() async {
    final root = await dataDirectoryPath();
    while (_pending.containsKey(root)) {
      await _pending[root];
    }
  }

  Future<void> _recoverFile(File file) async {
    final previous = File('${file.path}.previous');
    if (!await file.exists() && await previous.exists()) {
      await previous.rename(file.path);
    }
  }

  Future<void> _writeAtomic(File file, String content) async {
    await file.parent.create(recursive: true);
    await _recoverFile(file);
    final temporary = File('${file.path}.tmp');
    final previous = File('${file.path}.previous');
    await temporary.writeAsString(content, flush: true);
    if (await previous.exists()) await previous.delete();
    if (await file.exists()) await file.rename(previous.path);
    try {
      await temporary.rename(file.path);
    } catch (_) {
      await _recoverFile(file);
      rethrow;
    }
    // A leftover previous copy is harmless and is replaced on the next write.
  }

  Future<Object?> _readJson(File file) async {
    await _recoverFile(file);
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString());
  }

  Future<List<Map<String, dynamic>>?> loadItemsJson() => _serialized(() async {
    final decoded = await _readJson(await _itemsFile());
    if (decoded == null) {
      if (await (await _itemsFile()).exists()) {
        throw const FormatException('Invalid items');
      }
      return null;
    }
    if (decoded is! List || decoded.any((value) => value is! Map)) {
      throw const FormatException('Invalid items');
    }
    return decoded
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
  });

  Future<Map<String, dynamic>?> _loadMap(File file) async {
    final decoded = await _readJson(file);
    if (decoded == null && !await file.exists()) return null;
    if (decoded is! Map) {
      throw FormatException('Invalid ${p.basename(file.path)}');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<Map<String, dynamic>?> loadFiltersJson() =>
      _serialized(() async => _loadMap(await _filtersFile()));
  Future<Map<String, dynamic>?> loadOptionsJson() =>
      _serialized(() async => _loadMap(await _optionsFile()));

  Future<void> saveItemsJson(List<Map<String, dynamic>> items) {
    final content = jsonEncode(items);
    return _serialized(() async => _writeAtomic(await _itemsFile(), content));
  }

  Future<void> saveFiltersJson(Map<String, dynamic> filters) {
    final content = jsonEncode(filters);
    return _serialized(() async => _writeAtomic(await _filtersFile(), content));
  }

  Future<void> saveOptionsJson(Map<String, dynamic> options) {
    final content = jsonEncode(options);
    return _serialized(() async => _writeAtomic(await _optionsFile(), content));
  }

  static const _snapshotNames = [
    'ootd_items.json',
    'ootd_filters.json',
    'ootd_options.json',
  ];

  Future<void> _recoverSnapshot(String root) async {
    final journal = File(p.join(root, 'snapshot-recovery.json'));
    if (!await journal.exists()) return;
    final old =
        jsonDecode(await journal.readAsString()) as Map<String, dynamic>;
    for (final name in _snapshotNames) {
      if (!old.containsKey(name) ||
          (old[name] != null && old[name] is! String)) {
        throw const FormatException('Invalid recovery snapshot');
      }
    }
    for (final name in _snapshotNames) {
      final file = File(p.join(root, name));
      if (old[name] == null) {
        if (await file.exists()) await file.delete();
        final previous = File('${file.path}.previous');
        if (await previous.exists()) await previous.delete();
      } else {
        if (!await file.exists() || await file.readAsString() != old[name]) {
          await _writeAtomic(file, old[name] as String);
        }
      }
    }
    await journal.delete();
  }

  Future<void> saveSnapshot({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> filters,
    required Map<String, dynamic> options,
  }) {
    final values = [
      jsonEncode(items),
      jsonEncode(filters),
      jsonEncode(options),
    ];
    return _serialized(() async {
      final root = await dataDirectoryPath();
      final old = <String, String?>{};
      for (final name in _snapshotNames) {
        final file = File(p.join(root, name));
        await _recoverFile(file);
        old[name] = await file.exists() ? await file.readAsString() : null;
      }
      final journal = File(p.join(root, 'snapshot-recovery.json'));
      await _writeAtomic(journal, jsonEncode(old));
      try {
        for (var i = 0; i < _snapshotNames.length; i++) {
          await _writeAtomic(File(p.join(root, _snapshotNames[i])), values[i]);
        }
        await journal.delete();
      } catch (_) {
        await _recoverSnapshot(root);
        rethrow;
      }
    });
  }

  Future<String?> loadLastExportZipPath() async {
    final file = await _backupMetaFile();
    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      return null;
    }

    final path = decoded['lastExportZipPath'];
    return path is String && path.trim().isNotEmpty ? path : null;
  }

  Future<void> saveLastExportZipPath(String path) async {
    final file = await _backupMetaFile();
    await _serialized(
      () => _writeAtomic(file, jsonEncode({'lastExportZipPath': path})),
    );
  }

  Future<String> savePickedImage(XFile pickedFile) async {
    final imagesDir = Directory(p.join(await dataDirectoryPath(), 'drafts'));
    return _copyPickedImage(pickedFile, imagesDir, filePrefix: 'ootd_');
  }

  Future<String> promoteDraftImage(String storedPath) async {
    final root = await dataDirectoryPath();
    final source = resolveManagedImagePath(storedPath, dataDirectoryPath: root);
    if (!p.isWithin(p.join(root, 'drafts'), source)) return storedPath;
    final images = await _imagesDirectory();
    await images.create(recursive: true);
    final target = p.join(images.path, p.basename(source));
    // Keep the draft until the JSON commit succeeds, so a failed save is retryable.
    await File(source).copy(target);
    return normalizeManagedImagePath(target, dataDirectoryPath: root);
  }

  Future<void> removeUnreferencedImages(
    Set<String> referencedPaths, {
    required Set<String> protectedDraftPaths,
  }) => _serialized(() async {
    final root = await dataDirectoryPath();
    final keep = {...referencedPaths, ...protectedDraftPaths};
    final saved = await _readJson(await _itemsFile());
    if (saved is List) {
      for (final item in saved.whereType<Map>()) {
        final images = item['images'];
        if (images is List) {
          for (final image in images.whereType<Map>()) {
            if (image['path'] is String) keep.add(image['path'] as String);
          }
        }
      }
    }
    final resolvedKeep = keep
        .map((path) => resolveManagedImagePath(path, dataDirectoryPath: root))
        .toSet();
    for (final name in ['images', 'drafts']) {
      final directory = Directory(p.join(root, name));
      if (await FileSystemEntity.type(directory.path, followLinks: false) !=
          FileSystemEntityType.directory) {
        continue;
      }
      await for (final entry in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entry is File &&
            p.isWithin(directory.path, entry.path) &&
            !resolvedKeep.contains(p.normalize(entry.path))) {
          await entry.delete();
        }
      }
    }
  });

  Future<String> dataDirectoryPath() async {
    final directory = await _dataDirectory();
    return directory.path;
  }

  Future<Directory> exportBackupDirectory() async {
    if (Platform.isAndroid) {
      final externalDirectory = await getExternalStorageDirectory();
      if (externalDirectory != null) {
        return Directory(p.join(externalDirectory.path, 'backups', 'export'));
      }
    }

    final dataDirectory = await _dataDirectory();
    return Directory(p.join(dataDirectory.path, 'backup_exports'));
  }

  Future<Directory> rollbackBackupDirectory() async {
    final dataDirectory = await _dataDirectory();
    return Directory(p.join(dataDirectory.path, 'backup_rollbacks'));
  }

  Future<File> _itemsFile() async {
    final directory = await _dataDirectory();
    return File(p.join(directory.path, 'ootd_items.json'));
  }

  Future<File> _filtersFile() async {
    final directory = await _dataDirectory();
    return File(p.join(directory.path, 'ootd_filters.json'));
  }

  Future<File> _optionsFile() async {
    final directory = await _dataDirectory();
    return File(p.join(directory.path, 'ootd_options.json'));
  }

  Future<File> _backupMetaFile() async {
    final directory = await _dataDirectory();
    return File(p.join(directory.path, 'ootd_backup_meta.json'));
  }

  Future<Directory> _imagesDirectory() async {
    final directory = await _dataDirectory();
    return Directory(p.join(directory.path, ootdManagedImagesDirectoryName));
  }

  Future<Directory> _dataDirectory() async {
    if (dataDirectoryOverride != null) return Directory(dataDirectoryOverride!);
    final root = await getApplicationDocumentsDirectory();
    return Directory(p.join(root.path, ootdDataDirectoryName));
  }

  Future<String> _copyPickedImage(
    XFile pickedFile,
    Directory targetDirectory, {
    required String filePrefix,
  }) async {
    await targetDirectory.create(recursive: true);

    final extension = p.extension(pickedFile.path);
    final fileName =
        '$filePrefix${DateTime.now().microsecondsSinceEpoch}${extension.isEmpty ? '.jpg' : extension}';
    final targetPath = p.join(targetDirectory.path, fileName);

    await File(pickedFile.path).copy(targetPath);
    final dataDirectoryPath = await this.dataDirectoryPath();
    return normalizeManagedImagePath(
      targetPath,
      dataDirectoryPath: dataDirectoryPath,
    );
  }
}
