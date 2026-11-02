@Tags(['accessibility'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/ui/ui.dart';

import 'a11y_harness.dart';

/// What screen reader and keyboard users rely on, screen by screen.
void main() {
  late SemanticsHandle semantics;

  setUp(() => semantics = SemanticsBinding.instance.ensureSemantics());
  tearDown(() => semantics.dispose());

  group('screen reader', () {
    testWidgets('page and section titles are headings', (tester) async {
      await pumpRoute(tester, '/home', size: wholePage);
      expect(find.semantics.byLabel('Entraînement du jour'), _matches(isHeader: true));
      expect(find.semantics.byLabel('Statistiques rapides'), _matches(isHeader: true));
    });

    testWidgets('a section link is its own control, not part of the heading', (tester) async {
      await pumpRoute(tester, '/home', size: wholePage);
      expect(find.semantics.byLabel('Séances récentes'), _matches(isHeader: true, hasTapAction: false));
      expect(find.semantics.byLabel('Planning'), _matches(isLink: true, hasTapAction: true));
    });

    testWidgets('tabs say which one is open', (tester) async {
      await pumpRoute(tester, '/home');
      expect(find.semantics.byLabel('Accueil'), _matches(isButton: true, isSelected: true));
      expect(find.semantics.byLabel('Progrès'), _matches(isButton: true, isSelected: false));
    });

    testWidgets('calendar days read their content and can be activated', (tester) async {
      await pumpRoute(tester, '/planning');
      final plannedDay = find.semantics.byLabel(RegExp(r', 1 séance, 0 terminée$')).first;
      expect(plannedDay, _matches(isButton: true, hasTapAction: true));
    });

    testWidgets('timeline days can be activated', (tester) async {
      await pumpRoute(tester, '/progress');
      expect(find.semantics.byLabel(RegExp(r'séance faite, Parfait$')), _matches(isButton: true, hasTapAction: true));
    });

    testWidgets('form fields are named by their visible label', (tester) async {
      await pumpRoute(tester, '/login', signedIn: false);
      expect(find.semantics.byLabel(RegExp(r'^Email')), _matches(isTextField: true));
      expect(find.semantics.byLabel(RegExp(r'^Mot de passe')), _matches(isTextField: true));
    });

    testWidgets('a picker field can be opened with a screen reader', (tester) async {
      await pumpRoute(tester, '/profile-setup');
      expect(find.semantics.byLabel(RegExp(r'^Date de naissance')), _matches(isButton: true, hasTapAction: true));
    });

    testWidgets('the terms checkbox carries its sentence', (tester) async {
      await pumpRoute(tester, '/register', size: wholePage, signedIn: false);
      expect(
        find.semantics.byLabel(RegExp(r"^J'accepte les conditions")),
        _matches(hasCheckedState: true, isChecked: false, hasTapAction: true),
      );
    });

    testWidgets('choice cards are radio buttons', (tester) async {
      await pumpRoute(tester, '/profile/training', size: wholePage);
      expect(
        find.semantics.byLabel(RegExp(r'^Modérée')),
        _matches(hasCheckedState: true, isChecked: true, isInMutuallyExclusiveGroup: true),
      );
    });

    testWidgets('short metric values are spelled out', (tester) async {
      await pumpRoute(tester, '/home', size: wholePage);
      expect(find.semantics.byLabel(RegExp(r'^Semaine\n0 sur 2$')), findsOne);
    });

    testWidgets('set fields say which set and which value they hold', (tester) async {
      await pumpRoute(tester, '/training?start=today', size: wholePage);
      await tester.tap(find.text('Squat').last);
      await settle(tester);
      expect(find.semantics.byLabel(RegExp(r'^Série 1, poids en kg')), _matches(isTextField: true));
      expect(find.semantics.byLabel(RegExp(r'^Série 1, répétitions')), _matches(isTextField: true));
    });
  });

  group('language', () {
    testWidgets('system strings are in French', (tester) async {
      await pumpRoute(tester, '/planning');
      final context = tester.element(find.byType(AppTopBar));
      expect(MaterialLocalizations.of(context).backButtonTooltip, 'Retour');
    });

    test('the web page declares French', () {
      expect(File('web/index.html').readAsStringSync(), contains('<html lang="fr">'));
    });
  });

  group('keyboard', () {
    testWidgets('Tab reaches every control of the login form in order', (tester) async {
      await pumpRoute(tester, '/login', signedIn: false);
      final reached = <String>[];
      for (var i = 0; i < 8 && !reached.contains('Créer un compte'); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final label = _focusedLabel();
        if (label != null && (reached.isEmpty || reached.last != label)) reached.add(label);
      }
      expect(reached, containsAllInOrder(['Email', 'Mot de passe', 'Se connecter', 'Créer un compte']));
    });
  });

  group('keyboard pickers', () {
    testWidgets('Enter on the birth date field opens the date picker', (tester) async {
      await pumpRoute(tester, '/profile-setup', size: wholePage);
      for (var i = 0; i < 10 && _focusedLabel() != 'Date de naissance'; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(_focusedLabel(), 'Date de naissance');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.byType(DatePickerDialog), findsOne);
    });
  });

  group('touch', () {
    testWidgets('a chip reacts to taps on its enlarged touch area', (tester) async {
      await pumpRoute(tester, '/progress');
      final chip = tester.getRect(find.text('7 jours'));
      // Just above the visible 36px pill, inside the 44px touch area.
      await tester.tapAt(Offset(chip.center.dx, chip.center.dy - 20));
      await settle(tester);
      expect(find.semantics.byLabel('7 jours'), _matches(isSelected: true));
    });
  });

  group('reduced motion', () {
    testWidgets('loaders stop pulsing when the system asks for less motion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpRoute(tester, '/training/generate');
      await tester.tap(find.text('Générer mon programme'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Construction de ton programme…'), findsOne);
      expect(tester.binding.hasScheduledFrame, isFalse);
      // Let the mock service answer before the test ends.
      await tester.pump(const Duration(seconds: 4));
    });
  });
}

Matcher _matches({
  bool? isHeader,
  bool? isButton,
  bool? isLink,
  bool? isSelected,
  bool? isTextField,
  bool? hasCheckedState,
  bool? isChecked,
  bool? isInMutuallyExclusiveGroup,
  bool? hasTapAction,
}) =>
    isA<FinderBase<SemanticsNode>>().having(
      (finder) => finder.evaluate().single,
      'single node',
      isSemantics(
        isHeader: isHeader,
        isButton: isButton,
        isLink: isLink,
        isSelected: isSelected,
        isTextField: isTextField,
        hasCheckedState: hasCheckedState,
        isChecked: isChecked,
        isInMutuallyExclusiveGroup: isInMutuallyExclusiveGroup,
        hasTapAction: hasTapAction,
      ),
    );

/// Visible label of the control that has keyboard focus.
String? _focusedLabel() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  final field = context.findAncestorWidgetOfExactType<AppTextField>();
  if (field != null) return field.label;
  final button = context.findAncestorWidgetOfExactType<AppButton>();
  if (button != null) return button.label;
  String? text;
  void visit(Element element) {
    if (text != null) return;
    final widget = element.widget;
    if (widget is Text) {
      text = widget.data;
      return;
    }
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  return text;
}
