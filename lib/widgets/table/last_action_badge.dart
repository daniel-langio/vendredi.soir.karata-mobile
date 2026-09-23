import 'package:flutter/material.dart';
import '../../theme.dart';
import 'pop_in.dart';

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
    return PopIn(
      popKey: rawAction,
      child: _BadgePill(color: _color, textColor: _textColor, text: displayText),
    );
  }
}

/// Shown instead of [LastActionBadge] when a seat is on the clock but hasn't posted a fresh
/// action yet this street. Pulses gently while it's up, so the player whose turn it is stands out
/// at a glance.
class TurnBadge extends StatefulWidget {
  final String label;

  const TurnBadge({super.key, required this.label});

  @override
  State<TurnBadge> createState() => _TurnBadgeState();
}

class _TurnBadgeState extends State<TurnBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);
  late final Animation<double> _pulse = CurvedAnimation(
    parent: _pulseController,
    curve: Curves.easeInOut,
  ).drive(Tween(begin: 1.0, end: 1.1));

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: PopIn(
        popKey: 'turn:${widget.label}',
        child: _BadgePill(
          color: KarataColors.actionTurn,
          textColor: KarataColors.ink,
          text: widget.label,
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String text;

  const _BadgePill({
    required this.color,
    required this.textColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
