import '../data/local_ootd_store.dart';
import '../domain/ootd_models.dart';
import '../domain/ootd_option_config.dart';

List<MockOotdItem> normalizeItemsForOptions(
  List<MockOotdItem> items,
  OotdOptionConfig config,
) {
  return items
      .map((item) => item.normalizedForConfig(config))
      .toList(growable: false);
}

List<MockOotdItem> normalizeItemsForStorageRoot(
  List<MockOotdItem> items,
  String dataDirectoryPath,
) {
  return items
      .map((item) => normalizeItemForStorageRoot(item, dataDirectoryPath))
      .toList(growable: false);
}

MockOotdItem normalizeItemForStorageRoot(
  MockOotdItem item,
  String dataDirectoryPath,
) {
  return item.copyWith(
    images: [
      for (final image in item.images)
        normalizeImageForStorageRoot(image, dataDirectoryPath),
    ],
  );
}

MockOotdImage normalizeImageForStorageRoot(
  MockOotdImage image,
  String dataDirectoryPath,
) {
  if (image.sourceType != OotdImageSourceType.file || image.path == null) {
    return image;
  }

  final normalizedPath = normalizeManagedImagePath(
    image.path!,
    dataDirectoryPath: dataDirectoryPath,
  );
  if (normalizedPath == image.path) {
    return image;
  }

  return MockOotdImage.file(id: image.id, filePath: normalizedPath);
}
