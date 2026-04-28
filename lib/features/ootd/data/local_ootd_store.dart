import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const ootdManagedImagesDirectoryName = 'images';
const ootdDataDirectoryName = 'daily_ootd';

String normalizeManagedImagePath(String rawPath, {required String dataDirectoryPath}) {
  if (rawPath.trim().isEmpty) {
    return rawPath;
  }

  final normalizedPath = p.normalize(rawPath);
  final normalizedRoot = p.normalize(dataDirectoryPath);
  if (p.isAbsolute(normalizedPath) && p.isWithin(normalizedRoot, normalizedPath)) {
    return p.relative(normalizedPath, from: normalizedRoot).replaceAll('\\', '/');
  }

  return rawPath.replaceAll('\\', '/');
}

String resolveManagedImagePath(String storedPath, {required String dataDirectoryPath}) {
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
  const OotdLocalStore();

  Future<List<Map<String, dynamic>>?> loadItemsJson() async {
    try {
      final file = await _itemsFile();
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(content);
      if (decoded is! List) {
        return null;
      }

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveItemsJson(List<Map<String, dynamic>> items) async {
    final file = await _itemsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(items));
  }

  Future<Map<String, dynamic>?> loadFiltersJson() async {
    try {
      final file = await _filtersFile();
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

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFiltersJson(Map<String, dynamic> filters) async {
    final file = await _filtersFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(filters));
  }

  Future<Map<String, dynamic>?> loadOptionsJson() async {
    try {
      final file = await _optionsFile();
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

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOptionsJson(Map<String, dynamic> options) async {
    final file = await _optionsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(options));
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
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'lastExportZipPath': path}));
  }

  Future<String> savePickedImage(XFile pickedFile) async {
    final imagesDir = await _imagesDirectory();
    return _copyPickedImage(pickedFile, imagesDir, filePrefix: 'ootd_');
  }

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
