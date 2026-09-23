import 'package:flutter/material.dart';
import '../../theme.dart';

/// A docked side panel shown next to the table on a laptop-size window, styled like the
/// reference app's chat dock - a placeholder shell only, not wired to any real chat feature yet.
class ChatDockPanel extends StatelessWidget {
  const ChatDockPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KarataColors.field,
        border: Border.all(color: KarataColors.pillLine),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Table Chat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: KarataColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: Text(
                'Chat coming soon',
                style: const TextStyle(fontSize: 12.5, color: KarataColors.dim),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
