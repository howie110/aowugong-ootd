import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? barrierColor,
  bool fullScreen = false,
}) {
  final navigator = Navigator.of(context);
  return navigator.push(
    DialogRoute<T>(
      context: context,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      data: Data.capture(from: context, to: navigator.context),
      alignment: Alignment.center,
      fullScreen: fullScreen,
      barrierDismissible: true,
      barrierLabel: '关闭',
      barrierColor: barrierColor ?? const Color(0x66000000),
      builder: (context) => fullScreen
          ? builder(context)
          : Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: builder(context),
              ),
            ),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

void showAppMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  showToast(
    context: context,
    location: ToastLocation.bottomCenter,
    builder: (context, overlay) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 32,
      ),
      child: Card(child: Text(message)),
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  bool destructive = false,
}) async {
  return await showAppDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            OutlineButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            Button(
              style: destructive
                  ? const ButtonStyle.destructive()
                  : const ButtonStyle.primary(),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认'),
            ),
          ],
        ),
      ) ??
      false;
}
