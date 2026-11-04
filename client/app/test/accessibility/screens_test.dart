@Tags(['accessibility'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/video/presentation/pages/video_selection_page.dart';

import 'a11y_harness.dart';

/// Key screens of the app, reached the way users reach them.
const _routes = [
  '/onboarding',
  '/login',
  '/register',
  '/profile-setup',
  '/home',
  '/training',
  '/planning',
  '/progress',
  '/profile',
  '/profile/training',
  '/training/generate',
];

void main() {
  for (final route in _routes) {
    group(route, () {
      testWidgets('touch targets, labels and contrast', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpRoute(tester, route, size: wholePage, signedIn: !_signedOut(route));
        await expectAccessible(tester);
        semantics.dispose();
      });

      testWidgets('200% text without overflow', (tester) async {
        await expectNoOverflowAtLargeText(
          tester,
          (size) => pumpRoute(tester, route, size: size, textScale: 2, signedIn: !_signedOut(route)),
        );
      });
    });
  }

  group('video selection', () {
    testWidgets('touch targets, labels and contrast', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPage(tester, const VideoSelectionPage(), size: wholePage);
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('200% text without overflow', (tester) async {
      await expectNoOverflowAtLargeText(
        tester,
        (size) => pumpPage(tester, const VideoSelectionPage(), size: size, textScale: 2),
      );
    });
  });
}

bool _signedOut(String route) => const ['/onboarding', '/login', '/register'].contains(route);
