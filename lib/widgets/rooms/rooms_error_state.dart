import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/karata_button.dart';
import '../common/karata_icon.dart';
import '../common/karata_icons.dart';

/// What the Rooms tab shows when it could not reach the server.
///
/// Deliberately not an empty list: a room with nobody in it is a real and ordinary state here, so
/// "we could not find out" has to look nothing like "there is nobody here".
class RoomsErrorState extends StatelessWidget {
  const RoomsErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x24C4502A),
              shape: BoxShape.circle,
            ),
            child: const KarataIcon(
              KarataIcons.warning,
              size: 26,
              color: KarataColors.orangeLight,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: karataText(size: 18, weight: 800),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: karataText(
                size: 14,
                weight: 500,
                color: KarataColors.inkMuted,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          KarataButton(
            label: retryLabel,
            onPressed: onRetry,
            style: KarataButtonStyle.surface,
            height: 44,
            expand: false,
            horizontalPadding: 26,
          ),
        ],
      ),
    );
  }
}
