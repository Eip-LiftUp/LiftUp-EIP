@Tags(['accessibility'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/video_analysis_service.dart';
import 'package:app/features/movement_analysis/presentation/pages/video_analysis_results_page.dart';
import 'package:app/features/video/presentation/pages/video_upload_page.dart';

import 'a11y_harness.dart';

/// Sheets, dialogs and states reached from the key screens.
class _Flow {
  final String name;
  final String route;

  /// Taps and waits that lead from [route] to the state under test.
  final Future<void> Function(WidgetTester tester) open;
  final bool online;

  const _Flow(this.name, this.route, this.open, {this.online = true});
}

/// Scrolls the page down to [text] when it is below the fold, then taps it.
Future<void> _tap(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    final page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    await tester.scrollUntilVisible(finder, 200, scrollable: page.first);
  }
  await tester.ensureVisible(finder.last);
  await settle(tester);
  await tester.tap(finder.last);
  await settle(tester);
}

final _flows = [
  _Flow('workout details sheet', '/training', (tester) => _tap(tester, 'Full body')),
  _Flow('active session sheet', '/training?start=today', (tester) async {}),
  _Flow('set editor sheet', '/training?start=today', (tester) => _tap(tester, 'Squat')),
  _Flow('personal info dialog', '/profile', (tester) => _tap(tester, 'Informations personnelles')),
  _Flow('delete account dialog', '/profile', (tester) => _tap(tester, 'Supprimer mon compte')),
  _Flow('offline banner', '/home', (tester) async {}, online: false),
  _Flow('generated program', '/training/generate', (tester) async {
    await _tap(tester, 'Générer mon programme');
    // The mock service answers after 3 s.
    await tester.pump(const Duration(seconds: 4));
    await settle(tester);
  }),
];

VideoAnalysisResult _analysis() => VideoAnalysisResult.fromJson({
      'analysis_id': 'a1',
      'timestamp': DateTime.now().toIso8601String(),
      'quality_score': 72,
      'detected_exercise': 'squat',
      'detection_confidence': 0.93,
      'form_scores': {'depth': 70, 'alignment': 80, 'stability': 75, 'tempo': 60, 'range_of_motion': 74},
      'feedback': [
        {'id': 'f1', 'type': 'correction', 'category': 'depth', 'text': 'Descends un peu plus bas.', 'score': 70, 'severity': 2},
        {'id': 'f2', 'type': 'positive', 'category': 'alignment', 'text': 'Genoux bien alignés.', 'score': 80, 'severity': 1},
      ],
      'metrics': {'video_fps': 30, 'total_frames': 300, 'frames_analyzed': 300, 'processing_time_seconds': 4.2},
    });

final _pages = <String, Widget Function()>{
  'video upload': () => const VideoUploadPage(videoPath: '/missing/video.mp4'),
  'analysis results': () => VideoAnalysisResultsPage(result: _analysis()),
};

void main() {
  for (final flow in _flows) {
    group(flow.name, () {
      testWidgets('touch targets, labels and contrast', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpRoute(tester, flow.route, size: wholePage, online: flow.online);
        await flow.open(tester);
        await expectAccessible(tester);
        semantics.dispose();
      });

      testWidgets('200% text without overflow', (tester) async {
        await expectNoOverflowAtLargeText(tester, (size) async {
          await pumpRoute(tester, flow.route, size: size, textScale: 2, online: flow.online);
          await flow.open(tester);
        });
      });
    });
  }

  for (final MapEntry(key: name, value: page) in _pages.entries) {
    group(name, () {
      testWidgets('touch targets, labels and contrast', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpPage(tester, page(), size: wholePage);
        await expectAccessible(tester);
        semantics.dispose();
      });

      testWidgets('200% text without overflow', (tester) async {
        await expectNoOverflowAtLargeText(
          tester,
          (size) => pumpPage(tester, page(), size: size, textScale: 2),
        );
      });
    });
  }
}
