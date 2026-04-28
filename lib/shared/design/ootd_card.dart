import 'package:flutter/material.dart';

import 'app_theme.dart';

class OotdCard extends StatelessWidget {
  const OotdCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 18.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final ootd = Theme.of(context).extension<OotdColors>() ?? OotdColors.light;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ootd.cardSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: ootd.cardBorder),
      ),
      child: child,
    );
  }
}
