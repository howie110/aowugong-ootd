import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aowugong_ootd/features/ootd/data/local_ootd_store.dart';

void main() {
  test(
    'cleanup preserves shared references, drafts, and external files',
    () async {
      final root = await Directory.systemTemp.createTemp('ootd-images-');
      addTearDown(() => root.delete(recursive: true));
      final data = Directory('${root.path}/data');
      await Directory('${data.path}/images').create(recursive: true);
      final store = OotdLocalStore(dataDirectoryOverride: data.path);
      final outside = await File(
        '${root.path}/external.jpg',
      ).writeAsBytes([1, 2, 3]);
      await File('${data.path}/images/shared.jpg').writeAsBytes([1]);
      await File('${data.path}/images/unused.jpg').writeAsBytes([1]);
      final draft = await store.savePickedImage(XFile(outside.path));
      expect(draft, startsWith('drafts/'));
      await store.removeUnreferencedImages(
        {'images/shared.jpg', outside.path},
        protectedDraftPaths: {draft},
      );
      expect(await File('${data.path}/images/shared.jpg').exists(), isTrue);
      expect(await File('${data.path}/images/unused.jpg').exists(), isFalse);
      expect(await File('${data.path}/$draft').exists(), isTrue);
      expect(await outside.exists(), isTrue);
      final promoted = await store.promoteDraftImage(draft);
      expect(promoted, startsWith('images/'));
      await store.removeUnreferencedImages({promoted}, protectedDraftPaths: {});
      expect(await File('${data.path}/$promoted').readAsBytes(), [1, 2, 3]);
      expect(await File('${data.path}/$draft').exists(), isFalse);
      expect(await outside.exists(), isTrue);
    },
  );
}
