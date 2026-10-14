import '../../../ootd/presentation/home/providers/ootd_mutation_queue.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:aowugong_ootd/shared/design/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_metadata.dart';
import '../../../../features/ootd/presentation/home/mock_ootd_items.dart';
import '../../../../shared/design/ootd_card.dart';
import '../../data/ootd_backup_service.dart';

class BackupExportPage extends ConsumerStatefulWidget {
  const BackupExportPage({super.key});

  @override
  ConsumerState<BackupExportPage> createState() => _BackupExportPageState();
}

class _BackupExportPageState extends ConsumerState<BackupExportPage> {
  OotdBackupService get _backupService =>
      OotdBackupService(store: ref.read(ootdLocalStoreProvider));

  OotdBackupPreview? _lastPreview;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLatestPreview();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(ootdItemsProvider);
    final totalImageCount = items.fold(
      0,
      (sum, item) => sum + item.images.length,
    );
    final backupImageCount = items
        .expand((item) => item.images)
        .where((image) => image.sourceType == OotdImageSourceType.file)
        .length;

    return PopScope(
      canPop: !_busy,
      child: AppScaffold(
        appBar: AppPageBar(title: const Text('数据备份')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const _GuideCard(
              title: '导出说明',
              lines: [
                '会把当前数据打包成一个 zip 备份文件。',
                '生成后会弹出系统另存为窗口，请自己选择 zip 保存目录。',
                '建议直接保存到 Download，这样最容易找到。',
                'zip 内包含 manifest.json、ootd 数据和本地目录里的图片文件。',
              ],
            ),
            const SizedBox(height: 12),
            _StatsCard(
              itemCount: items.length,
              totalImageCount: totalImageCount,
              backupImageCount: backupImageCount,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              onPressed: _busy ? null : _exportBackup,
              leading: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(),
                    )
                  : const Icon(LucideIcons.archive),
              child: Text(_busy ? '正在生成 zip...' : '生成 zip 备份文件'),
            ),
            if (_lastPreview != null) ...[
              const SizedBox(height: 12),
              _ResultCard(
                preview: _lastPreview!,
                onShare: _busy ? null : _shareBackup,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '当前版本：$appFullVersion',
              style: Theme.of(context).typography.small.copyWith(
                color: Theme.of(context).colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final temporaryPreview = await ref
          .read(ootdMutationQueueProvider)
          .run(
            () => _backupService.exportBackup(
              items: ref.read(ootdItemsProvider),
              filters: ref.read(ootdFiltersProvider),
              options: ref.read(ootdOptionConfigProvider),
            ),
          );
      final bytes = await File(temporaryPreview.zipPath).readAsBytes();
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: '选择 zip 保存位置',
        fileName: temporaryPreview.fileName,
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        bytes: bytes,
      );

      if (!mounted) {
        return;
      }

      if (savedPath == null) {
        showAppMessage(context, '已取消选择保存位置');
        return;
      }

      await _backupService.rememberLastExportZipPath(savedPath);
      if (!mounted) {
        return;
      }
      final preview = temporaryPreview.copyWith(
        zipPath: savedPath,
        directoryPath: File(savedPath).parent.path,
      );

      setState(() => _lastPreview = preview);
      showAppMessage(context, 'zip 备份文件已保存');
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppMessage(
        context,
        error is OotdBackupException ? '数据备份失败：$error' : '数据备份失败，请重试',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _shareBackup() async {
    final preview = _lastPreview;
    if (preview == null) {
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(preview.zipPath)],
        text: '穿搭备份 zip 已生成，可以直接发送到新手机导入。',
        subject: preview.fileName,
      );
    } catch (_) {
      if (mounted) showAppMessage(context, '分享失败，请检查备份文件是否还在');
    }
  }

  Future<void> _loadLatestPreview() async {
    OotdBackupPreview? preview;
    try {
      preview = await _backupService.loadLatestExportPreview();
    } catch (_) {
      return;
    }
    if (!mounted || preview == null) {
      return;
    }

    setState(() => _lastPreview = preview);
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OotdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.typography.large.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines) ...[
            Text(
              line,
              style: theme.typography.small.copyWith(
                color: theme.colorScheme.mutedForeground,
                height: 1.45,
              ),
            ),
            if (line != lines.last) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.itemCount,
    required this.totalImageCount,
    required this.backupImageCount,
  });

  final int itemCount;
  final int totalImageCount;
  final int backupImageCount;

  @override
  Widget build(BuildContext context) {
    return OotdCard(
      child: Row(
        children: [
          _StatColumn(label: '穿搭', value: '$itemCount'),
          _StatColumn(label: '穿搭图', value: '$totalImageCount'),
          _StatColumn(label: 'zip图', value: '$backupImageCount'),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.typography.xLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.typography.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.preview, required this.onShare});

  final OotdBackupPreview preview;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OotdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近一次生成',
            style: theme.typography.large.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _ResultLine(label: '文件名', value: preview.fileName),
          _ResultLine(label: '目录', value: preview.directoryPath),
          _ResultLine(label: '完整路径', value: preview.zipPath),
          _ResultLine(label: '穿搭数量', value: '${preview.itemCount}'),
          _ResultLine(label: '穿搭图', value: '${preview.ootdImageCount}'),
          _ResultLine(label: 'zip图', value: '${preview.imageCount}'),
          const SizedBox(height: 10),
          OutlineButton(
            onPressed: onShare,
            leading: const Icon(LucideIcons.share2),
            child: const Text('再次分享 zip'),
          ),
        ],
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: theme.typography.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.typography.small.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
