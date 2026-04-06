import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_metadata.dart';
import '../../../../features/ootd/presentation/home/mock_ootd_items.dart';
import '../../data/ootd_backup_service.dart';

class BackupExportPage extends ConsumerStatefulWidget {
  const BackupExportPage({super.key});

  @override
  ConsumerState<BackupExportPage> createState() => _BackupExportPageState();
}

class _BackupExportPageState extends ConsumerState<BackupExportPage> {
  final OotdBackupService _backupService = const OotdBackupService();

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
    final totalImageCount = items.fold(0, (sum, item) => sum + item.images.length);
    final backupImageCount = items
        .expand((item) => item.images)
        .where((image) => image.sourceType == OotdImageSourceType.file)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('数据备份')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _GuideCard(
            title: '导出说明',
            lines: [
              '会把当前数据打包成一个 zip 备份文件。',
              '生成后会直接弹出系统分享面板，你可以发送到新手机。',
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
          FilledButton.icon(
            onPressed: _busy ? null : _exportBackup,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.archive_outlined),
            label: Text(_busy ? '正在生成 zip...' : '生成 zip 备份文件'),
          ),
          if (_lastPreview != null) ...[
            const SizedBox(height: 12),
            _ResultCard(preview: _lastPreview!, onShare: _busy ? null : _shareBackup),
          ],
          const SizedBox(height: 12),
          Text(
            '当前版本：$appFullVersion',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      final preview = await _backupService.exportBackup(
        items: ref.read(ootdItemsProvider),
        filters: ref.read(ootdFiltersProvider),
        options: ref.read(ootdOptionConfigProvider),
      );

      if (!mounted) {
        return;
      }

      setState(() => _lastPreview = preview);
      await _shareBackup();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('数据备份失败：$error')));
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

    await Share.shareXFiles(
      [XFile(preview.zipPath)],
      text: '穿搭备份 zip 已生成，可以直接发送到新手机导入。',
      subject: preview.fileName,
    );
  }

  Future<void> _loadLatestPreview() async {
    final preview = await _backupService.loadLatestExportPreview();
    if (!mounted || preview == null) {
      return;
    }

    setState(() => _lastPreview = preview);
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines) ...[
            Text(
              line,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F6)),
      ),
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
  const _StatColumn({
    required this.label,
    required this.value,
  });

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
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.preview,
    required this.onShare,
  });

  final OotdBackupPreview preview;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近一次生成',
            style: theme.textTheme.titleMedium?.copyWith(
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
          OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined),
            label: const Text('再次分享 zip'),
          ),
        ],
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.label,
    required this.value,
  });

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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
