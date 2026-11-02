import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/router.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';
  // On the web, Flutter only builds the accessibility tree after a click on
  // a hidden button; screen reader users get it from the start instead.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  // Signed in last time: open the app directly, network or not.
  final session = await AuthNotifier.restoreSession();
  runApp(
    ProviderScope(
      overrides: [restoredSessionProvider.overrideWithValue(session)],
      child: MyApp(router: buildAppRouter(initialLocation: startLocation(session))),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;

  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) => ListenableBuilder(
        listenable: router.routerDelegate,
        builder: (context, _) {
          final matches = router.routerDelegate.currentConfiguration;
          return Title(
            title: matches.isEmpty ? AppConstants.appName : pageTitle(matches.last.matchedLocation),
            color: AppColors.primary,
            child: child!,
          );
        },
      ),
      debugShowCheckedModeBanner: false,
      // French system strings (date picker, tooltips, screen reader hints).
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
