import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aowugong_ootd/shared/design/app_ui.dart';
import 'package:aowugong_ootd/features/ootd/presentation/shared/ootd_image_view.dart';
import 'package:aowugong_ootd/features/ootd/presentation/home/mock_ootd_items.dart';

void main() {
  testWidgets('grid decode is bounded while preview retains full resolution', (
    tester,
  ) async {
    for (final full in [false, true]) {
      await tester.pumpWidget(
        ProviderScope(
          child: ShadcnApp(
            home: MediaQuery(
              data: const MediaQueryData(devicePixelRatio: 3),
              child: Center(
                child: SizedBox(
                  width: 100,
                  height: 150,
                  child: OotdImageView(
                    image: MockOotdImage.file(id: 'x', filePath: 'missing.jpg'),
                    fullResolution: full,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final provider = tester.widget<Image>(find.byType(Image)).image;
      if (full) {
        expect(provider, isA<FileImage>());
      } else {
        expect((provider as ResizeImage).width, 300);
      }
      await tester.pumpAndSettle();
    }
  });
}
