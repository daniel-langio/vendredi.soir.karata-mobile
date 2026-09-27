import 'package:flutter/painting.dart';

import '../../theme/karata_colors.dart';
import 'room_tag.dart';

/// Which of the four things a room card can be saying, as the design draws them side by side in
/// `room-card-states.html`.
///
/// The phone card and the wide row both switch on this, so the stripe colour and the tag tone
/// live here rather than being decided twice.
enum RoomCardState {
  /// Tables are running and there is a seat. The ordinary case.
  open,

  /// Nobody is here yet. Still sittable - that is the point of the invitation.
  quiet,

  /// The player already has a seat in this room and is being sent back to it.
  seated,

  /// Every seat the room is allowed to open is taken.
  full,
}

extension RoomCardAccent on RoomCardState {
  /// The stripe down the card's left edge, which only the two exceptional states colour.
  Color get accent => switch (this) {
    RoomCardState.open || RoomCardState.quiet => const Color(0x00000000),
    RoomCardState.seated => KarataColors.teal,
    RoomCardState.full => KarataColors.orange,
  };

  /// The tone of the card's second tag. [RoomCardState.open] and [RoomCardState.quiet] have
  /// nothing of their own to say there, so the tag falls back to whether the room cashes out -
  /// which the caller decides, since only it knows the room.
  RoomTagTone? get tagTone => switch (this) {
    RoomCardState.open || RoomCardState.quiet => null,
    RoomCardState.seated => RoomTagTone.seated,
    RoomCardState.full => RoomTagTone.full,
  };
}
