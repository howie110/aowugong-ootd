import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aowugong_ootd/features/ootd/data/local_ootd_store.dart';
import 'package:aowugong_ootd/features/ootd/presentation/home/mock_ootd_items.dart';

void main() {
  test('failed deletion leaves state unchanged and retry commits', () async {
    final root = await Directory.systemTemp.createTemp('ootd-state-');
    addTearDown(() => root.delete(recursive: true));
    final store = OotdLocalStore(dataDirectoryOverride: root.path);
    final container = ProviderContainer(
      overrides: [ootdLocalStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final previous = container.read(ootdItemsProvider);
    final blocker = Directory('${root.path}/ootd_items.json.tmp');
    await blocker.create();
    await expectLater(
      container.read(ootdItemsProvider.notifier).deleteItem('look-01'),
      throwsA(isA<FileSystemException>()),
    );
    expect(container.read(ootdItemsProvider), previous);
    await blocker.delete();
    await container.read(ootdItemsProvider.notifier).deleteItem('look-01');
    expect(container.read(ootdItemsProvider).length, previous.length - 1);
    expect((await store.loadItemsJson())!.length, previous.length - 1);
  });
}
