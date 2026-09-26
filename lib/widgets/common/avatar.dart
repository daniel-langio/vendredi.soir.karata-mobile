import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';

/// A player, drawn as their initial on a coloured disc inside a thin accent ring.
///
/// The design builds this from three concentric circles: a 3px ring, a 2px navy gap punched out
/// of it by the inner disc's `box-shadow: 0 0 0 2px #14142a`, and the disc itself. That leaves
/// 1px of ring showing, which is what gives the avatar its fine gold outline.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    this.diameter = 56,
    this.ringColor = KarataColors.gold,
  });

  final String name;
  final double diameter;
  final Color ringColor;

  /// The disc colours the design cycles through, picked by the name so a player keeps the same
  /// colour everywhere they appear.
  static const _palette = [
    Color(0xFF5B4BB0),
    Color(0xFFA8467E),
    Color(0xFF6A4BD0),
    Color(0xFF1A6FC2),
    Color(0xFF8C4B16),
    Color(0xFF3F7F55),
    Color(0xFFC2410C),
  ];

  static Color colorFor(String name) {
    if (name.isEmpty) return _palette.first;
    final hash = name.codeUnits.fold<int>(
      0,
      (a, b) => (a * 31 + b) & 0x7FFFFFFF,
    );
    return _palette[hash % _palette.length];
  }

  String get _initial =>
      name.isEmpty ? '?' : name.characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diameter,
      child: Center(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(color: ringColor, shape: BoxShape.circle),
          child: Center(
            child: Container(
              width: diameter - 2,
              height: diameter - 2,
              decoration: const BoxDecoration(
                color: KarataColors.backdrop,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: diameter - 6,
                  height: diameter - 6,
                  decoration: BoxDecoration(
                    color: colorFor(name),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initial,
                      style: karataText(
                        // The design sizes the initial at roughly 40% of the disc: 23px on the
                        // 56px profile avatar, 10px on the 26px seat markers.
                        size: diameter * 0.41,
                        weight: 800,
                        color: KarataColors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
