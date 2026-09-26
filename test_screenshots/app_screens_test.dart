@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, MissingPluginException;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_client/chip_display.dart';
import 'package:poker_client/l10n/app_localizations.dart';
import 'package:poker_client/screens/chip_purchase_screen.dart';
import 'package:poker_client/screens/chip_redemption_screen.dart';
import 'package:poker_client/screens/economy_config_screen.dart';
import 'package:poker_client/screens/economy_screen.dart';
import 'package:poker_client/screens/join_table_screen.dart';
import 'package:poker_client/screens/login_screen.dart';
import 'package:poker_client/screens/menu_screen.dart';
import 'package:poker_client/screens/new_table_screen.dart';
import 'package:poker_client/screens/pending_redemptions_screen.dart';
import 'package:poker_client/screens/register_screen.dart';
import 'package:poker_client/screens/settings_screen.dart';
import 'package:poker_client/screens/table_screen.dart';
import 'package:poker_client/screens/welcome_screen.dart';
import 'package:poker_client/sound_settings.dart';
import 'package:poker_client/theme/karata_text_styles.dart';
import 'package:poker_client/theme/karata_theme.dart';

import 'fake_server.dart';

/// Photographs every screen in the app, in both languages, and writes the PNGs under
/// `test_screenshots/shots/`. Not a behaviour test and not a visual-regression gate: it lives
/// outside `test/` precisely so `flutter test` never runs it, and it is always invoked with
/// `--update-goldens`, which makes [matchesGoldenFile] *write* the image instead of comparing it.
///
///     flutter test test_screenshots --update-goldens
///
/// Two things have to be set up by hand for the result to be worth looking at:
///
///  * Real fonts. The test binding ships a placeholder font that draws every glyph as a filled
///    box, which would make these images useless to a designer. [_loadRealFonts] registers the
///    Roboto and Material Icons files out of the Flutter SDK's own cache - already on disk, so no
///    download and no vendored binary in the repo.
///  * A server. See [fakeKarata].
void main() {
  // A tall phone, which is what this UI was drawn for. Logical 412x915 is a common Android size;
  // at 2x the PNGs land at 824x1830, big enough to inspect and small enough to attach.
  const size = Size(412, 915);
  const pixelRatio = 2.0;

  setUpAll(() async {
    await _loadRealFonts();
    _ignoreAudioPluginNoise();
  });

  setUp(() async {
    // Not under test/, so the analyzer does not know this is test code.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    // Reset the singletons between shots so one screen's toggle can't leak into the next.
    ChipDisplay.instance.value = const ChipDisplaySettings();
    await ChipDisplay.instance.load();
    await SoundSettings.instance.load();
  });

  for (final locale in const [Locale('en'), Locale('fr')]) {
    for (final screen in _screens) {
      testWidgets('${locale.languageCode}/${screen.name}', (tester) async {
        tester.view.physicalSize = size * pixelRatio;
        tester.view.devicePixelRatio = pixelRatio;
        addTearDown(tester.view.reset);

        // The rate every amount is shown at. Set directly rather than fetched, so a screen that
        // never calls /economy/price still photographs with money on like the shipped default.
        ChipDisplay.instance.value = ChipDisplay.instance.value.copyWith(
          arPerChip: 100,
        );

        await http.runWithClient(() async {
          await tester.pumpWidget(_app(locale, screen.build()));
          await screen.settle(tester);
        }, fakeKarata);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('shots/${locale.languageCode}/${screen.name}.png'),
        );
      });
    }
  }
}

/// Wraps a screen the way MyApp does - same theme, same localization delegates - so a shot is of
/// the app rather than of a screen in a bare MaterialApp.
Widget _app(Locale locale, Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: karataTheme(),
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

/// One screen to photograph.
///
/// Frames are pumped a fixed number of times rather than via `pumpAndSettle`, which never
/// returns here: a CircularProgressIndicator animates forever, and TableScreen polls on a timer.
class _Screen {
  final String name;
  final Widget Function() build;

  /// How many frames to run before the shutter. The default gives every screen time to fetch,
  /// settle and finish its entry animation; TableScreen wants fewer (see [_screens]).
  final int frames;

  const _Screen(this.name, this.build, {this.frames = 40});

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
}

const _session = {
  'serverUrl': shotsServerUrl,
  'token': 'screenshot-token',
  'username': shotsUsername,
};

final _screens = <_Screen>[
  _Screen('01-welcome', () => const WelcomeScreen()),
  _Screen('02-register', () => const RegisterScreen(serverUrl: shotsServerUrl)),
  _Screen('03-login', () => const LoginScreen(serverUrl: shotsServerUrl)),
  _Screen(
    '04-menu',
    () => MenuScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
    ),
  ),
  _Screen(
    '05-new-table',
    () => NewTableScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
    ),
  ),
  _Screen(
    '06-join-table',
    () => JoinTableScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
    ),
  ),
  _Screen(
    '07-table',
    () => TableScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
      gameId: shotsGameId,
    ),
    // Stop short of the 2s poll, so the shot is of one settled fetch rather than a screen
    // caught mid-refresh.
    frames: 12,
  ),
  _Screen(
    '07b-table-showdown',
    () => TableScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
      gameId: shotsShowdownGameId,
    ),
    frames: 12,
  ),
  _Screen(
    '08-economy',
    () => EconomyScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
    ),
  ),
  _Screen(
    '09-deposit',
    () => ChipPurchaseScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
    ),
  ),
  _Screen(
    '10-withdraw',
    () => ChipRedemptionScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
    ),
  ),
  _Screen(
    '11-pending-withdrawals',
    () => PendingRedemptionsScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
    ),
  ),
  _Screen(
    '12-economy-config',
    () => EconomyConfigScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
    ),
  ),
  _Screen(
    '13-settings',
    () => SettingsScreen(
      serverUrl: _session['serverUrl']!,
      token: _session['token']!,
      username: _session['username']!,
    ),
  ),
];

/// TableScreen builds three AudioPlayers, and a test VM has no just_audio plugin behind their
/// platform channels. GameSounds is written to tolerate exactly that - "audio is enhancement
/// only", says its own doc - but flutter_test still fails the test over it, which would cost us
/// the one screenshot that matters most.
///
/// So drop those, and only those, on the floor. Two other routes do not work: mocking the
/// plugin's channels is impossible because just_audio names each player's channel after a UUID
/// it generates itself, and hooking FlutterError.onError is futile because the binding resets it
/// at the start of every test. [reportTestException] is the layer that actually turns a caught
/// exception into a failed test, and it is deliberately set here in setUpAll rather than inside
/// a test - the binding asserts that no test changes it mid-flight.
void _ignoreAudioPluginNoise() {
  final report = reportTestException;
  reportTestException = (details, description) {
    final error = details.exception;
    if (error is MissingPluginException &&
        (error.message?.contains('just_audio') ?? false)) {
      return;
    }
    report(details, description);
  };
}

/// Registers the fonts the app actually renders with. Without this every glyph - letters and
/// Material icons alike - comes out as a filled rectangle, which is the single thing that would
/// make these screenshots worthless for design work.
///
/// The files come from the Flutter SDK's own artifact cache rather than a download or a vendored
/// copy: they are already on any machine that can run this test, CI included.
Future<void> _loadRealFonts() async {
  // Karata's own typeface, straight out of the assets the app ships. Without this the test VM
  // draws every glyph as a filled box, and with a Roboto substitute the shots would show the
  // right layout in the wrong voice - Bricolage Grotesque's proportions are a large part of what
  // the V2 design looks like.
  await (FontLoader(kKarataFont)..addFont(
        File(
          'assets/fonts/BricolageGrotesque.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      ))
      .load();

  final cache = _materialFontsDir();
  if (cache == null) {
    printOnFailure(
      'Flutter SDK fonts not found - icon glyphs will render as boxes.',
    );
    return;
  }

  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('${cache.path}/$name').readAsBytes());

  // Roboto still has to be present as the fallback family: it carries the card suits and any
  // glyph Bricolage Grotesque does not cover.
  final roboto = FontLoader('Roboto');
  for (final weight in const [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    roboto.addFont(read(weight));
  }
  await roboto.load();

  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('MaterialIcons-Regular.otf'))).load();
}

/// `flutter test` exports FLUTTER_ROOT; fall back to walking up from the running Dart executable
/// so the test still works when it is driven some other way.
Directory? _materialFontsDir() {
  final candidates = <String>[
    ?Platform.environment['FLUTTER_ROOT'],
    Directory(Platform.resolvedExecutable).parent.parent.parent.parent.path,
  ];
  for (final root in candidates) {
    final dir = Directory('$root/bin/cache/artifacts/material_fonts');
    if (dir.existsSync()) return dir;
  }
  return null;
}
