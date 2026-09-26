import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';

/// The 52x30 toggle the design uses for every on/off setting.
class KarataSwitch extends StatelessWidget {
  const KarataSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  static const _width = 52.0;
  static const _height = 30.0;
  static const _knob = 24.0;
  static const _inset = 3.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: onChanged == null ? 0.5 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            width: _width,
            height: _height,
            decoration: BoxDecoration(
              color: value ? KarataColors.teal : const Color(0xFF35355F),
              borderRadius: BorderRadius.circular(_height / 2),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  top: _inset,
                  left: value ? _width - _knob - _inset : _inset,
                  child: Container(
                    width: _knob,
                    height: _knob,
                    decoration: const BoxDecoration(
                      color: KarataColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
