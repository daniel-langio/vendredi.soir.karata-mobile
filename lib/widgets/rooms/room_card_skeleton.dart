import 'package:flutter/widgets.dart';

import '../../theme/karata_colors.dart';

/// The grey stand-in drawn while the room list is on its way.
///
/// It holds the card's own shape rather than a spinner so the list does not jump when the real
/// rooms land, and so an empty lobby and a loading one never look alike.
class RoomCardSkeleton extends StatelessWidget {
  const RoomCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: KarataColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Block(width: 120, height: 20),
                  SizedBox(height: 8),
                  _Block(width: 150, height: 12),
                ],
              ),
              _Block(width: 70, height: 22),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _Block(width: 80, height: 14),
              SizedBox(width: 18),
              _Block(width: 80, height: 14),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Block(width: 140, height: 12),
              _Block(width: 100, height: 36),
            ],
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: KarataColors.surfaceRaised,
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}
