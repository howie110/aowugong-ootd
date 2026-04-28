import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoSelectionPage extends StatefulWidget {
  const PhotoSelectionPage({super.key});

  @override
  State<PhotoSelectionPage> createState() => _PhotoSelectionPageState();
}

class _PhotoSelectionPageState extends State<PhotoSelectionPage> {
  static const int _pageSize = 90;
  static final PMFilter _filterOption = FilterOptionGroup(
    imageOption: FilterOption(
      sizeConstraint: SizeConstraint(ignoreSize: true),
    ),
    orders: [
      OrderOption(type: OrderOptionType.createDate, asc: false),
    ],
  );

  final ImagePicker _cameraPicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  List<AssetEntity> _assets = const [];
  AssetPathEntity? _allAlbum;
  AssetEntity? _selectedAsset;
  PermissionState? _permissionState;
  String? _capturedImagePath;
  String? _capturedAssetId;
  String? _selectedCapturedPath;
  int _currentPage = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _capturing = false;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadAssets();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('选择图片')),
      body: Column(
        children: [
          Expanded(child: _buildBody(theme)),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  if (_hasSelection)
                    Text(
                      '已选 1 张',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5F7FB4),
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  FilledButton(
                    onPressed: !_hasSelection || _capturing
                        ? null
                        : _confirmSelection,
                    child: const Text('选择图片'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasSelection =>
      _selectedAsset != null || _selectedCapturedPath != null;

  bool get _showsCapturedTile {
    if (_capturedImagePath == null) {
      return false;
    }
    if (_capturedAssetId == null) {
      return true;
    }
    return !_assets.any((asset) => asset.id == _capturedAssetId);
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (!(_permissionState?.hasAccess ?? false)) {
      return _PermissionPanel(theme: theme);
    }

    final extraTileCount = _showsCapturedTile ? 1 : 0;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: 0.76,
      ),
      itemCount: _assets.length + 1 + extraTileCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CameraTile(
            busy: _capturing,
            onTap: _captureImage,
          );
        }

        if (_showsCapturedTile && index == 1) {
          return _CapturedTile(
            imagePath: _capturedImagePath!,
            selected: _selectedCapturedPath == _capturedImagePath,
            onTap: () {
              setState(() {
                _selectedAsset = null;
                _selectedCapturedPath = _capturedImagePath;
              });
            },
          );
        }

        final asset = _assets[index - 1 - extraTileCount];
        return _AssetTile(
          asset: asset,
          selected: _selectedAsset?.id == asset.id,
          onTap: () {
            setState(() {
              _selectedAsset = asset;
              _selectedCapturedPath = null;
            });
          },
        );
      },
    );
  }

  Future<void> _loadAssets({String? selectedId}) async {
    final permissionState = await PhotoManager.requestPermissionExtend();
    if (!mounted) {
      return;
    }

    if (!permissionState.hasAccess) {
      setState(() {
        _permissionState = permissionState;
        _assets = const [];
        _allAlbum = null;
        _selectedAsset = null;
        _selectedCapturedPath = null;
        _loading = false;
        _hasMore = false;
        _loadingMore = false;
      });
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: _filterOption,
    );
    if (!mounted) {
      return;
    }

    final allAlbum = albums.isNotEmpty ? albums.first : null;
    if (allAlbum == null) {
      setState(() {
        _permissionState = permissionState;
        _assets = const [];
        _allAlbum = null;
        _selectedAsset = null;
        _selectedCapturedPath = null;
        _loading = false;
        _hasMore = false;
        _loadingMore = false;
      });
      return;
    }

    final assets = await allAlbum.getAssetListPaged(page: 0, size: _pageSize);
    final totalCount = await allAlbum.assetCountAsync;
    if (!mounted) {
      return;
    }

    AssetEntity? selectedAsset;
    if (selectedId != null) {
      for (final asset in assets) {
        if (asset.id == selectedId) {
          selectedAsset = asset;
          break;
        }
      }
    }
    selectedAsset ??= _selectedAsset != null
        ? assets.cast<AssetEntity?>().firstWhere(
            (asset) => asset?.id == _selectedAsset!.id,
            orElse: () => null,
          )
        : null;

    final hasCapturedAsset = _capturedAssetId != null &&
        assets.any((asset) => asset.id == _capturedAssetId);

    setState(() {
      _permissionState = permissionState;
      _allAlbum = allAlbum;
      _assets = assets;
      _selectedAsset = selectedAsset;
      _selectedCapturedPath = hasCapturedAsset ? null : _selectedCapturedPath;
      _currentPage = 0;
      _hasMore = assets.length < totalCount;
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _loadMore() async {
    final album = _allAlbum;
    if (_loadingMore || !_hasMore || album == null) {
      return;
    }

    setState(() => _loadingMore = true);

    final nextPage = _currentPage + 1;
    final nextAssets = await album.getAssetListPaged(
      page: nextPage,
      size: _pageSize,
    );
    final totalCount = await album.assetCountAsync;

    if (!mounted) {
      return;
    }

    setState(() {
      _assets = [..._assets, ...nextAssets];
      _currentPage = nextPage;
      _hasMore = _assets.length < totalCount;
      _loadingMore = false;
    });
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 600) {
      _loadMore();
    }
  }

  Future<void> _captureImage() async {
    if (_capturing) {
      return;
    }

    final picked = await _cameraPicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );
    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _capturing = true;
      _capturedImagePath = picked.path;
      _capturedAssetId = null;
      _selectedAsset = null;
      _selectedCapturedPath = picked.path;
    });

    try {
      final entity = await PhotoManager.editor.saveImageWithPath(
        picked.path,
        title:
            'ootd_${DateTime.now().millisecondsSinceEpoch}${_fileExtensionOf(picked.path)}',
        creationDate: DateTime.now(),
      );

      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (!mounted) {
        return;
      }

      setState(() {
        _capturedAssetId = entity.id;
      });

      await _loadAssets(selectedId: entity.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('拍照失败，请重试')));
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<void> _confirmSelection() async {
    final selectedCapturedPath = _selectedCapturedPath;
    if (selectedCapturedPath != null) {
      Navigator.of(context).pop(selectedCapturedPath);
      return;
    }

    final selectedAsset = _selectedAsset;
    if (selectedAsset == null) {
      return;
    }

    final file = await selectedAsset.file;
    if (!mounted) {
      return;
    }
    if (file == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('读取图片失败，请重试')));
      return;
    }

    Navigator.of(context).pop(file.path);
  }

  String _fileExtensionOf(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) {
      return '.jpg';
    }
    return path.substring(dotIndex);
  }
}

class _PermissionPanel extends StatelessWidget {
  const _PermissionPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 34,
              color: Color(0xFF6C87B2),
            ),
            const SizedBox(height: 12),
            Text(
              '需要相册权限才能选择图片',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '打开权限后，再回来选择图片。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: PhotoManager.openSetting,
              child: const Text('去设置'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraTile extends StatelessWidget {
  const _CameraTile({
    required this.busy,
    required this.onTap,
  });

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '拍照',
      button: true,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E7F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.photo_camera_outlined,
                    size: 24,
                    color: Color(0xFF4B5566),
                  ),
                const SizedBox(height: 6),
                const Text(
                  '拍一张',
                  style: TextStyle(
                    color: Color(0xFF303743),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _CapturedTile extends StatelessWidget {
  const _CapturedTile({
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: selected ? '已选拍摄的照片' : '拍摄的照片',
      button: true,
      child: Material(
        color: Colors.black12,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFF1F4F8)),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _SelectionIndicator(selected: selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetTile extends StatefulWidget {
  const _AssetTile({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final AssetEntity asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AssetTile> createState() => _AssetTileState();
}

class _AssetTileState extends State<_AssetTile> {
  late final Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.asset.thumbnailDataWithSize(
      const ThumbnailSize.square(360),
      quality: 88,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.selected ? '已选照片' : '照片',
      button: true,
      child: Material(
        color: Colors.black12,
        child: InkWell(
          onTap: widget.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: FutureBuilder<Uint8List?>(
                future: _thumbnailFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                  }

                  return const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFF1F4F8)),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 1.8),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _SelectionIndicator(selected: widget.selected),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF3C7BF4) : Colors.black26,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.8),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : null,
    );
  }
}
