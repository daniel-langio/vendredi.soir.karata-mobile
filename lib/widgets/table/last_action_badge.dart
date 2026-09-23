import 'package:flutter/material.dart';
import '../../theme.dart';

/// A small pill badge shown above a seat (or over the hero's own hand): either a completed
/// action ("FOLD", "CALL 20", ...) or, via [TurnBadge], an indicator that it's currently their
/// turn and they haven't acted yet this street.
class LastActionBadge extends StatelessWidget {
  final String rawAction;
  final String displayText;

  const LastActionBadge({
    super.key,
    required this.rawAction,
    required this.displayText,
  });

  String get _kind => rawAction.split(' ').first;

  Color get _color {
    switch (_kind) {
      case 'RAISE':
      case 'BET':
        return KarataColors.actionRaise;
      case 'CHECK':
      case 'CALL':
        return KarataColors.live;
      default:
        return KarataColors.pill;
    }
  }

  Color get _textColor {
    switch (_kind) {
      case 'RAISE':
      case 'BET':
      case 'CHECK':
      case 'CALL':
        return KarataColors.cardInk;
      default:
        return KarataColors.dim;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keying on the raw action (not the localized display text) restarts the pop animation only
    // when the action itself genuinely changes, including its first appearance - a language
    // switch shouldn't replay it.
    return _BadgePill(
      animationKey: rawAction,
      color: _color,
      textColor: _textColor,
      text: displayText,
    );
  }
}

/// Shown instead of [LastActionBadge] when a seat is on the clock but hasn't posted a fresh
/// action yet this street.
class TurnBadge extends StatelessWidget {
  final String label;

  const TurnBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return _BadgePill(
      animationKey: 'turn:$label',
      color: KarataColors.actionTurn,
      textColor: KarataColors.ink,
      text: label,
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String animationKey;
  final Color color;
  final Color textColor;
  final String text;

  const _BadgePill({
    required this.animationKey,
    required this.color,
    required this.textColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(animationKey),
      tween: Tween(begin: 1.4, end: 1.0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1,
          ),
        ),
      ),
    );
  }
}
