import 'dart:io';

import 'package:aowugong_ootd/shared/design/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_ootd_store.dart';
import '../home/mock_ootd_items.dart';

class OotdImageView extends ConsumerWidget {
  const OotdImageView({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.fullResolution = false,
  });

  final MockOotdImage image;
  final BoxFit fit;
  final bool fullResolution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageRoot = ref.watch(ootdStorageRootProvider);
    final resolvedPath = image.path == null || storageRoot.isEmpty
        ? image.path
        : resolveManagedImagePath(image.path!, dataDirectoryPath: storageRoot);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cacheWidth = !fullResolution && width.isFinite && width > 0
            ? (width * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(
                1,
                2048,
              )
            : null;
        return switch (image.sourceType) {
          OotdImageSourceType.asset => Image.asset(
            image.path ?? '',
            fit: fit,
            cacheWidth: cacheWidth,
            errorBuilder: (_, _, _) =>
                _FallbackColor(colorValue: image.colorValue),
          ),
          OotdImageSourceType.file => Image.file(
            File(resolvedPath ?? ''),
            fit: fit,
            cacheWidth: cacheWidth,
            errorBuilder: (_, _, _) =>
                _FallbackColor(colorValue: image.colorValue),
          ),
          OotdImageSourceType.solidColor => _FallbackColor(
            colorValue: image.colorValue,
          ),
        };
      },
    );
  }
}

class _FallbackColor extends StatelessWidget {
  const _FallbackColor({this.colorValue});

  final int? colorValue;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue ?? 0xFFE3ECF8);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.alphaBlend(const Color(0x4DFFFFFF), color)],
        ),
      ),
    );
  }
}
