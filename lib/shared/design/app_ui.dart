import 'package:shadcn_flutter/shadcn_flutter.dart';
export 'package:shadcn_flutter/shadcn_flutter.dart';
export 'app_feedback.dart';

/// Shared mobile page layout, including keyboard insets and automatic back.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
  });
  final Widget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    headers: [?appBar],
    footers: [?bottomNavigationBar],
    child: SafeArea(top: false, child: body),
  );
}

class AppPageBar extends StatelessWidget {
  const AppPageBar({super.key, required this.title, this.actions = const []});
  final Widget title;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => AppBar(
    title: title,
    leading: [
      if (Navigator.of(context).canPop())
        AppIconButton(
          tooltip: '返回',
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
    ],
    trailing: actions,
  );
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.variance = const ButtonStyle.ghost(),
  });
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AbstractButtonStyle variance;
  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      label: tooltip,
      button: true,
      enabled: onPressed != null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: IconButton(icon: icon, onPressed: onPressed, variance: variance),
      ),
    );
    return tooltip == null
        ? button
        : Tooltip(
            tooltip: TooltipContainer(child: Text(tooltip!)).call,
            child: button,
          );
  }
}

class AppPressable extends StatelessWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
  });
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  @override
  Widget build(BuildContext context) => Button(
    onPressed: onTap,
    style: const ButtonStyle.ghost().copyWith(
      padding: (_, _, _) => EdgeInsets.zero,
    ),
    child: child,
  );
}

class AppImageSurface extends StatelessWidget {
  const AppImageSurface({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
  });
  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.zero,
    clipBehavior: clipBehavior,
    child: ColoredBox(
      color: color ?? Theme.of(context).colorScheme.card,
      child: child,
    ),
  );
}
