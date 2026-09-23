import 'package:flutter/material.dart';
import '../../theme.dart';

class ActButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool solid;
  final VoidCallback onPressed;

  const ActButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: solid ? KarataColors.pill : Colors.transparent,
          side: BorderSide(
            color: solid ? Colors.transparent : KarataColors.pillLine,
          ),
          foregroundColor: KarataColors.ink,
          disabledForegroundColor: KarataColors.ink.withValues(alpha: 0.3),
          disabledBackgroundColor: solid
              ? KarataColors.pill.withValues(alpha: 0.3)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

class BumpButton extends StatelessWidget {
  final bool on;
  final bool enabled;
  final VoidCallback onPressed;

  const BumpButton({
    super.key,
    required this.on,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: on ? KarataColors.pill : Colors.transparent,
          side: BorderSide(
            color: on ? Colors.transparent : KarataColors.pillLine,
          ),
          foregroundColor: KarataColors.ink,
          disabledForegroundColor: KarataColors.ink.withValues(alpha: 0.3),
          shape: const CircleBorder(),
        ),
        child: const Icon(Icons.arrow_upward, size: 16),
      ),
    );
  }
}
