import 'package:aowugong_ootd/shared/design/app_ui.dart';

class OotdCard extends StatelessWidget {
  const OotdCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: padding,
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }
}
