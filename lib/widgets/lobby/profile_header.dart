import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';
import '../../theme/karata_text_styles.dart';
import '../common/avatar.dart';

/// Who you are signed in as, at the top of the lobby.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.username,
    required this.caption,
  });

  final String username;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Avatar(name: username),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: karataText(size: 22, weight: 800, height: 1.1),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: karataText(
                  size: 13,
                  weight: 500,
                  color: KarataColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
