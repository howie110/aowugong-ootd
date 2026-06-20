import 'package:flutter/material.dart';

import '../../../../shared/design/app_theme.dart';

class SettingsPlaceholderPage extends StatelessWidget {
  const SettingsPlaceholderPage({
    super.key,
    required this.title,
    this.description = '功能预留中，后续接入。',
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ootd = theme.extension<OotdColors>() ?? OotdColors.light;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ootd.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ootd.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                size: 34,
                color: ootd.subtleIcon,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
