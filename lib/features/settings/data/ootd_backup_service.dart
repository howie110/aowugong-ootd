import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:io' as io;

import 'package:archive/archive_io.dart';
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
  final Map<String, String> imageContents;
}

class OotdBackupService {
  const OotdBackupService({
    this.store = const OotdLocalStore(),
    this.importCheckpoint,
  });

  final void Function(String phase)? importCheckpoint;

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
    final fileName =
        '${filePrefix}_${_timestampLabel(DateTime.now())}_${DateTime.now().microsecondsSinceEpoch}.zip';
    final directory = await _backupDirectory(backupKind);
    await directory.create(recursive: true);
    final zipPath = p.join(directory.path, fileName);

    final manifest = {
      'backupFormatVersion': ootdBackupFormatVersion,
      'appVersion': appFullVersion,
      'exportedAt': exportedAt,
      'items': prepared.items
          .map((item) => item.toJson())
          .toList(growable: false),
      'filters': prepared.filters.toJson(),
      'options': prepared.options.toJson(),
      'images': prepared.imageFiles.keys.toList(growable: false),
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));

    final files = prepared.imageFiles.map(
      (key, file) => MapEntry(key, file.path),
    );
    try {
      await Isolate.run(() async {
        final temporary = '$zipPath.tmp';
        final encoder = ZipFileEncoder()..create(temporary);
        try {
          if (manifestBytes.length > _maxManifestSize) {
            throw const OotdBackupException('记录数据过大');
          }
          encoder.addArchiveFile(
            ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
          );
          var total = manifestBytes.length;
          if (files.length + 1 > _maxEntries) {
            throw const OotdBackupException('图片数量过多');
          }
          for (final entry in files.entries) {
            final file = File(entry.value);
            final size = await file.length();
            total += size;
            if (size > _maxImageSize || total > _maxExpandedSize) {
              throw const OotdBackupException('备份图片过大');
            }
            await encoder.addFile(file, entry.key, ZipFileEncoder.STORE);
          }
        } finally {
          await encoder.close();
        }
        if (await File(temporary).length() > _maxZipSize) {
          throw const OotdBackupException('备份文件超过 500MB');
        }
        await File(temporary).rename(zipPath);
      });
      // Only discard older backups once the new archive has been read and verified.
      await _parseBackup(zipPath, includeImageContents: false);
    } catch (_) {
      // Never remove an older successful backup when this attempt fails.
      for (final path in ['$zipPath.tmp', zipPath]) {
        try {
          final partial = File(path);
          if (await partial.exists()) await partial.delete();
        } on FileSystemException {
          // Retain the original failure if the filesystem also rejects cleanup.
        }
      }
      rethrow;
    }
    await _clearExistingZipFiles(directory, except: zipPath);
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
    await store.flushPendingWrites();
    importCheckpoint?.call('before-images');
    final parsed = await _parseBackup(zipPath, includeImageContents: true);
    importCheckpoint?.call('after-images');
    final snapshot = await _applyParsedBackup(parsed);
    importCheckpoint?.call('after-snapshot');
    return snapshot;
  }

  Future<void> recoverInterruptedImport() async {
    // Reading first resolves an unfinished JSON transaction. Old image generations
    // were never overwritten, so either complete snapshot remains usable.
    final items = await store.loadItemsJson();
    final paths = items == null
        ? <String>{}
        : _collectReferencedImagePaths(
            items.map(MockOotdItem.fromJson).toList(),
          );
    await store.removeUnreferencedImages(paths, protectedDraftPaths: {});
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
        if (image.sourceType != OotdImageSourceType.file ||
            image.path == null) {
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
        if (p.isAbsolute(relativePath) ||
            !relativePath.startsWith('images/') ||
            relativePath.split('/').contains('..')) {
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
          MockOotdImage.file(id: image.id, filePath: relativePath),
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

  static const _maxZipSize = 500 * 1024 * 1024;
  static const _maxExpandedSize = 1024 * 1024 * 1024;
  static const _maxImageSize = 64 * 1024 * 1024;
  static const _maxManifestSize = 16 * 1024 * 1024;
  static const _maxEntries = 10000;

  Future<_ParsedBackup> _parseBackup(
    String zipPath, {
    required bool includeImageContents,
  }) async {
    final root = await store.dataDirectoryPath();
    final generation = 'images/import-${DateTime.now().microsecondsSinceEpoch}';
    final extractionRoot = includeImageContents
        ? p.join(root, generation)
        : null;
    try {
      return await Isolate.run(
        () => _parseArchive(
          zipPath,
          extractionRoot: extractionRoot,
          generation: generation,
        ),
      );
    } catch (_) {
      if (extractionRoot != null &&
          p.isWithin(p.join(root, 'images'), extractionRoot)) {
        try {
          final staged = Directory(extractionRoot);
          if (await staged.exists()) await staged.delete(recursive: true);
        } on FileSystemException {
          // Startup cleanup retries if a filesystem failure prevented removal.
        }
      }
      rethrow;
    }
  }

  static bool _safeImagePath(String name) =>
      name.startsWith('images/') &&
      !name.contains('\\') &&
      !name.contains(':') &&
      !name.contains('\u0000') &&
      name
          .split('/')
          .every((part) => part.isNotEmpty && part != '.' && part != '..');

  static Stream<List<int>> _compressedChunks(ZipFile entry) async* {
    final input = entry.rawContent;
    if (input == null) throw const OotdBackupException('图片内容缺失');
    while (!input.isEOS) {
      yield input
          .readBytes(input.length > 65536 ? 65536 : input.length)
          .toUint8List();
    }
  }

  static Future<Uint8List?> _readEntry(
    ZipFile entry,
    int limit, {
    File? destination,
  }) async {
    final source = _compressedChunks(entry);
    final decoded = entry.compressionMethod == 8
        ? source.transform(io.ZLibDecoder(raw: true))
        : source;
    final bytes = destination == null ? BytesBuilder(copy: false) : null;
    final output = destination == null
        ? null
        : await destination.open(mode: FileMode.write);
    var length = 0;
    var crc = 0;
    try {
      await for (final chunk in decoded) {
        length += chunk.length;
        if (length > limit || length > entry.uncompressedSize!) {
          throw const OotdBackupException('解压内容超出大小限制');
        }
        crc = getCrc32(chunk, crc);
        if (output != null) {
          await output.writeFrom(chunk);
        } else {
          bytes!.add(chunk);
        }
      }
      if (length != entry.uncompressedSize || crc != entry.crc32) {
        throw const OotdBackupException('备份文件校验失败');
      }
      await output?.flush();
      return bytes?.takeBytes();
    } finally {
      await output?.close();
    }
  }

  static Future<_ParsedBackup> _parseArchive(
    String zipPath, {
    String? extractionRoot,
    required String generation,
  }) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw const OotdBackupException('没有找到选择的 zip 备份文件');
    }
    final size = await file.length();
    if (size > _maxZipSize || size < 22) {
      throw const OotdBackupException('备份文件大小不正确');
    }
    // Bound central-directory allocation before archive parses it. Our <500MB
    // format does not need ZIP64; reject it rather than trusting oversized fields.
    final handle = await file.open();
    late Uint8List tail;
    try {
      await handle.setPosition(size > 65557 ? size - 65557 : 0);
      tail = await handle.read(size > 65557 ? 65557 : size);
    } finally {
      await handle.close();
    }
    final data = ByteData.sublistView(tail);
    var end = -1;
    for (var i = tail.length - 22; i >= 0; i--) {
      if (data.getUint32(i, Endian.little) == 0x06054b50 &&
          i + 22 + data.getUint16(i + 20, Endian.little) == tail.length) {
        end = i;
        break;
      }
    }
    if (end < 0 ||
        data.getUint16(end + 10, Endian.little) > _maxEntries ||
        data.getUint32(end + 12, Endian.little) > _maxManifestSize ||
        data.getUint32(end + 16, Endian.little) >= size ||
        data.getUint16(end + 4, Endian.little) != 0) {
      throw const OotdBackupException('ZIP 目录无效或超出限制');
    }
    final input = InputFileStream(zipPath);
    try {
      final directory = ZipDirectory.read(input);
      if (directory.fileHeaders.length > _maxEntries) {
        throw const OotdBackupException('ZIP 条目过多');
      }
      final entries = <String, ZipFile>{};
      var total = 0;
      for (final header in directory.fileHeaders) {
        final entry = header.file!;
        final name = entry.filename;
        final mode = (header.externalFileAttributes ?? 0) >> 16;
        if (name != 'manifest.json' && !_safeImagePath(name)) {
          throw const OotdBackupException('备份包含非法路径');
        }
        if ((mode & 0xF000) == 0xA000 ||
            entry.flags & 1 != 0 ||
            ![0, 8].contains(entry.compressionMethod) ||
            entries.containsKey(name.toLowerCase())) {
          throw const OotdBackupException('备份包含重复、加密或不支持的文件');
        }
        final entrySize = entry.uncompressedSize ?? -1;
        final limit = name == 'manifest.json'
            ? _maxManifestSize
            : _maxImageSize;
        total += entrySize;
        if (entrySize < 0 || entrySize > limit || total > _maxExpandedSize) {
          throw const OotdBackupException('解压内容超出大小限制');
        }
        entries[name.toLowerCase()] = entry;
      }
      final manifestEntry = entries['manifest.json'];
      if (manifestEntry == null) {
        throw const OotdBackupException('zip 里缺少 manifest.json');
      }
      final manifest = jsonDecode(
        utf8.decode((await _readEntry(manifestEntry, _maxManifestSize))!),
      );
      if (manifest is! Map ||
          manifest['backupFormatVersion'] != ootdBackupFormatVersion) {
        throw const OotdBackupException('不支持的备份格式版本');
      }
      if (manifest['items'] is! List ||
          manifest['filters'] is! Map ||
          manifest['options'] is! Map ||
          manifest['images'] is! List) {
        throw const OotdBackupException('备份内容不完整');
      }
      final ids = <String>{};
      final dates = <String>{};
      for (final raw in manifest['items'] as List) {
        if (raw is! Map ||
            raw['id'] is! String ||
            (raw['id'] as String).trim().isEmpty ||
            raw['dateLabel'] is! String ||
            (raw['dateLabel'] as String).trim().isEmpty ||
            raw['images'] is! List ||
            (raw['images'] as List).isEmpty ||
            (raw['images'] as List).length > 4) {
          throw const OotdBackupException('穿搭记录必须包含有效日期和 1–4 张图片');
        }
        final date = readDateLabel(raw['dateLabel']);
        final parsedDate = DateTime.tryParse(date);
        if (parsedDate == null ||
            formatDateLabel(parsedDate) != date ||
            !ids.add(raw['id'] as String) ||
            !dates.add(date)) {
          throw const OotdBackupException('备份含重复记录、重复日期或无效日期');
        }
      }
      final items = (manifest['items'] as List)
          .map((item) => MockOotdItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      final filters = OotdFilterState.fromJson(
        Map<String, dynamic>.from(manifest['filters']),
      );
      final options = OotdOptionConfig.fromJson(
        Map<String, dynamic>.from(manifest['options']),
      );
      final paths = <String>{};
      for (final path in manifest['images'] as List) {
        if (path is! String ||
            !_safeImagePath(path) ||
            !paths.add(path) ||
            !entries.containsKey(path.toLowerCase())) {
          throw const OotdBackupException('图片目录不完整或含非法路径');
        }
      }
      final referenced = <String>{};
      for (final item in items) {
        for (final image in item.images) {
          if (image.sourceType == OotdImageSourceType.file) {
            if (image.path == null || !paths.contains(image.path)) {
              throw const OotdBackupException('记录引用的图片缺失');
            }
            referenced.add(image.path!);
          }
        }
      }
      final imagePaths = <String, String>{};
      if (extractionRoot != null) {
        await Directory(extractionRoot).create(recursive: true);
      }
      var imageIndex = 0;
      for (final path in paths) {
        final entry = entries[path.toLowerCase()]!;
        final name = '${imageIndex++}${p.posix.extension(path)}';
        final output = extractionRoot == null
            ? null
            : File(p.join(extractionRoot, name));
        // Preview validates size/CRC too; discard chunks instead of retaining images.
        if (output == null) {
          await _verifyEntry(entry, _maxImageSize);
        } else {
          await _readEntry(entry, _maxImageSize, destination: output);
          imagePaths[path] = '$generation/$name';
        }
      }
      return _ParsedBackup(
        preview: OotdBackupPreview(
          zipPath: zipPath,
          fileName: p.basename(zipPath),
          directoryPath: p.dirname(zipPath),
          itemCount: items.length,
          ootdImageCount: items.fold(
            0,
            (sum, item) => sum + item.images.length,
          ),
          imageCount: paths.length,
          exportedAt: manifest['exportedAt'] as String? ?? '',
          appVersion: manifest['appVersion'] as String? ?? '',
          backupFormatVersion: ootdBackupFormatVersion,
        ),
        items: items,
        filters: filters,
        options: options,
        imageContents: imagePaths,
      );
    } finally {
      await input.close();
    }
  }

  static Future<void> _verifyEntry(ZipFile entry, int limit) async {
    final source = _compressedChunks(entry);
    final decoded = entry.compressionMethod == 8
        ? source.transform(io.ZLibDecoder(raw: true))
        : source;
    var length = 0;
    var crc = 0;
    await for (final chunk in decoded) {
      length += chunk.length;
      if (length > limit || length > entry.uncompressedSize!) {
        throw const OotdBackupException('解压内容超出大小限制');
      }
      crc = getCrc32(chunk, crc);
    }
    if (length != entry.uncompressedSize || crc != entry.crc32) {
      throw const OotdBackupException('备份文件校验失败');
    }
  }

  Future<OotdImportedSnapshot> _applyParsedBackup(_ParsedBackup parsed) async {
    final items = normalizeItemsForOptions([
      for (final item in parsed.items)
        item.copyWith(
          images: [
            for (final image in item.images)
              image.sourceType == OotdImageSourceType.file
                  ? MockOotdImage.file(
                      id: image.id,
                      filePath: parsed.imageContents[image.path]!,
                    )
                  : image,
          ],
        ),
    ], parsed.options);
    await store.saveSnapshot(
      items: items.map((item) => item.toJson()).toList(),
      filters: parsed.filters.toJson(),
      options: parsed.options.toJson(),
    );
    return OotdImportedSnapshot(
      preview: parsed.preview,
      items: items,
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

  Future<void> _clearExistingZipFiles(
    Directory directory, {
    required String except,
  }) async {
    if (!await directory.exists()) {
      return;
    }

    final entries = await directory.list().toList();
    for (final entry in entries) {
      if (entry is File &&
          entry.path != except &&
          p.extension(entry.path).toLowerCase() == '.zip') {
        try {
          await entry.delete();
        } on FileSystemException {
          /* A valid new backup already exists. */
        }
      }
    }
  }
}
