import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/l10n/app_localizations.dart';
import 'package:poker_client/main.dart';
import 'package:poker_client/theme/karata_theme.dart';
import 'package:poker_client/widgets/common/karata_switch.dart';
import 'package:poker_client/widgets/common/labeled_field.dart';
import 'package:poker_client/widgets/common/setting_row.dart';

/// Wraps a screen the same way MyApp's MaterialApp does, so AppLocalizations.of(context) has
/// something to find - without this, any screen using it throws a null-check failure in tests.
Widget wrapForTest(Widget child) {
  return MaterialApp(
    theme: karataTheme(),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: child,
  );
}

/// The whole app, routed the way it is in production, entered at [initialRoute].
///
/// Distinct from [wrapForTest], which mounts one screen directly: this one goes through
/// karataOnGenerateRoute, which is what a test of deep links and redirects has to exercise.
Widget wrapRoutedForTest(String initialRoute) {
  return MaterialApp(
    theme: karataTheme(),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    onGenerateRoute: karataOnGenerateRoute,
    initialRoute: initialRoute,
  );
}

/// The text field under the caption reading [label].
///
/// The V2 design puts a field's name in its own [LabeledField] caption rather than inside the
/// input, so a field can no longer be found by the label text alone - this walks from the caption
/// to the input it belongs to.
Finder fieldLabelled(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(LabeledField)),
  matching: find.byType(TextField),
);

/// The toggle on the [SettingRow] titled [title].
Finder switchLabelled(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(SettingRow)),
  matching: find.byType(KarataSwitch),
);
