import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '管理中心',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '设置页负责标签和“不喜欢”记录管理，首页只保留找灵感和浏览入口。',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: '标签管理',
            subtitle: '后续会接标签的创建、重命名、删除和颜色区分。',
            leading: Icons.sell_outlined,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                Chip(label: Text('通勤')),
                Chip(label: Text('周末')),
                Chip(label: Text('极简')),
                Chip(label: Text('叠穿')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '不喜欢的 OOTD',
            subtitle: '这里会承接“移出首页灵感库”后的记录，并支持恢复。',
            leading: Icons.restore_from_trash_outlined,
            child: Column(
              children: const [
                _StatusRow(label: '待恢复记录', value: '0'),
                SizedBox(height: 10),
                _StatusRow(label: '支持永久删除', value: '已规划'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '本地存储',
            subtitle: '首版只走本地文件系统和本地数据库，不接云同步。',
            leading: Icons.folder_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '照片只保存在 App 私有目录，避免回写系统相册。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.storage_outlined),
                  label: const Text('后续接入存储详情'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData leading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(leading),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
