import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_ootd_store.dart';
import '../home/mock_ootd_items.dart';

class OotdImageView extends ConsumerWidget {
  const OotdImageView({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
  });

  final MockOotdImage image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageRoot = ref.watch(ootdStorageRootProvider);
    final resolvedPath = image.path == null || storageRoot.isEmpty
        ? image.path
        : resolveManagedImagePath(
            image.path!,
            dataDirectoryPath: storageRoot,
          );

    return switch (image.sourceType) {
      OotdImageSourceType.asset => Image.asset(
        image.path ?? '',
        fit: fit,
        errorBuilder: (_, _, _) => _FallbackColor(colorValue: image.colorValue),
      ),
      OotdImageSourceType.file => Image.file(
        File(resolvedPath ?? ''),
        fit: fit,
        errorBuilder: (_, _, _) => _FallbackColor(colorValue: image.colorValue),
      ),
      OotdImageSourceType.solidColor => _FallbackColor(
        colorValue: image.colorValue,
      ),
    };
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
          colors: [color, Color.alphaBlend(Colors.white30, color)],
        ),
      ),
    );
  }
}
