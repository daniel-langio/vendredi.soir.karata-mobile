import 'package:flutter/material.dart';
import '../../theme.dart';

class ActButton extends StatelessWidget {
  final String label;

  /// What the action costs, stacked under [label] on its own line. Null for actions that cost
  /// nothing (fold, check). Kept on a second line rather than appended to the label because three
  /// buttons share a phone's width, and "Relancer 7 600 Ar" on one line just ellipsises away the
  /// number the player most needs to see before committing to it.
  final String? amount;
  final bool enabled;
  final bool solid;
  final VoidCallback onPressed;

  const ActButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.amount,
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
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: amount == null ? 14.5 : 13,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (amount != null)
              Text(
                amount!,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
          ],
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
