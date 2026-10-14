import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aowugong_ootd/features/ootd/data/local_ootd_store.dart';
import 'package:aowugong_ootd/features/ootd/presentation/home/mock_ootd_items.dart';
import 'package:aowugong_ootd/features/settings/data/ootd_backup_service.dart';

void main() {
  late Directory root;
  late OotdLocalStore store;
  late OotdBackupService service;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('ootd-backup-');
    store = OotdLocalStore(dataDirectoryOverride: root.path);
    service = OotdBackupService(store: store);
  });
  tearDown(() => root.delete(recursive: true));

  Future<String> backup() async {
    await Directory('${root.path}/images').create(recursive: true);
    await File(
      '${root.path}/images/photo.jpg',
    ).writeAsBytes(List.generate(10000, (i) => i % 256));
    final item = defaultMockOotdItems.first.copyWith(
      images: [MockOotdImage.file(id: 'image', filePath: 'images/photo.jpg')],
    );
    return (await service.exportBackup(
      items: [item],
      filters: defaultOotdFilterState,
      options: defaultOotdOptionConfig,
    )).zipPath;
  }

  test('ZIP round trip preserves original bytes', () async {
    final zip = await backup();
    final result = await service.importBackup(
      zipPath: zip,
      currentItems: [],
      currentFilters: defaultOotdFilterState,
      currentOptions: defaultOotdOptionConfig,
    );
    final path = result.items.single.primaryImage.path!;
    expect(
      await File('${root.path}/$path').readAsBytes(),
      List.generate(10000, (i) => i % 256),
    );
    expect((await store.loadItemsJson())!.single['id'], result.items.single.id);
    await service.recoverInterruptedImport();
  });

  test('failed export retains previous backup', () async {
    final zip = await backup();
    await File('${root.path}/images/photo.jpg').delete();
    await expectLater(
      service.exportBackup(
        items: [
          defaultMockOotdItems.first.copyWith(
            images: [
              MockOotdImage.file(id: 'missing', filePath: 'images/photo.jpg'),
            ],
          ),
        ],
        filters: defaultOotdFilterState,
        options: defaultOotdOptionConfig,
      ),
      throwsA(isA<OotdBackupException>()),
    );
    expect(await File(zip).exists(), isTrue);
  });

  test('failed export cleans only its own incomplete output', () async {
    final previous = await backup();
    final large = await File(
      '${root.path}/images/large.jpg',
    ).open(mode: FileMode.write);
    await large.truncate(64 * 1024 * 1024 + 1);
    await large.close();
    await expectLater(
      service.exportBackup(
        items: [
          defaultMockOotdItems.first.copyWith(
            images: [
              MockOotdImage.file(id: 'one', filePath: 'images/photo.jpg'),
              MockOotdImage.file(id: 'two', filePath: 'images/large.jpg'),
            ],
          ),
        ],
        filters: defaultOotdFilterState,
        options: defaultOotdOptionConfig,
      ),
      throwsA(isA<OotdBackupException>()),
    );
    expect(await File(previous).exists(), isTrue);
    expect(
      (await Directory(
        '${root.path}/backup_exports',
      ).list().toList()).where((f) => f.path.endsWith('.tmp')),
      isEmpty,
    );
  });

  test(
    'corrupt image after extraction cleans only the failed generation',
    () async {
      await Directory('${root.path}/images').create();
      final old = await File('${root.path}/images/old.jpg').writeAsBytes([99]);
      final item = defaultMockOotdItems.first.copyWith(
        images: [
          MockOotdImage.file(id: 'one', filePath: 'images/good.jpg'),
          MockOotdImage.file(id: 'two', filePath: 'images/bad.jpg'),
        ],
      );
      final manifest = utf8.encode(
        jsonEncode({
          'backupFormatVersion': 1,
          'items': [item.toJson()],
          'filters': defaultOotdFilterState.toJson(),
          'options': defaultOotdOptionConfig.toJson(),
          'images': ['images/good.jpg', 'images/bad.jpg'],
        }),
      );
      final archive = Archive()
        ..addFile(ArchiveFile('manifest.json', manifest.length, manifest))
        ..addFile(ArchiveFile('images/good.jpg', 1, [1])..compress = false)
        ..addFile(ArchiveFile('images/bad.jpg', 1, [2])..compress = false);
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
      final view = ByteData.sublistView(bytes);
      for (var i = 0; i < bytes.length - 30; i++) {
        if (view.getUint32(i, Endian.little) != 0x04034b50) continue;
        final nameSize = view.getUint16(i + 26, Endian.little);
        final extraSize = view.getUint16(i + 28, Endian.little);
        if (utf8.decode(bytes.sublist(i + 30, i + 30 + nameSize)) ==
            'images/bad.jpg') {
          bytes[i + 30 + nameSize + extraSize] = 77;
          break;
        }
      }
      final zip = await File('${root.path}/corrupt.zip').writeAsBytes(bytes);
      await expectLater(
        service.importBackup(
          zipPath: zip.path,
          currentItems: [],
          currentFilters: defaultOotdFilterState,
          currentOptions: defaultOotdOptionConfig,
        ),
        throwsA(anything),
      );
      expect(await old.readAsBytes(), [99]);
      expect(
        (await Directory(
          '${root.path}/images',
        ).list().toList()).whereType<Directory>(),
        isEmpty,
      );
    },
  );

  for (final badKind in [
    'empty-images',
    'many-images',
    'duplicate-id',
    'duplicate-date',
  ]) {
    test('rejects $badKind with a runtime validation error', () async {
      final first = defaultMockOotdItems.first.toJson();
      final second = defaultMockOotdItems.last.toJson();
      if (badKind == 'empty-images') first['images'] = [];
      if (badKind == 'many-images') {
        first['images'] = List.filled(
          5,
          defaultMockOotdItems.first.images.first.toJson(),
        );
      }
      if (badKind == 'duplicate-id') second['id'] = first['id'];
      if (badKind == 'duplicate-date') second['dateLabel'] = first['dateLabel'];
      final manifest = utf8.encode(
        jsonEncode({
          'backupFormatVersion': 1,
          'items': [first, second],
          'filters': defaultOotdFilterState.toJson(),
          'options': defaultOotdOptionConfig.toJson(),
          'images': [],
        }),
      );
      final zip = await File('${root.path}/invalid.zip').writeAsBytes(
        ZipEncoder().encode(
          Archive()
            ..addFile(ArchiveFile('manifest.json', manifest.length, manifest)),
        )!,
      );
      await expectLater(
        service.readBackupPreview(zip.path),
        throwsA(isA<OotdBackupException>()),
      );
    });
  }

  for (final phase in ['before-images', 'after-images', 'after-snapshot']) {
    test(
      'interruption at $phase leaves a complete recoverable snapshot',
      () async {
        final zip = await backup();
        await File('${root.path}/images/photo.jpg').writeAsBytes([99]);
        final oldItem = defaultMockOotdItems.last.copyWith(
          images: [
            MockOotdImage.file(id: 'old-image', filePath: 'images/photo.jpg'),
          ],
        );
        await store.saveSnapshot(
          items: [oldItem.toJson()],
          filters: defaultOotdFilterState.toJson(),
          options: defaultOotdOptionConfig.toJson(),
        );
        final interrupted = OotdBackupService(
          store: store,
          importCheckpoint: (value) {
            if (value == phase) throw StateError('simulated process stop');
          },
        );
        await expectLater(
          interrupted.importBackup(
            zipPath: zip,
            currentItems: [oldItem],
            currentFilters: defaultOotdFilterState,
            currentOptions: defaultOotdOptionConfig,
          ),
          throwsA(anything),
        );
        await service.recoverInterruptedImport();
        final items = (await store.loadItemsJson())!
            .map(MockOotdItem.fromJson)
            .toList();
        expect(
          items.single.id,
          phase == 'after-snapshot'
              ? defaultMockOotdItems.first.id
              : defaultMockOotdItems.last.id,
        );
        for (final image in items.single.images) {
          if (image.sourceType == OotdImageSourceType.file) {
            expect(
              await File('${root.path}/${image.path}').readAsBytes(),
              phase == 'after-snapshot'
                  ? List.generate(10000, (i) => i % 256)
                  : [99],
            );
          }
        }
      },
    );
  }

  test(
    'rejects traversal, missing image, duplicate entries and future format',
    () async {
      for (final kind in ['traversal', 'missing', 'duplicate', 'version']) {
        final manifest = {
          'backupFormatVersion': kind == 'version' ? 999 : 1,
          'items': [
            defaultMockOotdItems.first
                .copyWith(
                  images: [
                    MockOotdImage.file(id: 'x', filePath: 'images/x.jpg'),
                  ],
                )
                .toJson(),
          ],
          'filters': defaultOotdFilterState.toJson(),
          'options': defaultOotdOptionConfig.toJson(),
          'images': ['images/x.jpg'],
        };
        final bytes = utf8.encode(jsonEncode(manifest));
        final archive = Archive()
          ..addFile(ArchiveFile('manifest.json', bytes.length, bytes));
        if (kind != 'missing') {
          archive.addFile(ArchiveFile('images/x.jpg', 1, [1]));
        }
        if (kind == 'traversal') {
          archive.addFile(ArchiveFile('../outside.jpg', 1, [1]));
        }
        if (kind == 'duplicate') {
          archive.addFile(ArchiveFile('images/../images/x.jpg', 1, [1]));
        }
        final zip = File('${root.path}/bad-$kind.zip');
        await zip.writeAsBytes(ZipEncoder().encode(archive)!);
        await expectLater(
          service.readBackupPreview(zip.path),
          throwsA(anything),
        );
      }
    },
  );
}
