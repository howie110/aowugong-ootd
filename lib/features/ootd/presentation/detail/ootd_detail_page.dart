import 'package:aowugong_ootd/shared/design/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/navigation/smooth_page_route.dart';
import '../../../../shared/design/app_theme.dart';
import '../home/mock_ootd_items.dart';
import 'photo_selection_page.dart';
import '../shared/compact_option_group.dart';
import '../shared/ootd_image_view.dart';

class OotdDetailPage extends ConsumerStatefulWidget {
  const OotdDetailPage({super.key, this.itemId});

  final String? itemId;

  bool get isCreateMode => itemId == null;

  @override
  ConsumerState<OotdDetailPage> createState() => _OotdDetailPageState();
}

class _OotdDetailPageState extends ConsumerState<OotdDetailPage> {
  late MockOotdItem _initialItem;
  late MockOotdItem _draftItem;
  bool _itemMissing = false;
  bool _isPickingImage = false;
  bool _saving = false;
  bool _allowPop = false;
  bool _confirmingBack = false;

  @override
  void initState() {
    super.initState();
    final source = _loadSourceItem();
    _initialItem = source;
    _draftItem = _cloneItem(source);
  }

  @override
  Widget build(BuildContext context) {
    if (_itemMissing) {
      return AppScaffold(
        appBar: AppPageBar(title: const Text('穿搭详情')),
        body: const Center(child: Text('没有找到这条穿搭')),
      );
    }

    final options = ref.watch(ootdOptionConfigProvider);
    final optionGroups = options.allGroups;

    return PopScope(
      canPop:
          _allowPop ||
          (!_saving &&
              !_isPickingImage &&
              _draftItem.sameContentAs(_initialItem)),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmBack();
      },
      child: AppScaffold(
        appBar: AppPageBar(
          title: Text(_draftItem.dateLabel),
          actions: [
            if (!widget.isCreateMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AppIconButton(
                  tooltip: '删除穿搭',
                  onPressed: _saving || _isPickingImage
                      ? null
                      : _confirmDeleteItem,
                  icon: const Icon(LucideIcons.trash2),
                ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ImagesPanel(
              images: _draftItem.images,
              busy: _isPickingImage || _saving,
              onPreview: _showImagePreview,
              onReplacePrimary: () => _replaceImage(0),
              onReplaceSecondary: _replaceImage,
              onAddSecondary: _addSecondaryImage,
              onRemoveSecondary: _removeSecondaryImage,
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < optionGroups.length; index++) ...[
              CompactOptionGroup<String>(
                options: optionGroups[index].values,
                isSelected: (value) =>
                    _draftItem.valueOf(
                      optionGroups[index].key,
                      fallback: optionGroups[index].values.first,
                    ) ==
                    value,
                labelBuilder: (value) => value,
                onTap: (value) {
                  if (_saving) return;
                  setState(() {
                    _draftItem = _draftItem.copyWithValue(
                      optionGroups[index].key,
                      value,
                    );
                  });
                },
              ),
              if (index != optionGroups.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              key: const Key('ootd-save-button'),
              onPressed: _canSave ? _save : null,
              child: Text(widget.isCreateMode ? '新增穿搭' : '保存修改'),
            ),
          ),
        ),
      ),
    );
  }

  bool get _canSave {
    final hasChanges = !_draftItem.sameContentAs(_initialItem);
    final hasPrimaryImage =
        _draftItem.primaryImage.sourceType != OotdImageSourceType.solidColor;

    if (widget.isCreateMode) {
      return !_saving && !_isPickingImage && hasChanges && hasPrimaryImage;
    }

    return !_saving && !_isPickingImage && hasChanges;
  }

  MockOotdItem _loadSourceItem() {
    final config = ref.read(ootdOptionConfigProvider);
    if (widget.isCreateMode) {
      return createDraftOotdItem(config).normalizedForConfig(config);
    }

    final source = ref.read(ootdByIdProvider(widget.itemId!));
    if (source == null) {
      _itemMissing = true;
      return createDraftOotdItem(config).normalizedForConfig(config);
    }

    return _cloneItem(source).normalizedForConfig(config);
  }

  MockOotdItem _cloneItem(MockOotdItem source) {
    return source.copyWith(images: List<MockOotdImage>.from(source.images));
  }

  Future<void> _replaceImage(int index) async {
    final nextImage = await _pickImage();
    if (!mounted || nextImage == null) {
      return;
    }

    setState(() {
      final images = List<MockOotdImage>.from(_draftItem.images);
      images[index] = nextImage;
      _draftItem = _draftItem.copyWith(images: images);
    });
  }

  Future<void> _addSecondaryImage() async {
    if (_draftItem.images.length >= 4) {
      return;
    }

    final nextImage = await _pickImage();
    if (!mounted || nextImage == null) {
      return;
    }

    setState(() {
      _draftItem = _draftItem.copyWith(
        images: [..._draftItem.images, nextImage],
      );
    });
  }

  void _removeSecondaryImage(int index) {
    if (index <= 0 || index >= _draftItem.images.length) {
      return;
    }

    setState(() {
      final images = List<MockOotdImage>.from(_draftItem.images)
        ..removeAt(index);
      _draftItem = _draftItem.copyWith(images: images);
    });
  }

  Future<MockOotdImage?> _pickImage() async {
    if (_isPickingImage) {
      return null;
    }

    setState(() => _isPickingImage = true);

    try {
      final selectedPath = await Navigator.of(
        context,
      ).push<String>(SmoothPageRoute<String>(page: const PhotoSelectionPage()));
      if (selectedPath == null) {
        return null;
      }

      final savedPath = await ref
          .read(ootdLocalStoreProvider)
          .savePickedImage(XFile(selectedPath));

      return MockOotdImage.file(
        id: 'picked-${DateTime.now().microsecondsSinceEpoch}',
        filePath: savedPath,
      );
    } catch (_) {
      if (mounted) {
        showAppMessage(context, '选图失败，请重试');
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _showImagePreview(MockOotdImage image) async {
    await showAppDialog<void>(
      context: context,
      barrierColor: const Color(0xDD000000),
      fullScreen: true,
      builder: (dialogContext) {
        return ColoredBox(
          color: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: AspectRatio(
                      aspectRatio: 0.72,
                      child: OotdImageView(
                        image: image,
                        fit: BoxFit.contain,
                        fullResolution: true,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: AppIconButton(
                    key: const Key('ootd-preview-close'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(LucideIcons.x),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final notifier = ref.read(ootdItemsProvider.notifier);
    final duplicateDate = notifier.hasItemOnDate(
      _draftItem.dateLabel,
      excludingId: widget.itemId,
    );
    if (duplicateDate) {
      showAppMessage(context, '这一天已经有穿搭，不能重复保存');
      return;
    }

    setState(() => _saving = true);
    try {
      final store = ref.read(ootdLocalStoreProvider);
      final images = <MockOotdImage>[];
      for (final image in _draftItem.images) {
        images.add(
          image.sourceType == OotdImageSourceType.file && image.path != null
              ? MockOotdImage.file(
                  id: image.id,
                  filePath: await store.promoteDraftImage(image.path!),
                )
              : image,
        );
      }
      if (widget.isCreateMode) {
        await notifier.addItem(
          images: images,
          dateLabel: _draftItem.dateLabel,
          preference: _draftItem.preference,
          season: _draftItem.season,
          scene: _draftItem.scene,
          tone: _draftItem.tone,
          rating: _draftItem.rating,
          extraSelections: _draftItem.extraSelections,
        );
      } else {
        await notifier.updateItem(
          id: widget.itemId!,
          images: images,
          dateLabel: _draftItem.dateLabel,
          preference: _draftItem.preference,
          season: _draftItem.season,
          scene: _draftItem.scene,
          tone: _draftItem.tone,
          rating: _draftItem.rating,
          extraSelections: _draftItem.extraSelections,
        );
      }

      if (!mounted) return;
      _initialItem = _draftItem;
      await _cleanupImages();
      _leave();
    } catch (_) {
      if (mounted) showAppMessage(context, '保存失败，修改仍保留，请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cleanupImages() async {
    final store = ref.read(ootdLocalStoreProvider);
    final paths = ref
        .read(ootdItemsProvider)
        .expand((item) => item.images)
        .map((image) => image.path)
        .whereType<String>()
        .toSet();
    try {
      await store.removeUnreferencedImages(paths, protectedDraftPaths: {});
    } catch (_) {
      // Cleanup is best effort; never turn a successful commit into a failed save.
    }
  }

  void _leave() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _confirmBack() async {
    if (_saving || _isPickingImage || _confirmingBack) return;
    _confirmingBack = true;
    final choice = await showAppDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('有未保存的修改'),
        content: const Text('保存后离开，或放弃这次修改。'),
        actions: [
          GhostButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续编辑'),
          ),
          OutlineButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('放弃修改'),
          ),
          PrimaryButton(
            onPressed: _canSave ? () => Navigator.pop(context, 'save') : null,
            child: const Text('保存'),
          ),
        ],
      ),
    );
    _confirmingBack = false;
    if (!mounted) return;
    if (choice == 'save') await _save();
    if (choice == 'discard') {
      await _cleanupImages();
      _leave();
    }
  }

  Future<void> _confirmDeleteItem() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除穿搭'),
          content: const Text('删除后不能恢复。是否确认删除这条穿搭？'),
          actions: [
            GhostButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            PrimaryButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true || widget.itemId == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(ootdItemsProvider.notifier).deleteItem(widget.itemId!);
      if (!mounted) return;
      await _cleanupImages();
      _leave();
    } catch (_) {
      if (mounted) showAppMessage(context, '删除失败，请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ImagesPanel extends StatelessWidget {
  const _ImagesPanel({
    required this.images,
    required this.busy,
    required this.onPreview,
    required this.onReplacePrimary,
    required this.onReplaceSecondary,
    required this.onAddSecondary,
    required this.onRemoveSecondary,
  });

  final List<MockOotdImage> images;
  final bool busy;
  final ValueChanged<MockOotdImage> onPreview;
  final VoidCallback onReplacePrimary;
  final ValueChanged<int> onReplaceSecondary;
  final VoidCallback onAddSecondary;
  final ValueChanged<int> onRemoveSecondary;

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          for (var index = 0; index < 4; index++) ...[
            if (index != 0) const SizedBox(width: 6),
            Expanded(
              child: _ImageTile(
                key: Key('ootd-image-slot-$index'),
                image: index < images.length ? images[index] : null,
                label: index == 0 ? '主' : null,
                busy: busy,
                onPreview: index < images.length
                    ? () => onPreview(images[index])
                    : null,
                onChange: index == 0
                    ? onReplacePrimary
                    : index >= images.length
                    ? onAddSecondary
                    : () => onReplaceSecondary(index),
                onRemove: index != 0 && index < images.length
                    ? () => onRemoveSecondary(index)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    super.key,
    required this.image,
    required this.label,
    required this.busy,
    required this.onPreview,
    required this.onChange,
    required this.onRemove,
  });

  final MockOotdImage? image;
  final String? label;
  final bool busy;
  final VoidCallback? onPreview;
  final VoidCallback onChange;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;
    final ootd = OotdColors.of(context);

    return AspectRatio(
      aspectRatio: 0.60,
      child: AppImageSurface(
        color: ootd.mutedSurface,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: AppPressable(
          onTap: busy
              ? null
              : hasImage
              ? onPreview
              : onChange,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ootd.cardBorder),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: hasImage
                      ? OotdImageView(image: image!)
                      : const _EmptyImageSlot(),
                ),
                if (label != null)
                  Positioned(left: 6, top: 6, child: _TileBadge(label: label!)),
                Positioned(
                  right: 4,
                  bottom: 6,
                  child: AppIconButton(
                    onPressed: busy ? null : onChange,
                    icon: Icon(
                      hasImage ? LucideIcons.replace : LucideIcons.plus,
                    ),
                    tooltip: hasImage ? '替换图片' : '添加图片',
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: AppIconButton(
                      onPressed: busy ? null : onRemove,
                      icon: const Icon(LucideIcons.x),
                      tooltip: '删除副图',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyImageSlot extends StatelessWidget {
  const _EmptyImageSlot();

  @override
  Widget build(BuildContext context) {
    final ootd = OotdColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: ootd.mutedSurface),
      child: Center(
        child: Icon(LucideIcons.imagePlus, color: ootd.subtleIcon, size: 18),
      ),
    );
  }
}

class _TileBadge extends StatelessWidget {
  const _TileBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
