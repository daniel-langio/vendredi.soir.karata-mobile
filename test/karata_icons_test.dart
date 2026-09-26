import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/widgets/common/karata_icon.dart';
import 'package:poker_client/widgets/common/karata_icons.dart';
import 'package:poker_client/widgets/common/svg_path.dart';

/// The icons are transcribed `d` strings, so a typo in one would otherwise surface as a blank
/// square at runtime on whichever screen happens to use it. Parsing every shape here turns that
/// into a build failure instead.
void main() {
  const catalogue = <String, KarataIconData>{
    'back': KarataIcons.back,
    'chevronRight': KarataIcons.chevronRight,
    'chevronDown': KarataIcons.chevronDown,
    'externalLink': KarataIcons.externalLink,
    'brightness': KarataIcons.brightness,
    'refresh': KarataIcons.refresh,
    'deposit': KarataIcons.deposit,
    'withdraw': KarataIcons.withdraw,
    'copy': KarataIcons.copy,
    'clock': KarataIcons.clock,
    'plus': KarataIcons.plus,
    'link': KarataIcons.link,
    'shuffle': KarataIcons.shuffle,
    'globe': KarataIcons.globe,
    'speaker': KarataIcons.speaker,
    'money': KarataIcons.money,
    'sliders': KarataIcons.sliders,
    'logout': KarataIcons.logout,
    'eye': KarataIcons.eye,
    'betBars': KarataIcons.betBars,
    'emote': KarataIcons.emote,
    'spade': KarataSuits.spade,
    'heart': KarataSuits.heart,
    'diamond': KarataSuits.diamond,
    'club': KarataSuits.club,
  };

  group('every catalogue icon parses', () {
    catalogue.forEach((name, icon) {
      test(name, () {
        for (final shape in icon.shapes) {
          if (shape is! PathShape) continue;
          final bounds = parseSvgPath(shape.d).getBounds();
          expect(bounds.isEmpty, isFalse, reason: '$name drew nothing');
          expect(
            bounds.left >= -1 && bounds.right <= icon.viewBox + 1,
            isTrue,
            reason: '$name escapes its ${icon.viewBox}px viewBox: $bounds',
          );
        }
      });
    });
  });

  group('path grammar', () {
    test('relative commands offset from the current point', () {
      final absolute = parseSvgPath('M10 10 L20 20').getBounds();
      final relative = parseSvgPath('M10 10 l10 10').getBounds();
      expect(relative, absolute);
    });

    test('repeated pairs after a moveto are implicit linetos', () {
      expect(
        parseSvgPath('M0 0 10 10 20 0').getBounds(),
        parseSvgPath('M0 0 L10 10 L20 0').getBounds(),
      );
    });

    test('numbers may run together without separators', () {
      expect(
        parseSvgPath('M1.5.5L2.5.5').getBounds(),
        parseSvgPath('M1.5 0.5 L2.5 0.5').getBounds(),
      );
    });

    test('an unsupported command is rejected rather than skipped', () {
      expect(() => parseSvgPath('M0 0 T5 5'), throwsFormatException);
    });
  });
}
