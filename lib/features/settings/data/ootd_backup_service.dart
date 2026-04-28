import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../../app/app_metadata.dart';
import '../../ootd/data/local_ootd_store.dart';
import '../../ootd/presentation/home/mock_ootd_items.dart';

const ootdBackupFormatVersion = 1;

enum OotdBackupKind { export, rollback }

class OotdBackupException implements Exception {
  const OotdBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OotdBackupPreview {
  const OotdBackupPreview({
    required this.zipPath,
    required this.fileName,
    required this.directoryPath,
    required this.itemCount,
    required this.ootdImageCount,
    required this.imageCount,
    required this.exportedAt,
    required this.appVersion,
    required this.backupFormatVersion,
  });

  final String zipPath;
  final String fileName;
  final String directoryPath;
  final int itemCount;
  final int ootdImageCount;
  final int imageCount;
  final String exportedAt;
  final String appVersion;
  final int backupFormatVersion;

  OotdBackupPreview copyWith({
    String? zipPath,
    String? fileName,
    String? directoryPath,
    int? itemCount,
    int? ootdImageCount,
    int? imageCount,
    String? exportedAt,
    String? appVersion,
    int? backupFormatVersion,
  }) {
    return OotdBackupPreview(
      zipPath: zipPath ?? this.zipPath,
      fileName: fileName ?? this.fileName,
      directoryPath: directoryPath ?? this.directoryPath,
      itemCount: itemCount ?? this.itemCount,
      ootdImageCount: ootdImageCount ?? this.ootdImageCount,
      imageCount: imageCount ?? this.imageCount,
      exportedAt: exportedAt ?? this.exportedAt,
      appVersion: appVersion ?? this.appVersion,
      backupFormatVersion: backupFormatVersion ?? this.backupFormatVersion,
    );
  }
}

class OotdImportedSnapshot {
  const OotdImportedSnapshot({
    required this.preview,
    required this.items,
    required this.filters,
    required this.options,
  });

  final OotdBackupPreview preview;
  final List<MockOotdItem> items;
  final OotdFilterState filters;
  final OotdOptionConfig options;
}

class _PreparedExportPayload {
  const _PreparedExportPayload({
    required this.items,
    required this.filters,
    required this.options,
    required this.imageFiles,
  });

  final List<MockOotdItem> items;
  final OotdFilterState filters;
  final OotdOptionConfig options;
  final Map<String, File> imageFiles;
}

class _ParsedBackup {
  const _ParsedBackup({
    required this.preview,
    required this.items,
    required this.filters,
    required this.options,
    required this.imageContents,
  });

  final OotdBackupPreview preview;
  final List<MockOotdItem> items;
  final OotdFilterState filters;
  final OotdOptionConfig options;
  final Map<String, Uint8List> imageContents;
}

class OotdBackupService {
  const OotdBackupService({this.store = const OotdLocalStore()});

  final OotdLocalStore store;

  Future<OotdBackupPreview> exportBackup({
    required List<MockOotdItem> items,
    required OotdFilterState filters,
    required OotdOptionConfig options,
    String filePrefix = 'ootd_backup',
    OotdBackupKind backupKind = OotdBackupKind.export,
  }) async {
    final prepared = await _prepareExportPayload(
      items: items,
      filters: filters,
      options: options,
    );
    final exportedAt = DateTime.now().toIso8601String();
    final fileName = '${filePrefix}_${_timestampLabel(DateTime.now())}.zip';
    final directory = await _backupDirectory(backupKind);
    await directory.create(recursive: true);
    await _clearExistingZipFiles(directory);
    final zipPath = p.join(directory.path, fileName);

    final manifest = {
      'backupFormatVersion': ootdBackupFormatVersion,
      'appVersion': appFullVersion,
      'exportedAt': exportedAt,
      'items': prepared.items.map((item) => item.toJson()).toList(growable: false),
      'filters': prepared.filters.toJson(),
      'options': prepared.options.toJson(),
      'images': prepared.imageFiles.keys.toList(growable: false),
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));

    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'manifest.json',
          manifestBytes.length,
          manifestBytes,
        ),
      );

    for (final entry in prepared.imageFiles.entries) {
      final bytes = await entry.value.readAsBytes();
      archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw const OotdBackupException('生成 zip 备份文件失败');
    }

    await File(zipPath).writeAsBytes(encoded, flush: true);
    return OotdBackupPreview(
      zipPath: zipPath,
      fileName: fileName,
      directoryPath: directory.path,
      itemCount: prepared.items.length,
      ootdImageCount: _countOotdImages(prepared.items),
      imageCount: prepared.imageFiles.length,
      exportedAt: exportedAt,
      appVersion: appFullVersion,
      backupFormatVersion: ootdBackupFormatVersion,
    );
  }

  Future<OotdBackupPreview?> loadLatestExportPreview() async {
    final rememberedPath = await store.loadLastExportZipPath();
    if (rememberedPath != null && await File(rememberedPath).exists()) {
      try {
        return await readBackupPreview(rememberedPath);
      } catch (_) {
        // Preview load failure is non-critical; return null to show no preview.
      }
    }

    return null;
  }

  Future<OotdBackupPreview> readBackupPreview(String zipPath) async {
    final parsed = await _parseBackup(zipPath, includeImageContents: false);
    return parsed.preview;
  }

  Future<OotdImportedSnapshot> importBackup({
    required String zipPath,
    required List<MockOotdItem> currentItems,
    required OotdFilterState currentFilters,
    required OotdOptionConfig currentOptions,
  }) async {
    final rollbackBackup = await exportBackup(
      items: currentItems,
      filters: currentFilters,
      options: currentOptions,
      filePrefix: 'rollback_backup',
      backupKind: OotdBackupKind.rollback,
    );

    try {
      final parsed = await _parseBackup(zipPath, includeImageContents: true);
      return await _applyParsedBackup(parsed);
    } catch (error) {
      var rollbackFailed = false;
      try {
        final rollbackParsed = await _parseBackup(
          rollbackBackup.zipPath,
          includeImageContents: true,
        );
        await _applyParsedBackup(rollbackParsed);
      } catch (_) {
        rollbackFailed = true;
      }

      if (error is OotdBackupException) {
        if (rollbackFailed) {
          throw OotdBackupException('${error.message}（自动回滚也失败了，数据可能不完整）');
        }
        rethrow;
      }
      final suffix = rollbackFailed ? '（自动回滚也失败了，数据可能不完整）' : '';
      throw OotdBackupException('导入失败，请重试$suffix');
    }
  }

  Future<_PreparedExportPayload> _prepareExportPayload({
    required List<MockOotdItem> items,
    required OotdFilterState filters,
    required OotdOptionConfig options,
  }) async {
    final dataDirectoryPath = await store.dataDirectoryPath();
    final usedImageFiles = <String, File>{};
    final preparedItems = <MockOotdItem>[];

    for (final item in items) {
      final nextImages = <MockOotdImage>[];
      for (final image in item.images) {
        if (image.sourceType != OotdImageSourceType.file || image.path == null) {
          nextImages.add(image);
          continue;
        }

        final resolvedPath = resolveManagedImagePath(
          image.path!,
          dataDirectoryPath: dataDirectoryPath,
        );
        final file = File(resolvedPath);
        if (!await file.exists()) {
          throw OotdBackupException('存在缺失图片，无法备份：${image.path}');
        }

        var relativePath = normalizeManagedImagePath(
          image.path!,
          dataDirectoryPath: dataDirectoryPath,
        );
        if (p.isAbsolute(relativePath) || relativePath.startsWith('../')) {
          relativePath = p.posix.join(
            ootdManagedImagesDirectoryName,
            p.basename(resolvedPath),
          );
        } else {
          relativePath = relativePath.replaceAll('\\', '/');
        }

        if (usedImageFiles.containsKey(relativePath) &&
            p.normalize(usedImageFiles[relativePath]!.path) !=
                p.normalize(file.path)) {
          relativePath = _dedupeRelativePath(relativePath, usedImageFiles.keys);
        }

        usedImageFiles[relativePath] = file;
        nextImages.add(
          MockOotdImage.file(
            id: image.id,
            filePath: relativePath,
          ),
        );
      }

      preparedItems.add(item.copyWith(images: List.unmodifiable(nextImages)));
    }

    return _PreparedExportPayload(
      items: List.unmodifiable(preparedItems),
      filters: filters,
      options: options,
      imageFiles: Map<String, File>.unmodifiable(usedImageFiles),
    );
  }

  Future<_ParsedBackup> _parseBackup(
    String zipPath, {
    required bool includeImageContents,
  }) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      throw const OotdBackupException('没有找到选择的 zip 备份文件');
    }

    const maxZipSize = 500 * 1024 * 1024; // 500 MB
    final fileSize = await zipFile.length();
    if (fileSize > maxZipSize) {
      throw const OotdBackupException('备份文件过大，请检查文件是否正确');
    }

    final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
    final manifestFile = _findArchiveFile(archive, 'manifest.json');
    if (manifestFile == null) {
      throw const OotdBackupException('zip 里缺少 manifest.json');
    }

    final manifestContent = manifestFile.content;
    final manifestText = switch (manifestContent) {
      List<int> bytes => utf8.decode(bytes),
      String text => text,
      _ => throw const OotdBackupException('manifest.json 无法读取'),
    };
    final manifestJson = jsonDecode(manifestText);
    if (manifestJson is! Map) {
      throw const OotdBackupException('manifest.json 格式不正确');
    }

    final manifest = Map<String, dynamic>.from(manifestJson);
    final formatVersion = manifest['backupFormatVersion'];
    if (formatVersion is! int) {
      throw const OotdBackupException('备份格式版本缺失');
    }
    if (formatVersion != ootdBackupFormatVersion) {
      throw OotdBackupException('暂不支持导入该备份格式版本：$formatVersion');
    }

    final itemsJson = manifest['items'];
    final filtersJson = manifest['filters'];
    final optionsJson = manifest['options'];
    if (itemsJson is! List || filtersJson is! Map || optionsJson is! Map) {
      throw const OotdBackupException('备份文件内容不完整');
    }

    final items = itemsJson
        .map((item) => MockOotdItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final filters = OotdFilterState.fromJson(Map<String, dynamic>.from(filtersJson));
    final options = OotdOptionConfig.fromJson(Map<String, dynamic>.from(optionsJson));
    final manifestImages = _readManifestImagePaths(manifest['images']);
    final referencedImages = _collectReferencedImagePaths(items);

    for (final imagePath in referencedImages) {
      if (!manifestImages.contains(imagePath)) {
        throw OotdBackupException('manifest.json 缺少图片记录：$imagePath');
      }
    }

    final imageContents = <String, Uint8List>{};
    if (includeImageContents) {
      for (final imagePath in referencedImages) {
        final archiveFile = _findArchiveFile(archive, imagePath);
        if (archiveFile == null) {
          throw OotdBackupException('zip 内缺少图片文件：$imagePath');
        }

        final content = archiveFile.content;
        final bytes = switch (content) {
          Uint8List typedBytes => typedBytes,
          List<int> listBytes => Uint8List.fromList(listBytes),
          _ => throw OotdBackupException('图片文件无法读取：$imagePath'),
        };
        imageContents[imagePath] = bytes;
      }
    }

    return _ParsedBackup(
      preview: OotdBackupPreview(
        zipPath: zipPath,
        fileName: p.basename(zipPath),
        directoryPath: p.dirname(zipPath),
        itemCount: items.length,
        ootdImageCount: _countOotdImages(items),
        imageCount: manifestImages.length,
        exportedAt: manifest['exportedAt'] as String? ?? '',
        appVersion: manifest['appVersion'] as String? ?? '',
        backupFormatVersion: formatVersion,
      ),
      items: items,
      filters: filters,
      options: options,
      imageContents: imageContents,
    );
  }

  Future<OotdImportedSnapshot> _applyParsedBackup(_ParsedBackup parsed) async {
    final dataDirectoryPath = await store.dataDirectoryPath();
    final normalizedItems = normalizeItemsForOptions(
      normalizeItemsForStorageRoot(parsed.items, dataDirectoryPath),
      parsed.options,
    );
    final imagesDirectory = Directory(
      p.join(dataDirectoryPath, ootdManagedImagesDirectoryName),
    );

    if (await imagesDirectory.exists()) {
      await imagesDirectory.delete(recursive: true);
    }
    await imagesDirectory.create(recursive: true);

    for (final entry in parsed.imageContents.entries) {
      final sanitizedKey = entry.key.replaceAll('/', Platform.pathSeparator);
      final resolvedPath = p.normalize(p.join(dataDirectoryPath, sanitizedKey));
      final normalizedRoot = p.normalize(dataDirectoryPath);
      if (!resolvedPath.startsWith(normalizedRoot + Platform.pathSeparator) &&
          resolvedPath != normalizedRoot) {
        throw const OotdBackupException('备份文件包含非法路径，已中止导入');
      }

      final targetFile = File(resolvedPath);
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(entry.value, flush: true);
    }

    await store.saveItemsJson(
      normalizedItems.map((item) => item.toJson()).toList(growable: false),
    );
    await store.saveFiltersJson(parsed.filters.toJson());
    await store.saveOptionsJson(parsed.options.toJson());

    return OotdImportedSnapshot(
      preview: parsed.preview,
      items: normalizedItems,
      filters: parsed.filters,
      options: parsed.options,
    );
  }

  Future<Directory> _backupDirectory(OotdBackupKind backupKind) async {
    return switch (backupKind) {
      OotdBackupKind.export => store.exportBackupDirectory(),
      OotdBackupKind.rollback => store.rollbackBackupDirectory(),
    };
  }

  Future<void> rememberLastExportZipPath(String path) {
    return store.saveLastExportZipPath(path);
  }

  String _timestampLabel(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$year-$month-${day}_$hour-$minute-$second';
  }

  Set<String> _collectReferencedImagePaths(List<MockOotdItem> items) {
    return {
      for (final item in items)
        for (final image in item.images)
          if (image.sourceType == OotdImageSourceType.file &&
              image.path != null &&
              image.path!.trim().isNotEmpty)
            image.path!.replaceAll('\\', '/'),
    };
  }

  Set<String> _readManifestImagePaths(dynamic value) {
    if (value is! List) {
      return const {};
    }

    return value
        .whereType<String>()
        .map((item) => item.replaceAll('\\', '/'))
        .toSet();
  }

  String _dedupeRelativePath(String originalPath, Iterable<String> usedPaths) {
    final extension = p.extension(originalPath);
    final baseName = extension.isEmpty
        ? originalPath
        : originalPath.substring(0, originalPath.length - extension.length);
    var index = 2;
    var candidate = '${baseName}_$index$extension';
    while (usedPaths.contains(candidate)) {
      index++;
      candidate = '${baseName}_$index$extension';
    }
    return candidate;
  }

  int _countOotdImages(List<MockOotdItem> items) {
    return items.fold(0, (sum, item) => sum + item.images.length);
  }

  Future<void> _clearExistingZipFiles(Directory directory) async {
    if (!await directory.exists()) {
      return;
    }

    final entries = await directory.list().toList();
    for (final entry in entries) {
      if (entry is File && p.extension(entry.path).toLowerCase() == '.zip') {
        await entry.delete();
      }
    }
  }

  ArchiveFile? _findArchiveFile(Archive archive, String name) {
    for (final file in archive.files) {
      if (file.name == name) {
        return file;
      }
    }

    return null;
  }
}
