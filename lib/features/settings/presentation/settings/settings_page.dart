import 'package:flutter/material.dart';

import '../../../../app/app_metadata.dart';
import '../../../../shared/design/app_theme.dart';
import '../../../../shared/navigation/smooth_page_route.dart';
import 'backup_export_page.dart';
import 'backup_import_page.dart';
import 'option_management_page.dart';
import 'settings_placeholder_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      key: const PageStorageKey<String>('settings-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsGroup(
            items: [
              _SettingsItemData(
                icon: Icons.tune_rounded,
                title: '选项管理',
                onTap: () {
                  Navigator.of(context).push(
                    SmoothPageRoute<void>(
                      page: const OptionManagementPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            items: [
              _SettingsItemData(
                icon: Icons.cloud_upload_outlined,
                title: '数据备份',
                onTap: () {
                  Navigator.of(context).push(
                    SmoothPageRoute<void>(
                      page: const BackupExportPage(),
                    ),
                  );
                },
              ),
              _SettingsItemData(
                icon: Icons.download_for_offline_outlined,
                title: '备份导入',
                onTap: () {
                  Navigator.of(context).push(
                    SmoothPageRoute<void>(
                      page: const BackupImportPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            items: [
              _SettingsItemData(
                icon: Icons.help_outline_rounded,
                title: '帮助中心',
                onTap: () => _openPlaceholder(context, '帮助中心'),
              ),
              _SettingsItemData(
                icon: Icons.info_outline_rounded,
                title: '版本信息',
                trailingText: appVersionLabel,
                onTap: () => _openPlaceholder(context, '版本信息'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '帮助中心和版本信息仍为预留页，数据备份和备份导入已接入 zip 流程。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlaceholder(BuildContext context, String title) {
    Navigator.of(context).push(
      SmoothPageRoute<void>(
        page: SettingsPlaceholderPage(title: title),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});

  final List<_SettingsItemData> items;

  @override
  Widget build(BuildContext context) {
    final ootd = Theme.of(context).extension<OotdColors>() ?? OotdColors.light;

    return Container(
      decoration: BoxDecoration(
        color: ootd.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ootd.cardBorder),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _SettingsRow(data: items[index]),
            if (index != items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Divider(height: 1, color: ootd.subtleDivider),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data});

  final _SettingsItemData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ootd = theme.extension<OotdColors>() ?? OotdColors.light;

    return Semantics(
      label: data.title,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Row(
            children: [
              Icon(data.icon, size: 18, color: ootd.foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (data.trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    data.trailingText!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ootd.mutedForeground,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: ootd.mutedForeground.withValues(alpha: 0.55),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItemData {
  const _SettingsItemData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailingText;
}
