import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../home/mock_ootd_items.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  late MockOotdItem _initialItem;
  late MockOotdItem _draftItem;
  bool _itemMissing = false;
  bool _isPickingImage = false;

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
      return Scaffold(
        appBar: AppBar(title: const Text('穿搭详情')),
        body: const Center(child: Text('没有找到这条穿搭')),
      );
    }

    final options = ref.watch(ootdOptionConfigProvider);
    final optionGroups = options.allGroups;

    return Scaffold(
      appBar: AppBar(
        title: Text(_draftItem.dateLabel),
        actions: [
          if (!widget.isCreateMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: '删除穿搭',
                onPressed: _confirmDeleteItem,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _ImagesPanel(
            images: _draftItem.images,
            busy: _isPickingImage,
            onPreview: _showImagePreview,
            onReplacePrimary: () => _replaceImage(0),
            onReplaceSecondary: _replaceImage,
            onAddSecondary: _addSecondaryImage,
            onRemoveSecondary: _removeSecondaryImage,
          ),
          const SizedBox(height: 10),
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
                setState(() {
                  _draftItem = _draftItem.copyWithValue(
                    optionGroups[index].key,
                    value,
                  );
                });
              },
            ),
            if (index != optionGroups.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          key: const Key('ootd-save-button'),
          onPressed: _canSave ? _save : null,
          child: Text(widget.isCreateMode ? '新增穿搭' : '保存修改'),
        ),
      ),
    );
  }

  bool get _canSave {
    final hasChanges = !_draftItem.sameContentAs(_initialItem);
    final hasPrimaryImage =
        _draftItem.primaryImage.sourceType != OotdImageSourceType.solidColor;

    if (widget.isCreateMode) {
      return !_isPickingImage && hasChanges && hasPrimaryImage;
    }

    return !_isPickingImage && hasChanges;
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
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null) {
        return null;
      }

      final savedPath = await ref
          .read(ootdLocalStoreProvider)
          .savePickedImage(picked);

      return MockOotdImage.file(
        id: 'picked-${DateTime.now().microsecondsSinceEpoch}',
        filePath: savedPath,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('选图失败，请重试')));
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _showImagePreview(MockOotdImage image) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: AspectRatio(
                      aspectRatio: 0.72,
                      child: OotdImageView(image: image, fit: BoxFit.contain),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    key: const Key('ootd-preview-close'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _save() {
    final notifier = ref.read(ootdItemsProvider.notifier);
    final duplicateDate = notifier.hasItemOnDate(
      _draftItem.dateLabel,
      excludingId: widget.itemId,
    );
    if (duplicateDate) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('这一天已经有穿搭，不能重复保存')));
      return;
    }

    if (widget.isCreateMode) {
      notifier.addItem(
        images: _draftItem.images,
        dateLabel: _draftItem.dateLabel,
        preference: _draftItem.preference,
        season: _draftItem.season,
        scene: _draftItem.scene,
        tone: _draftItem.tone,
        rating: _draftItem.rating,
        extraSelections: _draftItem.extraSelections,
      );
    } else {
      notifier.updateItem(
        id: widget.itemId!,
        images: _draftItem.images,
        dateLabel: _draftItem.dateLabel,
        preference: _draftItem.preference,
        season: _draftItem.season,
        scene: _draftItem.scene,
        tone: _draftItem.tone,
        rating: _draftItem.rating,
        extraSelections: _draftItem.extraSelections,
      );
    }

    Navigator.of(context).pop();
  }

  Future<void> _confirmDeleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除穿搭'),
          content: const Text('删除后不能恢复。是否确认删除这条穿搭？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
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

    ref.read(ootdItemsProvider.notifier).deleteItem(widget.itemId!);
    Navigator.of(context).pop();
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE6F6)),
      ),
      padding: const EdgeInsets.all(10),
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

    return AspectRatio(
      aspectRatio: 0.74,
      child: Material(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: hasImage ? onPreview : onChange,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCE6F6)),
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
                  bottom: 4,
                  child: IconButton.filledTonal(
                    onPressed: busy ? null : onChange,
                    icon: Icon(
                      hasImage ? Icons.sync_alt_rounded : Icons.add_rounded,
                    ),
                    tooltip: hasImage ? '替换图片' : '添加图片',
                    iconSize: 14,
                    constraints: const BoxConstraints.tightFor(
                      width: 24,
                      height: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton.filled(
                      onPressed: busy ? null : onRemove,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: '删除副图',
                      iconSize: 14,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 24,
                      ),
                      padding: EdgeInsets.zero,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F6FD), Color(0xFFE4EDF9)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: Color(0xFF6C87B2),
          size: 18,
        ),
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
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
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
