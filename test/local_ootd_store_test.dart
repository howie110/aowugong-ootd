import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aowugong_ootd/features/ootd/data/local_ootd_store.dart';

void main() {
  late Directory root;
  late OotdLocalStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('ootd-store-');
    store = OotdLocalStore(dataDirectoryOverride: root.path);
  });
  tearDown(() async => root.delete(recursive: true));

  test('ordered writes retain the last requested snapshot', () async {
    await Future.wait(
      List.generate(
        30,
        (i) => store.saveItemsJson([
          {'id': i},
        ]),
      ),
    );
    await store.flushPendingWrites();
    expect(await store.loadItemsJson(), [
      {'id': 29},
    ]);
  });

  test('malformed and empty existing JSON are not a fresh install', () async {
    expect(await store.loadItemsJson(), isNull);
    final file = File('${root.path}/ootd_items.json');
    for (final value in ['{broken', '', '{}', '[1]']) {
      await file.writeAsString(value);
      await expectLater(store.loadItemsJson(), throwsFormatException);
      expect(await file.readAsString(), value);
    }
  });

  test('failed replacement preserves previous data and allows retry', () async {
    await store.saveItemsJson([
      {'id': 'old'},
    ]);
    final blocker = Directory('${root.path}/ootd_items.json.tmp');
    await blocker.create();
    await expectLater(
      store.saveItemsJson([
        {'id': 'new'},
      ]),
      throwsA(isA<FileSystemException>()),
    );
    expect(await store.loadItemsJson(), [
      {'id': 'old'},
    ]);
    await blocker.delete();
    await store.saveItemsJson([
      {'id': 'retry'},
    ]);
    expect(await store.loadItemsJson(), [
      {'id': 'retry'},
    ]);
  });

  test('interrupted replacement restores previous file', () async {
    await File(
      '${root.path}/ootd_items.json.previous',
    ).writeAsString('[{"id":"old"}]');
    await File(
      '${root.path}/ootd_items.json.tmp',
    ).writeAsString('[{"id":"new"}]');
    expect(await store.loadItemsJson(), [
      {'id': 'old'},
    ]);
  });

  test('snapshot failure restores all three files', () async {
    await store.saveSnapshot(
      items: [
        {'id': 'old'},
      ],
      filters: {'v': 1},
      options: {'v': 1},
    );
    final blocker = Directory('${root.path}/ootd_options.json.tmp');
    await blocker.create();
    await expectLater(
      store.saveSnapshot(
        items: [
          {'id': 'new'},
        ],
        filters: {'v': 2},
        options: {'v': 2},
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(await store.loadItemsJson(), [
      {'id': 'old'},
    ]);
    expect(await store.loadFiltersJson(), {'v': 1});
    expect(await store.loadOptionsJson(), {'v': 1});
  });

  for (final replaced in [1, 2, 3]) {
    test(
      'restart rolls back a journal interrupted after $replaced JSON replacements',
      () async {
        const names = [
          'ootd_items.json',
          'ootd_filters.json',
          'ootd_options.json',
        ];
        final old = {
          'ootd_items.json': '[{"id":"old"}]',
          'ootd_filters.json': '{"v":1}',
          'ootd_options.json': '{"v":1}',
        };
        final next = ['[{"id":"new"}]', '{"v":2}', '{"v":2}'];
        await File(
          '${root.path}/snapshot-recovery.json',
        ).writeAsString(jsonEncode(old), flush: true);
        for (var i = 0; i < names.length; i++) {
          await File(
            '${root.path}/${names[i]}',
          ).writeAsString(i < replaced ? next[i] : old[names[i]]!, flush: true);
        }
        final restarted = OotdLocalStore(dataDirectoryOverride: root.path);
        expect(await restarted.loadItemsJson(), [
          {'id': 'old'},
        ]);
        expect(await restarted.loadFiltersJson(), {'v': 1});
        expect(await restarted.loadOptionsJson(), {'v': 1});
        expect(
          await File('${root.path}/snapshot-recovery.json').exists(),
          isFalse,
        );
      },
    );
  }
}
